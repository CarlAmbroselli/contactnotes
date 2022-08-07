//
//  MatrixModel.swift
//  Crew (iOS)
//
//  Created by dev on 01.03.22.
//

import Foundation
import Alamofire
import CoreData

class MatrixModel: ObservableObject {
    static let shared = MatrixModel()
    @Published var isAuthenticated: Bool
    @Published var roomTimestamps: [String:Date?]
    
    init() {
        let accessToken = UserDefaults.standard.string(forKey: SessionStore.accessToken.rawValue)
        if (accessToken != nil) {
//            let homeServer = UserDefaults.standard.string(forKey: SessionStore.homeserver.rawValue)!
//            let userId = UserDefaults.standard.string(forKey: SessionStore.userId.rawValue)!
        }
        isAuthenticated = accessToken != nil
        roomTimestamps = [String:Date]()
        
        let fetchRequest: NSFetchRequest<MatrixRoom>
        fetchRequest = MatrixRoom.fetchRequest()
        
        let viewContext = PersistenceController.shared.container.viewContext
        
        let rooms = try? viewContext.fetch(fetchRequest)
        if (rooms != nil) {
            rooms!.forEach { room in
                roomTimestamps[room.roomId!] = room.lastMessageTimestamp
            }
        }
    }
    
    func loadLatestState(silent: Bool = true) {
        guard let accessToken = UserDefaults.standard.string(forKey: SessionStore.accessToken.rawValue) else {
            StatusModel.shared.show(message: "Can't load matrix state, no access token!", level: .ERROR)
            return
        }
        
        let homeServer = UserDefaults.standard.string(forKey: SessionStore.homeserver.rawValue)!
        let nextBatchToken = UserDefaults.standard.string(forKey: SessionStore.nextBatchToken.rawValue)
        
        var urlParams = [
            "filter":"{\"room\":{\"timeline\":{\"limit\":10}}}",
            "access_token": accessToken,
        ]
        
        var fetchingMessagesMessage = "Updating all rooms... (can take several minutes)"
        
        if (nextBatchToken != nil) {
            urlParams["since"] = nextBatchToken!
            fetchingMessagesMessage = "Fetching latest messages... (can take several minutes)"
        }
        
        if (!silent) {
            StatusModel.shared.show(message: fetchingMessagesMessage, level: .INFO, permanent: true)
        }

        // Fetch Request
        AF.request("https://\(homeServer)/_matrix/client/r0/sync", method: .get, parameters: urlParams) { $0.timeoutInterval = 600 }
            .validate(statusCode: 200..<300)
            .responseDecodable(of: SyncResponse.self) { response in
                StatusModel.shared.dismissMessage(message: fetchingMessagesMessage)
                guard let result = response.value else {
                    if (response.error != nil && response.error!.errorDescription != nil) {
                        StatusModel.shared.show(message: "Error fetching room state: \n\(String(describing: response.error!.errorDescription!))", level: .ERROR)
                    } else {
                        StatusModel.shared.show(message: "Error fetching room state", level: .ERROR)
                    }
                    return
                }
                UserDefaults.standard.set(result.nextBatch, forKey: SessionStore.nextBatchToken.rawValue)
                UserDefaults.standard.synchronize()
                
                self.updateCoreDataRooms(rooms: result.rooms)
            }
    }
    
    func updateCoreDataRooms(rooms: [Room]) {
        let fetchRequest: NSFetchRequest<MatrixRoom>
        fetchRequest = MatrixRoom.fetchRequest()
        
        let viewContext = PersistenceController.shared.container.viewContext
        
        let knownRooms = try? viewContext.fetch(fetchRequest)
        if (knownRooms != nil) {
            rooms.forEach { room in
                let alreadyKnownRoom = knownRooms?.first(where: { knownRoom in
                    return knownRoom.roomId == room.key
                })
                if (alreadyKnownRoom != nil) {
                    if (room.lastMessage != nil) {
                        alreadyKnownRoom!.lastMessageTimestamp = room.lastMessage!.timestamp
                        roomTimestamps[room.key] = room.lastMessage!.timestamp
                    }
                } else {
                        let newRoom = MatrixRoom(context: viewContext)
                        newRoom.roomId = room.key
                        if (room.lastMessage != nil) {
                            newRoom.lastMessageTimestamp = room.lastMessage!.timestamp
                            roomTimestamps[room.key] = room.lastMessage!.timestamp
                        }
                }
            }
        }
        DispatchQueue.main.async {
            try? viewContext.save()
        }
    }
    
    func login(username: String, password: String, homeserverRaw: String) {
        let homeserver = homeserverRaw.replacingOccurrences(of: "https://", with: "")
        StatusModel.shared.show(message: "Starting login", level: .INFO, permanent: true)
        // Add Headers
        let headers: HTTPHeaders = HTTPHeaders.init([
            "Content-Type":"application/json; charset=utf-8",
        ])
        
        // JSON Body
        let body: [String : Any] = [
            "type": "m.login.password",
            "user": username,
            "password": password
        ]
        
        // Fetch Request
        AF.request("https://\(homeserver)/_matrix/client/r0/login", method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: LoginResponse.self) { response in
                guard let session = response.value else {
                    StatusModel.shared.show(message: "Login failed!", level: .ERROR)
                    if (response.data != nil) {
                        print(String(decoding: response.data!, as: UTF8.self))
                    }
                    return
                }
                UserDefaults.standard.set(session.home_server, forKey: SessionStore.homeserver.rawValue)
                UserDefaults.standard.set(session.user_id, forKey: SessionStore.userId.rawValue)
                UserDefaults.standard.set(session.access_token, forKey: SessionStore.accessToken.rawValue)
                UserDefaults.standard.synchronize()
                
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                }
                StatusModel.shared.show(message: "Login successful", level: .INFO)
                self.loadLatestState()
            }
    }
    
    func logout() {
        guard let accessToken = UserDefaults.standard.string(forKey: SessionStore.accessToken.rawValue) else {
            StatusModel.shared.show(message: "No access token, forgetting login.", level: .ERROR)
            return
        }
        
        let homeserver = UserDefaults.standard.string(forKey: SessionStore.homeserver.rawValue)!
        
        let headers: HTTPHeaders = HTTPHeaders.init([
            "Authorization":"Bearer \(accessToken)",
        ])
        
        AF.request("https://\(homeserver)/_matrix/client/r0/logout", method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .response { _ in
                StatusModel.shared.show(message: "Logged out", level: .SUCCESS)
            }
        UserDefaults.standard.removeObject(forKey: SessionStore.homeserver.rawValue)
        UserDefaults.standard.removeObject(forKey: SessionStore.userId.rawValue)
        UserDefaults.standard.removeObject(forKey: SessionStore.accessToken.rawValue)
        UserDefaults.standard.removeObject(forKey: SessionStore.nextBatchToken.rawValue)
        UserDefaults.standard.synchronize()
        self.isAuthenticated = false
    }
}

struct LoginResponse: Codable, Hashable {
    let user_id: String
    let access_token: String
    let home_server: String
    let device_id: String
}

struct Room: Decodable {
    var key: String
    var lastMessage: Message?
}

struct Message: Decodable {
    var sender: String
    var timestamp: Date
}

struct GenericCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
}

struct SyncResponse: Decodable {
    
    var nextBatch: String
    var rooms: [Room] = []

    struct RoomResponse: Decodable {
        var timeline: Timeline
    }
    
    struct Timeline: Decodable {
        var events: [Event]
    }
    
    struct Event: Decodable {
        var sender: String
        var type: String
        var originServerTs: Int

        private enum CodingKeys: String, CodingKey {
            case sender
            case type
            case originServerTs    = "origin_server_ts"
        }
    }
    
    private enum TopLevelCodingKeys: String, CodingKey {
        case nextBatch         = "next_batch"
        case rooms
    }
    
    private enum JoinCodingKeys: String, CodingKey {
        case join
    }

    // You must decode the JSON manually
    init(from decoder: Decoder) throws {
        self.rooms = [Room]()
        
        let container = try decoder.container(keyedBy: TopLevelCodingKeys.self)
        self.nextBatch  = try container.decode(String.self, forKey: .nextBatch)
        
        var joined : KeyedDecodingContainer<SyncResponse.JoinCodingKeys>? = nil
        do {
           joined = try container.nestedContainer(keyedBy: JoinCodingKeys.self, forKey: .rooms)
        } catch {
//            StatusModel.shared.show(message: "No new messages since last update", level: .INFO, )
            print("No new messages since last update")
        }
        if (joined != nil) {
            let roomsContainer = try joined!.nestedContainer(keyedBy: GenericCodingKeys.self, forKey: .join)
            for key in roomsContainer.allKeys {
                let roomResponse = try roomsContainer.decode(RoomResponse.self, forKey: key)
                var room = Room(key: key.stringValue)
                let events = roomResponse.timeline.events
                if (!events.isEmpty) {
                    let nonJoinEvents = events.filter { event in
                        event.type != "m.room.member"
                    }
                    var lastEvent = roomResponse.timeline.events.last!
                    if (!nonJoinEvents.isEmpty) {
                        lastEvent = nonJoinEvents.last!
                    }
                    room.lastMessage = Message(sender: lastEvent.sender, timestamp: Date(timeIntervalSince1970: TimeInterval(lastEvent.originServerTs/1000)))
                }
                self.rooms.append(room)
            }
        }
    }
}

enum SessionStore: String {
    case homeserver = "HOMESERVER"
    case userId = "USER_ID"
    case accessToken = "ACCESS_TOKEN"
    case nextBatchToken = "NEXT_BATCH_TOKEN"
}

