//
//  NotificationHandler.swift
//  Crew (iOS)
//
//  Created by dev on 12.03.22.
//

import Foundation
import UserNotifications

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()
       
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
            notificationCenter.delegate = NotificationHandler.shared
            
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
}
