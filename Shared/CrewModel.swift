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
    
    func loadPeople(group: String?) async {
        print("Loading group \(group)")
        let access = (try? await requestAccess()) ?? false
        if (access) {
            let keys = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactIdentifierKey as CNKeyDescriptor
            ]
            if (group != nil) {
                let groups = try! fetchGroups()
                let filterGroup = groups.first { groupElement in
                    groupElement.name == group!
                }
                print("Groups \(groups)")
                guard let contacts = try? fetchContacts(withGroupIdentifier: filterGroup!.identifier, keysToFetch: keys) else {
                    return
                }
                DispatchQueue.main.async {
                    self.people = contacts
                }
            } else {
                fetchContacts(keysToFetch: keys, order: .userDefault, unifyResults: true, { result in
                    result.map { contacts in
                        DispatchQueue.main.async {
                            self.people = contacts
                        }
                    }
                })
            }
        }
    }
}
