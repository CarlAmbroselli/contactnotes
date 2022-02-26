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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(person.note)
                Spacer().frame(minWidth: 0, maxWidth: .infinity, minHeight:0, maxHeight: .infinity, alignment: Alignment.topLeading)
                HStack(alignment: .bottom, spacing: 5) {
                    ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                        if newNote.isEmpty {
                            Text("Add note...")
                                .foregroundColor(Color(.label))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        ExpandingTextView(text: $newNote)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(.systemGray5), lineWidth: 1.0)
                    )
                    Button {
                        self.person = viewModel.updateNote(contact: person, newNote: newNote)
                        self.newNote = ""
                    } label: {
                        Image(systemName: "plus.circle")
                            .padding(5)
                            .foregroundColor(Color(.lightGray))
                            .background(Color(.darkGray))
                    }
                    .cornerRadius(4)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                }
            }.rotationEffect(Angle(degrees: 180))
        }.rotationEffect(Angle(degrees: 180))
    }
}
