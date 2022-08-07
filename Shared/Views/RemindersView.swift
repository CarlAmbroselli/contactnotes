//
//  NotificationsView.swift
//  Crew
//
//  Created by dev on 27.02.22.
//

import SwiftUI
import CoreData

struct RemindersView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Reminder.timestamp, ascending: true)],
        animation: .default)
    private var reminders: FetchedResults<Reminder>
    
    var body: some View {
        List {
            ForEach(reminders) { reminder in
                VStack {
                    if (reminder.timestamp != nil && reminder.contactName != nil) {
                        Text("\(reminder.contactName!) | \(reminder.timestamp!.formatted)")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .foregroundColor(.secondary)
                            .padding([.bottom], 3)
                    }
                    if (reminder.text != nil) {
                        HStack {
                            Text(reminder.text!)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Spacer()
                            .frame(height: 15)
                    }
                }
                .listRowSeparator(.hidden)
                .font(Font.custom("IowanOldStyle-Roman", size: 16))
            }.onDelete { offsets in
                for i in offsets.makeIterator() {
                    let reminder = reminders[i]
                    NotificationUtils.deleteReminder(reminder)
                }
            }
        }.listStyle(PlainListStyle())
    }
}
