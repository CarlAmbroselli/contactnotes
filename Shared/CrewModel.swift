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
    @Published var people: [ContactGroup: [CNContact]] = [ContactGroup: [CNContact]]()
    
    static var dropboxViewModel = DropboxViewModel()
    
    func loadPeople() async {        
        let access = (try? await requestAccess()) ?? false
        if (access) {
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
                    seenContacts.insert(contact.identifier)
                }
            }
            
            fetchContacts(keysToFetch: keys, order: .userDefault, unifyResults: true, { result in
                guard let contacts = try? result.get() else {
                    return
                }
                loadedPeople[ContactGroup.ALL_CONTACTS] = contacts.filter { contact in
                    !seenContacts.contains(contact.identifier)
                }
            })
            let peopleResult = loadedPeople
            DispatchQueue.main.async {
                self.people = peopleResult
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
    
    func updateMatrixRoomForPerson(person: CNContact, room: String) {
        guard let mutableContact = person.mutableCopy() as? CNMutableContact else { return }
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
        Task.init(priority: .medium, operation: {
            await loadPeople()
        })
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
        // choose a random identifier
        let uuid = UUID().uuidString
        
        // Define the custom actions.
        let completeAction = UNNotificationAction(identifier: "COMPLETE_ACTION",
              title: "Mark as completed",
              options: [])
        let sleep1H = UNNotificationAction(identifier: "SLEEP_1_H",
              title: "Remind me in 1h",
              options: [])
        let sleep24H = UNNotificationAction(identifier: "SLEEP_24_H",
              title: "Remind me in 24h",
              options: [])
        let sleep3D = UNNotificationAction(identifier: "SLEEP_3_D",
              title: "Remind me in 3 days",
              options: [])
        // Define the notification type
        let notificationCategories =
              UNNotificationCategory(identifier: "CREW_NOTIFICATION",
              actions: [completeAction, sleep1H, sleep24H, sleep3D],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)
        
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([notificationCategories])
        notificationCenter.delegate = NotificationHandler.shared
        
        let content = UNMutableNotificationContent()
        content.title = note.contactName!
        content.body = note.text!
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "CREW_NOTIFICATION"
        content.userInfo = [
            "reminderId": uuid
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        let viewContext = note.managedObjectContext
        if (viewContext != nil) {
            let reminder = Reminder(context: viewContext!)
            reminder.text = note.text
            reminder.contactName = note.contactName
            reminder.timestamp = Date().addingTimeInterval(timeInterval)
            reminder.identifier = uuid
            try? viewContext!.save()
        }
        
        StatusModel.shared.show(message: "Will remind in \((timeInterval + 10).relativeTimeIntervalDescription)", level: .SUCCESS)
    }
    
    func deleteReminder(_ reminder: Reminder) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminder.identifier!])
        guard let viewContext = reminder.managedObjectContext else {
            return 
        }
        viewContext.delete(reminder)
        try? viewContext.save()
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

extension Date {
    var relativeTimeDescriptionSinceNow: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(fromTimeInterval: self.timeIntervalSince(Date.now))
    }
}

extension TimeInterval {
    var relativeTimeIntervalDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(fromTimeInterval: self)
    }
}
