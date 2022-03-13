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
    var roomCount: Int {
        guard let rooms = self.mxSession?.rooms else {
            return 0
        }
        return rooms.count
    }
    
    private var mxSession: MXSession?
    private var store: MXFileStore?
    private var mxRestClient: MXRestClient?
    
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
    }
    
    func lastEventDateForUser(roomId: String) -> Date? {
        guard let session = self.mxSession else {
            return nil
        }
        let rooms = session.rooms.filter { room in
            guard let id = room.roomId else {
                return false
            }
            return id == roomId
        }
        if (rooms.count == 0) {
            return nil
        } else {
            guard let timestamp = rooms.first?.summary?.lastMessageEvent.originServerTs else {
                return nil
            }
            return Date(timeIntervalSince1970: Double(timestamp / 1000))
        }
        
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
            StatusModel.shared.show(message: "Can't authenticate, no session available!", level: .ERROR)
            return
       }
        
        isAuthenticated = true
        
        // Launch mxSession: it will first make an initial sync with the homeserver
        StatusModel.shared.show(message: "Starting matrix sync...", level: .INFO, permanent: true)
        session.start { response in
            guard response.isSuccess else {
                StatusModel.shared.show(message: "Failed to login! \(String(describing: response.error?.localizedDescription))", level: .ERROR)
                return
            }
            
            StatusModel.shared.show(message: "Login successful!", level: .SUCCESS)
        }
    }
    
    func sync() {
        guard let session = mxSession else {
            StatusModel.shared.show(message: "Can't refresh Matrix, no session yet", level: .ERROR)
            return
        }
        mxSession?.setStore(store!, completion: { response in
            session.start { response in
                guard response.isSuccess else { return }
            }
        })
    }
    
    func login(username: String, password: String, homeserver: String) {
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
                StatusModel.shared.show(message: "Login successful", level: .INFO, permanent: true)
                self.authenticate(homeServer: session.home_server, userId: session.user_id, accessToken: session.access_token)
            }
    }
    
    func logout() {
        self.mxSession?.logout(completion: { response in
            if (response.isSuccess) {
                StatusModel.shared.show(message: "Logout successful", level: .SUCCESS)
            } else {
                StatusModel.shared.show(message: "Logout failed. \(response.error.debugDescription)", level: .ERROR)
            }
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

