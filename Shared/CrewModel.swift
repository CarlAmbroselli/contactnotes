//
//  CrewModel.swift
//  Crew
//
//  Created by dev on 25.02.22.
//

import Foundation
import SwiftyContacts

class CrewModel: ObservableObject {
    @Published var people: [CNContact] = Array()
    
    func loadPeople() async {
        let access = (try? await requestAccess()) ?? false
        if (access) {
            let keys = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactNoteKey as CNKeyDescriptor,
                CNContactIdentifierKey as CNKeyDescriptor
            ]
            fetchContacts(keysToFetch: keys, order: .userDefault, unifyResults: true, { result in
                result.map { contacts in
                    DispatchQueue.main.async {
                        self.people = contacts
                    }
                }
            })
        }
    }
    
    func updateNote(contact: CNContact, newNote: String) -> CNContact {
        guard let updatedContact = contact.mutableCopy() as? CNMutableContact else {
            return contact
        }
        
        let date = Date()

        let iso8601DateFormatter = ISO8601DateFormatter()
        iso8601DateFormatter.timeZone = TimeZone.current
        iso8601DateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = iso8601DateFormatter.string(from: date)
        
        let note = """
        🗓 \(dateString)
        📝 \(newNote)
        ==========
        \(contact.note)
        """
        
        updatedContact.note = note
        try? updateContact(updatedContact)
        let index = self.people.firstIndex(of: contact)
        if (index != nil) {
            self.people[index!] = updatedContact
        }
        return updatedContact
    }
}
