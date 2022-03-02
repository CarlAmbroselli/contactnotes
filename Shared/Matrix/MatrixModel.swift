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
    private var mxRestClient: MXRestClient?
    
    init() {
        isAuthenticated = (UserDefaults.standard.string(forKey: SessionStore.accessToken.rawValue) != nil)
    }
    
    func authenticate(homeServer: String, userId: String, accessToken: String) {
        let credentials = MXCredentials(homeServer: "https://\(homeServer)",
                                        userId: userId,
                                        accessToken: accessToken)
        
        // Create a matrix client
        mxRestClient = MXRestClient(credentials: credentials, unrecognizedCertificateHandler: nil)
        
        // Create a matrix session
        mxSession = MXSession(matrixRestClient: mxRestClient)
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
    
    func sync() {
        guard let session = mxSession else {
            print("Can't refresh, no session yet")
            return
        }
        session.backgroundSync(withTimeout: 60*60*24) { response in
            print("Background sync done")
        }
    }
    
    func login(username: String, password: String) {
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
        AF.request("https://matrix.org/_matrix/client/r0/login", method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
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

