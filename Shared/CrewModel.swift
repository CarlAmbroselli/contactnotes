//
//  CrewModel.swift
//  Crew
//
//  Created by dev on 25.02.22.
//

import Foundation
import SwiftyContacts

class CrewModel: ObservableObject {
    @Published var people: [String] = Array()
    
    func loadPeople() async {
        let access = (try? await requestAccess()) ?? false
        if (access) {
            guard let contacts = try? await fetchContacts() else {
                return
            }
            DispatchQueue.main.async {
                contacts.forEach { contact in
                    self.people.append(contact.familyName)
                }
            }
        }
    }
}
