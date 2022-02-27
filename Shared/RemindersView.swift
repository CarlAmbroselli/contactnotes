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
    private var dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
    }
    
    var body: some View {
        ScrollView {
            ForEach(reminders) { reminder in
                VStack {
                    if (reminder.timestamp != nil && reminder.contactName != nil) {
                        Text("\(reminder.contactName!) | \(dateFormatter.string(from: reminder.timestamp!))")
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
            }
        }
    }
}
