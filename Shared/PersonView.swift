//
//  PersonView.swift
//  Crew
//
//  Created by dev on 26.02.22.
//

import SwiftUI
import Contacts

struct PersonView: View {
    @State var person: CNContact
    var viewModel: CrewModel
    
    var body: some View {
        Text(person.note)
        Button("Update note") {
            let date = Date()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions.insert(.withFractionalSeconds)
            let note = formatter.string(from: date)
            
            self.person = viewModel.updateNote(contact: person, note: note)
        }

    }
    
}
