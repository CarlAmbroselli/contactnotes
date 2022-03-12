//
//  MatrixModel.swift
//  Crew (iOS)
//
//  Created by dev on 01.03.22.
//

import Foundation
import MatrixSDK
import Alamofire

class MatrixModel: ObservableObject {
    static let shared = MatrixModel()
    @Published var isAuthenticated: Bool
    
    private var mxSession: MXSession?
    private var store: MXFileStore?
    private var mxRestClient: MXRestClient?
//    private var membersByRoomId: [String: [MXRoomMember]]
    @Published var roomsByUserId: [String: [MXRoom]]
    
    init() {
        let accessToken = UserDefaults.standard.string(forKey: SessionStore.accessToken.rawValue)
        if (accessToken != nil) {
            let homeServer = UserDefaults.standard.string(forKey: SessionStore.homeserver.rawValue)!
            let userId = UserDefaults.standard.string(forKey: SessionStore.userId.rawValue)!
            let credentials = MXCredentials(homeServer: "https://\(homeServer)",
                                            userId: userId,
                                            accessToken: accessToken)
            store = MXFileStore.init(credentials: credentials)
            mxRestClient = MXRestClient(credentials: credentials, unrecognizedCertificateHandler: nil)
            mxSession = MXSession(matrixRestClient: mxRestClient)
        }
        isAuthenticated = accessToken != nil
        roomsByUserId = [String: [MXRoom]]()
    }
    
    func authenticate(homeServer: String, userId: String, accessToken: String) {
        let credentials = MXCredentials(homeServer: "https://\(homeServer)",
                                        userId: userId,
                                        accessToken: accessToken)
        
        // Create a matrix client
        let client = MXRestClient(credentials: credentials, unrecognizedCertificateHandler: nil)
        
        // Create a matrix session
        mxRestClient = client
        mxSession = MXSession(matrixRestClient: client)
        guard let session = mxSession else {
           print("Oh no!")
           return
       }
        
        isAuthenticated = true
        
        print("logged in!")
        // Launch mxSession: it will first make an initial sync with the homeserver
        session.start { response in
            guard response.isSuccess else { return }
            
            // mxSession is ready to be used
            // now wer can get all rooms with:
            print("ROOMS", session.rooms)
        }
    }
    
//    func roomsForUser(username: String) -> [MXRoom] {
//        guard let session = mxSession else {
//            print("Can't load rooms, no session yet")
//            return nil
//        }
//        let matchedUsers = session.users().filter { user in
//            guard let name = user.displayname else {
//                return false
//            }
//            return name.lowercased().contains(username)
//        }
//        let rooms = [MXRoom]()
//        session.rooms.forEach { room in
//            room.membe
//        }
//        matchedUsers.forEach { user in
//            user.
//        }
//    }
    
    func findUserByName(_ name: String) -> MXUser? {
        guard let session = mxSession else {
            print("Can't load rooms, no session yet")
            return nil
        }
        guard let sessionUsers = session.users() else {
            print("Can't load session users")
            return nil
        }
        let users = sessionUsers.filter { user in
            guard let displayName = user.displayname else {
                return false
            }
            return displayName.lowercased().contains(name.lowercased())
        }
        if (!users.isEmpty) {
            return users.first
        } else {
            return nil
        }
    }
    
    func lastMessageEventForPerson(name: String) -> MXEvent? {
        guard let user = findUserByName(name) else {
            return nil
        }
        guard let room = self.roomsByUserId[user.userId!] else {
            print("No room found")
            return nil
        }
        if (room.count == 0) {
            return nil
        }
        print("Accessed!!")
        print(room.first!.roomId)
        return room.first!.summary.lastMessageEvent
    }
    
    func loadRoomsByUser() {
        guard let session = mxSession else {
            print("Can't load rooms, no session yet")
            return
        }
        session.rooms.forEach { room in
            room.members { roomMembers in
                guard let membersResponse = roomMembers.value else {
                    print("Failed to load room members for \(room.roomId.debugDescription)")
                    return
                }
                guard let members = membersResponse else {
                    print("Failed to unpack room members for \(room.roomId.debugDescription)")
                    return
                }
                let _room = room
                DispatchQueue.main.async {
                    // ignore group rooms
                    let memberCount = members.members!.filter { member in
                        guard let name = member.displayname else {
                            return true
                        }
                        let isBot = name.contains("bridge bot")
                        print("\(_room.roomId) - \(name) : \(isBot)")
                        return !isBot
                    }.count
                    print("Member count: \(memberCount)")
                    if (memberCount < 3 || true) {
                        members.members!.forEach { member in
                            if (self.roomsByUserId[member.userId!] == nil) {
                                self.roomsByUserId[member.userId!] = [MXRoom]()
                            }
                            self.roomsByUserId[member.userId!]!.append(_room)
                            if (member.displayname != nil) {
                                print("Loaded user \(member.displayname!)")
                            } else {
                                print("Loaded user \(member.userId!)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func sync() {
        guard let session = mxSession else {
            print("Can't refresh, no session yet")
            return
        }
        mxSession?.setStore(store!, completion: { response in
            session.start { response in
                guard response.isSuccess else { return }
                self.loadRoomsByUser()
            }
        })
        
        
//        session.backgroundSync(withTimeout: 60*60*24) { response in
//            print(response)
//            print("Background sync done")
//            self.loadRoomsByUser()
//        }
    }
    
    func login(username: String, password: String, homeserver: String) {
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
                    print("Login failed!")
                    if (response.data != nil) {
                        print(String(decoding: response.data!, as: UTF8.self))
                    }
                    return
                }
                UserDefaults.standard.set(session.home_server, forKey: SessionStore.homeserver.rawValue)
                UserDefaults.standard.set(session.user_id, forKey: SessionStore.userId.rawValue)
                UserDefaults.standard.set(session.access_token, forKey: SessionStore.accessToken.rawValue)
                UserDefaults.standard.synchronize()
                self.authenticate(homeServer: session.home_server, userId: session.user_id, accessToken: session.access_token)
            }
    }
    
    func logout() {
        self.mxSession?.logout(completion: { response in
            print(response)
        })
        UserDefaults.standard.removeObject(forKey: SessionStore.homeserver.rawValue)
        UserDefaults.standard.removeObject(forKey: SessionStore.userId.rawValue)
        UserDefaults.standard.removeObject(forKey: SessionStore.accessToken.rawValue)
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

enum SessionStore: String {
    case homeserver = "HOMESERVER"
    case userId = "USER_ID"
    case accessToken = "ACCESS_TOKEN"
}

