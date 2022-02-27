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
    
    func uploadNotes() {
        let timestampSort = NSSortDescriptor(key:"timestamp", ascending:true)
        let fetchRequest = Note.fetchRequest() as NSFetchRequest<Note>
        fetchRequest.sortDescriptors = [timestampSort]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let asyncFetch = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { result in

            guard let notes = result.finalResult else {
              print("Failed to fetch notes")
              return
            }
            let fields = ["timestamp", "contactId", "contactName", "text"]
            var currentCsv = fields.joined(separator: ";")
            notes.forEach({ note in
                currentCsv += "\n" + fields.map({ field in
                    if (field == "timestamp") {
                        guard let timestamp = note.timestamp else {
                            return ""
                        }
                        return "\(Int(timestamp.timeIntervalSince1970))"
                    } else {
                        return "\(note.value(forKey: field) ?? "")"
                    }
                }).joined(separator: ";")
            })
            print(currentCsv)
        }
        
        do {
            let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
            try backgroundContext.execute(asyncFetch)
        } catch let error {
            print("Error!!", error)
        }
        
    }
}
