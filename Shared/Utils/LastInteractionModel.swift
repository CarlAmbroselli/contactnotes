//
//  LastInteractionModel.swift
//  Crew (iOS)
//
//  Created by dev on 06.03.22.
//

import Foundation
import MatrixSDK
import Contacts

class LastInteractionModel: ObservableObject {
    
    var person: CNContact?
    @Published var lastMessage = "123"

    func initSink(person: CNContact) {
        self.person = person
        self.updateMessage()
        MatrixModel.shared.$roomsByUserId.sink { _ in
            DispatchQueue.main.async {
                self.updateMessage()
            }
        }
    }
    
    func updateMessage() {
        print("UPDATE!")
        guard let person = self.person else {
            print("no person")
            return
        }
        guard let event: MXEvent = MatrixModel.shared.lastMessageEventForPerson(name: person.fullName) else {
            print("no event")
            return
        }
        lastMessage = event.content.debugDescription
    }
    
}
