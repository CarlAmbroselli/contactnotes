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

class DropboxModel: ObservableObject {
    
    static let shared: DropboxModel = {
        let instance = DropboxModel()
        DropboxClientsManager.setupWithAppKey("wutcnkqpwly32py")
        return instance
    }()
    
    var state: String = "Uninitialized"
    let rootFolderPath = ""
    @Published var lastDropboxUpdate: Date?
    @Published var syncStatus = "Not synced yet"
    
    init() {
        loadLastUpdateState()
    }
    
    func loadLastUpdateState() {
        let lastUpdateDate = UserDefaults.standard.double(forKey: "last_dropbox_update")
        if (lastUpdateDate > 0) {
            self.lastDropboxUpdate = Date(timeIntervalSince1970: lastUpdateDate)
        }
    }
    
    func updateDropboxState(resultHandler: @escaping (Bool, String) -> Void) {
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
        
        let asyncFetch = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { result in

            do {
                guard let notes = result.finalResult else {
                    StatusModel.shared.show(message: "Failed to fetch notes", level: .ERROR)
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
                    StatusModel.shared.show(message: "Dropbox client not initialized", level: .ERROR)
                    return
                }
                
                client.files.upload(path: "\(self.rootFolderPath)/notes.csv", mode: Files.WriteMode.overwrite, autorename: false, clientModified: nil, mute: true, propertyGroups: nil, strictConflict: false, input: result)
                    .response { response, error in
                        if let response = response {
                            completionHandler("Success")
                            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_dropbox_update")
                            self.loadLastUpdateState()
                            print(response)
                            StatusModel.shared.show(message: "Messages synced to dropbox", level: .SUCCESS)
                        } else if let error: CallError<Files.UploadError> = error {
                            StatusModel.shared.show(message: "Error syncing to dropbox: \(error.description)", level: .ERROR)
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
                StatusModel.shared.show(message: "Error uploading notes: \(error.localizedDescription)", level: .ERROR)
            }
            
        }
        
        do {
            let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
            try backgroundContext.execute(asyncFetch)
        } catch let error {
            StatusModel.shared.show(message: "Error executing fetch: \(error.localizedDescription)", level: .ERROR)
        }
        
    }
}
