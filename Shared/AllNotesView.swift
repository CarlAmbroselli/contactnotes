//
//  AllNotesView.swift
//  Crew (iOS)
//
//  Created by dev on 27.02.22.
//

import SwiftUI

struct AllNotesView: View {
    @FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Note.timestamp, ascending: true)],
            animation: .default)
    private var notes: FetchedResults<Note>
    private var dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
    }
    
    var body: some View {
        ScrollView {
            ForEach(notes) { note in
                VStack {
                    if (note.timestamp != nil && note.contactName != nil) {
                        Text("\(note.contactName!) | \(dateFormatter.string(from: note.timestamp!))")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .foregroundColor(.secondary)
                            .padding([.bottom], 3)
                    }
                    if (note.text != nil) {
                        HStack {
                            Text(note.text!)
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
