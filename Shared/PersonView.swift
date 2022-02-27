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
    @State var noteText: String = ""
    private var contactGroup: ContactGroup {
        viewModel.contactGroupOfPerson(person)
    }
    var person: CNContact
    var viewModel: CrewModel
    @State var editingNote: Note?
    
    private var viewContext: NSManagedObjectContext
    private var fetchRequest: FetchRequest<Note>
    private var dateFormatter: DateFormatter
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
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Spacer()
                VStack(alignment: .leading) {
                    ForEach(notes) { note in
                        ZStack {
                            if (editingNote?.objectID == note.objectID) {
                                Color.gray
                                    .opacity(0.2)
                            }
                            VStack {
                                if (note.timestamp != nil) {
                                    Text(dateFormatter.string(from: note.timestamp!))
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .foregroundColor(.secondary)
                                }
                                if (note.text != nil) {
                                    Text(note.text!)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                        .frame(height: 5)
                                }
                            }.onTapGesture {
                                editingNote = note
                                noteText = note.text ?? ""
                            }
                        }.padding(5)
                    }
                }
                HStack(alignment: .bottom, spacing: 5) {
                    ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                        if noteText.isEmpty {
                            Text("Add note...")
                                .foregroundColor(Color(.label))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        ExpandingTextView(text: $noteText)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(.systemGray5), lineWidth: 1.0)
                    )
                    Button {
                        addNote(text: noteText)
                        self.noteText = ""
                    } label: {
                        Image(systemName: "plus.circle")
                            .padding(9)
                            .foregroundColor(Color(.lightGray))
                            .background(Color(.darkGray))
                    }
                    .cornerRadius(4)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 5))
                }
            }.rotationEffect(Angle(degrees: 180))
        }
        .font(Font.custom("IowanOldStyle-Roman", size: 16))
        .rotationEffect(Angle(degrees: 180))
        .navigationTitle("\(person.givenName) \(person.familyName)")
        .toolbar {
            GroupSelector (selectionAction: { group in
                viewModel.updateGroupForPerson(person: person, group: group)
            }, selectedGroup: contactGroup)
        }
    }
    
    private func addNote(text: String) {
        withAnimation {
            if (editingNote != nil) {
                editingNote!.text = text
            } else {
                let newNote = Note(context: viewContext)
                newNote.timestamp = Date()
                newNote.text = text
                newNote.contactName = "\(person.givenName) \(person.familyName)"
                newNote.contactId = person.identifier
            }
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            editingNote = nil
        }
    }
}

