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
    
    func updateMatrixRoomForPerson(person: CNContact, room: String) {
        let updatedContact = ContactUtils.updateMatrixRoomForPerson(person: person, room: room)
        updatedPerson(updatedContact)
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
    
    func lastMessageIndicatorForContact(person: CNContact) -> LastContactIndicator {
        if (!MatrixModel.shared.isAuthenticated || person.matrixRoom == nil) {
            return .unknown
        }
        let group = ContactUtils.contactGroupOfPerson(person)
        let slightlyOver = Date().timeIntervalSince(Calendar.current.date(
            byAdding: .day,
            value: 7,
            to: Date())!)
        guard let lastTimestamp = (MatrixModel.shared.roomTimestamps[person.matrixRoom!] ?? nil) else {
            return .unknown
        }
        var targetDate: Date
        switch (group) {
            case .WEEKS_3:
                targetDate = Calendar.current.date(
                    byAdding: .day,
                    value: -21,
                    to: Date())!
            case .MONTHS_2:
                targetDate = Calendar.current.date(
                    byAdding: .month,
                    value: -2,
                    to: Date())!
            case .MONTHS_6:
                targetDate = Calendar.current.date(
                    byAdding: .month,
                    value: -6,
                    to: Date())!
            case .YEARLY:
                targetDate = Calendar.current.date(
                    byAdding: .year,
                    value: -1,
                    to: Date())!
            case .ALL_CONTACTS:
                return .unknown
        }
            
        let timeframe = lastTimestamp.timeIntervalSince(targetDate)
        if (timeframe > 0) {
            return .withinTimeframe
        } else if (slightlyOver < timeframe) {
            return .slightlyOver
        } else {
            return .significantlyOver
        }
    }
}

public enum LastContactIndicator: String {
    case unknown
    case withinTimeframe
    case slightlyOver
    case significantlyOver
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
