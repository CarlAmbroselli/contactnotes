//
//  CrewModel.swift
//  Crew
//
//  Created by dev on 25.02.22.
//

import Foundation
import SwiftyContacts
import UserNotifications
import CoreData

class CrewModel: ObservableObject {
    @Published var people: [CNContact] = Array()
    @Published var filteredGroup: ContactGroup = ContactGroup.WEEKS_3 {
        didSet {
            Task.init(priority: .high, operation: {
                await loadPeople()
            })
        }
    }
    static var dropboxViewModel = DropboxViewModel()
    
    func loadPeople() async {
        let access = (try? await requestAccess()) ?? false
        if (access) {
            let keys = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactIdentifierKey as CNKeyDescriptor
            ]
            let cnGroup = contactGroupToCnGroup(filteredGroup)
            if (filteredGroup != ContactGroup.ALL_CONTACTS && cnGroup != nil) {
                guard let contacts = try? fetchContacts(withGroupIdentifier: cnGroup!.identifier, keysToFetch: keys) else {
                    return
                }
                DispatchQueue.main.async {
                    self.people = contacts
                }
            } else {
                fetchContacts(keysToFetch: keys, order: .userDefault, unifyResults: true, { result in
                    guard let contacts = try? result.get() else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.people = contacts
                    }
                })
            }
        }
    }
    
    private func contactGroupToCnGroup(_ group: ContactGroup) -> CNGroup? {
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
    
    private func getGroupsThatAreContactGroupsForPerson(_ person: CNContact) -> [CNGroup] {
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
    
    func contactGroupOfPerson(_ person: CNContact) -> ContactGroup {
        let groups = getGroupsThatAreContactGroupsForPerson(person)
        if (groups.isEmpty) {
            return ContactGroup.ALL_CONTACTS
        } else {
            return ContactGroup.allCases.first { contactGroup in
                contactGroup.rawValue == groups.first!.name
            }!
        }
    }
    
    func updateGroupForPerson(person: CNContact, group targetGroup: ContactGroup) {
        let groupsOfContact = getGroupsThatAreContactGroupsForPerson(person)
        let groupToBeAdded = contactGroupToCnGroup(targetGroup)
        
        ContactGroup.allCases.forEach { possibleGroup in
            let isMemberOf = groupsOfContact.contains(where: { groupOfContact in
                groupOfContact.name == possibleGroup.rawValue
            })
            let cnGroup = contactGroupToCnGroup(possibleGroup)
            if (!isMemberOf && possibleGroup == targetGroup && groupToBeAdded != nil) {
                try? addContact(person, to: groupToBeAdded!)
            } else if (isMemberOf && possibleGroup != targetGroup && cnGroup != nil) {
                try? deleteContact(person, from: cnGroup!)
            }
        }
        Task.init(priority: .medium, operation: {
            await loadPeople()
        })
    }
    
    func scheduleNotification(note: Note, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = note.contactName!
        content.body = note.text!
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        let viewContext = note.managedObjectContext
        if (viewContext != nil) {
            let reminder = Reminder(context: viewContext!)
            reminder.text = note.text
            reminder.contactName = note.contactName
            reminder.timestamp = Date().addingTimeInterval(timeInterval)
            try? viewContext!.save()
        }
    }
}
