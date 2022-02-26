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
                CNContactNoteKey as CNKeyDescriptor
            ]
            fetchContacts(keysToFetch: keys, order: .userDefault, unifyResults: true, { result in
                print(result)
                result.map { contacts in
                    DispatchQueue.main.async {
                        self.people = contacts
                    }
                }
            })
        }
    }
}
