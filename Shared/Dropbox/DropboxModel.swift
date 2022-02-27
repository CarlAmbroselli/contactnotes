//
//  DropboxModel.swift
//  Crew (iOS)
//
//  Created by dev on 27.02.22.
//

import Foundation

import Foundation
import SwiftyDropbox
import CoreData

class DropboxModel {
    
    static let shared: DropboxModel = {
        let instance = DropboxModel()
        DropboxClientsManager.setupWithAppKey("ye6kkzaoel3xtca")
        return instance
    }()
    
    var state: String = "Uninitialized"
    let rootFolderPath = "/data/notes/crew"
    
    func updateDropboxState(resultHandler: @escaping (Bool, String) -> Void) {
        print("updateDropboxState")
        guard let client = DropboxClientsManager.authorizedClient else {
            print("failed to init client!")
            state = "Failed to initialize client"
            return
        }
        client.users.getCurrentAccount().response { response, error in
            if let account = response {
                resultHandler(true, "Authenticated \(account.name.givenName)")
            } else {
                resultHandler(false, error?.description ?? "no error")
            }
        }
    }
    
    func uploadLocations() {
        
    }
}
