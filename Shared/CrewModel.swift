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
    
    func loadPeople() async {
        let access = (try? await requestAccess()) ?? false
        if (access) {
            let groupedContacts = await ContactUtils.groupedContacts()
            DispatchQueue.main.async {
                self.people = groupedContacts
            }
        } else {
            StatusModel.shared.show(message: "Missing contact access permissions!", level: .ERROR)
        }
    }
    
    func updatedPerson(_ updatedPerson: CNContact) {
        self.people = self.people.mapValues({ contacts in
            return contacts.map { contact in
                return (contact.identifier == updatedPerson.identifier) ? updatedPerson : contact
            }
        })
    }
    
    func updateGroupForPerson(person: CNContact, group targetGroup: ContactGroup) {
        let removedFromGroups = ContactUtils.updateGroupForPerson(person: person, group: targetGroup)
        if (!removedFromGroups.isEmpty) {
            self.people = Dictionary(uniqueKeysWithValues: self.people.map { (key: ContactGroup, value: [CNContact]) in
                if (removedFromGroups.contains(where: { contactGroup in
                    contactGroup == key
                })) {
                    return (key, value.filter({ contact in
                        contact.identifier != person.identifier
                    }))
                } else if key == targetGroup {
                    return (key, value + [person])
                } else {
                    return (key, value)
                }
            })
        }
    }
    
    func scheduleNotification(note: Note, timeInterval: TimeInterval) {
        NotificationUtils.scheduleNotification(note: note, timeInterval: timeInterval)
    }
    
    func deleteReminder(_ reminder: Reminder) {
        NotificationUtils.deleteReminder(reminder)
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
