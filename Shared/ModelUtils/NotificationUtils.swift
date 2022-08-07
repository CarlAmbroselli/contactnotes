//
//  NotificationHandler.swift
//  Crew (iOS)
//
//  Created by dev on 12.03.22.
//

import Foundation
import UserNotifications

class NotificationUtils: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationUtils()
    
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
            if let error = error {
                StatusModel.shared.show(message: "Failed setting up push notification: \(error.localizedDescription)", level: .ERROR)
            }
        }
    }
       
    /** Handle notification when app is in background */
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response:
        UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        StatusModel.shared.show(message: "Notification received in background", level: .SUCCESS)
        rescheduleNotification(notification: response)
        
//        let notiName = Notification.Name(response.notification.request.identifier)
//        NotificationCenter.default.post(name:notiName , object: response.notification.request.content)
        completionHandler()
    }
    
    /** Handle notification when the app is in foreground */
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
             withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        StatusModel.shared.show(message: "Notification received in foreground", level: .INFO)
        
//        let notiName = Notification.Name( notification.request.identifier )
//        NotificationCenter.default.post(name:notiName , object: notification.request.content)
        completionHandler(.sound)
    }
    
    func rescheduleNotification(notification: UNNotificationResponse) {
        var timeInterval: TimeInterval
        
        switch(notification.actionIdentifier) {
            case "SLEEP_1_H":
                timeInterval = 60*60
            case "SLEEP_24_H":
                timeInterval = 60*60*24
            case "SLEEP_3_D":
                timeInterval = 60*60*24*3
            default:
                timeInterval = -1
        }
        
        if (timeInterval > 0) {
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.delegate = NotificationUtils.shared
            
            let content = UNMutableNotificationContent()
            content.title = notification.notification.request.content.title
            content.body = notification.notification.request.content.body
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "CREW_NOTIFICATION"
            content.userInfo = notification.notification.request.content.userInfo

            // show this notification five seconds from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

            let request = UNNotificationRequest(identifier: notification.notification.request.content.userInfo["reminderId"] as! String, content: content, trigger: trigger)

            // add our notification request
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    static func scheduleNotification(note: Note, timeInterval: TimeInterval) {
        if (timeInterval < 0) {
            return
        }
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
        notificationCenter.delegate = NotificationUtils.shared
        
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
            reminder.linkedNote = note
            try? viewContext!.save()
        }
        
        StatusModel.shared.show(message: "Will remind \((timeInterval + 1000).relativeTimeIntervalDescription)", level: .SUCCESS)
    }
    
    static func deleteReminder(_ reminder: Reminder) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminder.identifier!])
        guard let viewContext = reminder.managedObjectContext else {
            return
        }
        viewContext.delete(reminder)
        try? viewContext.save()
    }
}
