//
//  PersonView.swift
//  Crew
//
//  Created by dev on 26.02.22.
//

import SwiftUI
import Contacts
import CoreData

struct PersonView: View {
    @State var newNote: String = ""
    var person: CNContact
    var viewModel: CrewModel
    
    private var viewContext: NSManagedObjectContext
    private var fetchRequest: FetchRequest<Note>
    private var notes: FetchedResults<Note> {
        fetchRequest.wrappedValue
    }
    
    init(showPerson: CNContact, context: NSManagedObjectContext, model: CrewModel) {
        fetchRequest = FetchRequest<Note>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Note.timestamp, ascending: true)],
            predicate: NSPredicate(format: "contactId == %@", showPerson.identifier),
            animation: .default)
        person = showPerson
        viewContext = context
        viewModel = model
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                ForEach(notes) { note in
                    if (note.text != nil) {
                        Text(note.text!)
                    }
                }
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
                        addNote(text: newNote)
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
        .navigationTitle("\(person.givenName) \(person.familyName)")
    }
    
    private func addNote(text: String) {
        withAnimation {
            let newNote = Note(context: viewContext)
            newNote.timestamp = Date()
            newNote.text = text
            newNote.contactName = "\(person.givenName) \(person.familyName)"
            newNote.contactId = person.identifier
            print(newNote)
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
