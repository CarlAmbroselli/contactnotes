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
    @State var newNote: String = ""
    
    var viewModel: CrewModel
    
    var body: some View {
        VStack {
            Spacer()
            ScrollView {
                Text(person.note)
                ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                    if newNote.isEmpty {
                        Text("Add note...")
                            .foregroundColor(Color(.label))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $newNote)
                        .opacity(newNote.isEmpty ? 0.7 : 1)
                        .frame(minHeight: 200, alignment: .leading)
                }
                .padding([.leading, .trailing], 8)
                .overlay(
                    Rectangle()
                        .stroke(Color(.systemGray5), lineWidth: 1.0)
                )
                Spacer()
                Button("Speichern") {
                    self.person = viewModel.updateNote(contact: person, newNote: newNote)
                    self.newNote = ""
                }
            }
        }

    }
    
}
