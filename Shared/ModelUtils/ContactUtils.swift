//
//  ContactUtils.swift
//  Crew
//
//  Created by dev on 27.03.22.
//

import Foundation
import SwiftyContacts

public class ContactUtils {
    
    static func groupedContacts() async -> [ContactGroup : [CNContact]] {
        let keys = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactSocialProfilesKey as CNKeyDescriptor
        ]
        var seenContacts: Set<String> = []
        var loadedPeople = [ContactGroup: [CNContact]]()
        
        ContactGroup.allCases.filter { group in
            group != ContactGroup.ALL_CONTACTS
        }.forEach { contactGroup in
            guard let contacts = try? fetchContacts(withGroupIdentifier: contactGroupToCnGroup(contactGroup)!.identifier, keysToFetch: keys) else {
                return
            }
            loadedPeople[contactGroup] = contacts
            contacts.forEach { contact in
                if (contact.fullName.count > 0) {
                    seenContacts.insert(contact.identifier)
                }
            }
        }
        
        fetchContacts(keysToFetch: keys, order: .userDefault, unifyResults: true, { result in
            guard let contacts = try? result.get() else {
                return
            }
            loadedPeople[ContactGroup.ALL_CONTACTS] = contacts.filter { contact in
                !seenContacts.contains(contact.identifier) && contact.fullName.count > 0
            }
        })
        return loadedPeople
    }
    
    static func contactGroupToCnGroup(_ group: ContactGroup) -> CNGroup? {
        if (group == ContactGroup.ALL_CONTACTS) {
            return nil
        }
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
        return filterGroup
    }
    
    static func getGroupsThatAreContactGroupsForPerson(_ person: CNContact) -> [CNGroup] {
        let groups = try! fetchGroups()
        let contactGroups = groups.filter { group in
            ContactGroup.allCases.contains { contactGroup in
                contactGroup.rawValue == group.name
            }
        }
        var groupsOfPerson: [CNGroup] = []
        
        let keys = [
            CNContactIdentifierKey as CNKeyDescriptor
        ]
        contactGroups.forEach { group in
            let contacts = try? fetchContacts(withGroupIdentifier: group.identifier, keysToFetch: keys)
            if (contacts != nil) {
                contacts?.filter({ contact in
                    contact.identifier == person.identifier
                }).forEach({ _ in
                    groupsOfPerson.append(group)
                })
            }
        }
        return groupsOfPerson
    }
    
    static func contactGroupOfPerson(_ person: CNContact) -> ContactGroup {
        let groups = getGroupsThatAreContactGroupsForPerson(person)
        if (groups.isEmpty) {
            return ContactGroup.ALL_CONTACTS
        } else {
            return ContactGroup.allCases.first { contactGroup in
                contactGroup.rawValue == groups.first!.name
            }!
        }
    }
    
    static func updateMatrixRoomForPerson(person: CNContact, room: String) -> CNContact {
        guard let mutableContact = person.mutableCopy() as? CNMutableContact else {
            return person
        }
        var socialProfiles = mutableContact.socialProfiles.filter { profile in
            guard let label = profile.label else {
                return true
            }
            if (label == "Matrix") {
                // removing existing matrix profiles
                return false
            } else {
                return true
            }
        }
        
        let matrixProfile = CNLabeledValue(label: "Matrix", value: CNSocialProfile(urlString: room, username: room, userIdentifier: room, service: "Matrix"))
        socialProfiles.append(matrixProfile)
        mutableContact.socialProfiles = socialProfiles
        
        do {
            try updateContact(mutableContact)
        } catch {
            StatusModel.shared.show(message: "Error saving contact! \(error)", level: .ERROR)
        }
        return mutableContact
    }
    
    static func updateGroupForPerson(person: CNContact, group targetGroup: ContactGroup) -> [ContactGroup] {
        if (contactGroupOfPerson(person) == targetGroup) {
            return []
        }
        
        let groupsOfContact = getGroupsThatAreContactGroupsForPerson(person)
        let groupToBeAdded = contactGroupToCnGroup(targetGroup)
        
        var removedFromGroups = [ContactGroup]();
        
        ContactGroup.allCases.forEach { possibleGroup in
            let isMemberOf = groupsOfContact.contains(where: { groupOfContact in
                groupOfContact.name == possibleGroup.rawValue
            })
            let cnGroup = contactGroupToCnGroup(possibleGroup)
            if (!isMemberOf && possibleGroup == targetGroup && groupToBeAdded != nil) {
                try? addContact(person, to: groupToBeAdded!)
            } else if (isMemberOf && possibleGroup != targetGroup && cnGroup != nil) {
                try? deleteContact(person, from: cnGroup!)
                removedFromGroups.append(possibleGroup)
            }
        }
        
        if (targetGroup != ContactGroup.ALL_CONTACTS) {
            removedFromGroups.append(ContactGroup.ALL_CONTACTS)
        }
        
        return removedFromGroups
    }
}

extension CNContact {
    var fullName: String {
        return "\(self.givenName) \(self.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var matrixRoom: String? {
        let rooms = self.socialProfiles.filter { profile in
            guard let label = profile.label else {
                return false
            }
            return label == "Matrix"
        }
        if (rooms.count > 0) {
            return rooms.first!.value.username
        } else {
            return nil
        }
    }
}

extension String {
    var initials: String {
        return self.components(separatedBy: " ")
            .reduce("") {
                ($0.isEmpty ? "" : "\($0.first?.uppercased() ?? "")") +
                ($1.isEmpty ? "" : "\($1.first?.uppercased() ?? "")")
            }
    }
}
