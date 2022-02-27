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
import CodableCSV

class DropboxModel {
    
    static let shared: DropboxModel = {
        let instance = DropboxModel()
        DropboxClientsManager.setupWithAppKey("ye6kkzaoel3xtca")
        return instance
    }()
    
    var state: String = "Uninitialized"
    let rootFolderPath = "/data/notes/crew"
    @Published var syncStatus = "Not synced yet"
    
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
    
    func uploadNotes(completionHandler: @escaping (String) -> Void) {
        let timestampSort = NSSortDescriptor(key:"timestamp", ascending:true)
        let fetchRequest = Note.fetchRequest() as NSFetchRequest<Note>
        fetchRequest.sortDescriptors = [timestampSort]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let asyncFetch = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { result in

            do {
                guard let notes = result.finalResult else {
                  print("Failed to fetch notes")
                  return
                }
                
                let fields = ["timestamp", "contactId", "contactName", "text"]
                let writer = try CSVWriter { $0.headers = fields }
                for note in notes {
                    try writer.write(row: ["\(Int(note.timestamp!.timeIntervalSince1970))", note.contactId!, note.contactName!, note.text!])
                }
                try writer.endEncoding()
                let result = try writer.data()
                
                guard let client = DropboxClientsManager.authorizedClient else {
                    print("client not initialized")
                    return
                }
                
                client.files.upload(path: "\(self.rootFolderPath)/notes.csv", mode: Files.WriteMode.overwrite, autorename: false, clientModified: nil, mute: true, propertyGroups: nil, strictConflict: false, input: result)
                    .response { response, error in
                        if let response = response {
                            completionHandler("Success")
                            print(response)
                        } else if let error: CallError<Files.UploadError> = error {
                            switch error {
                                case let .routeError(_, _, summary, _):
                                guard let summaryText = summary else {
                                    completionHandler("routeError")
                                    return
                                }
                                if (summaryText.contains("conflict")) {
                                    completionHandler("conflict")
                                }
                                case .internalServerError(_, _, _):
                                    completionHandler("internalServerError")
                                case .badInputError(_, _):
                                    completionHandler("badInputError")
                                case .rateLimitError(_, _, _, _):
                                    completionHandler("rateLimitError")
                                case .httpError(_, _, _):
                                    completionHandler("httpError")
                                case .authError(_, _, _, _):
                                    completionHandler("authError")
                                case .accessError(_, _, _, _):
                                    completionHandler("accessError")
                                case .clientError(_):
                                    completionHandler("clientError")
                            }
                            
                        }
                    }
                    .progress { progressData in
                        print(progressData)
                        // TODO: Handle incremental progress
                    }
                
            } catch let error {
                print("Error :(", error)
            }
            
        }
        
        do {
            let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
            try backgroundContext.execute(asyncFetch)
        } catch let error {
            print("Error!!", error)
        }
        
    }
}
