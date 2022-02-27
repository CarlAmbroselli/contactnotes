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
    
    func loadPeople(group: ContactGroup) async {
        let access = (try? await requestAccess()) ?? false
        if (access) {
            let keys = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactIdentifierKey as CNKeyDescriptor
            ]
            if (group != ContactGroup.ALL_CONTACTS) {
                var groups = try! fetchGroups()
                var filterGroup = groups.first { groupElement in
                    groupElement.name == group.rawValue
                }
                if (filterGroup == nil) {
                    try! addGroup(group.rawValue)
                    groups = try! fetchGroups()
                    filterGroup = groups.first { groupElement in
                        groupElement.name == group.rawValue
                    }
                }
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
    
    func getGroupsForPerson(person: CNContact) {
        
    }
}
