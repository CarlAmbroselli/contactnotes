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
    @State var longPressNote: Note?
    @State private var showReminderPopover = false
    
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
        Group {
            List {
//                LastInteractionView(person: person)
//                    .listRowSeparator(.hidden)
//                    .listRowInsets(EdgeInsets())
                ForEach(notes) { note in
                    ZStack {
                        if (editingNote?.objectID == note.objectID) {
                            Color.gray
                                .opacity(0.2)
                        }
                        if (longPressNote?.objectID == note.objectID) {
                            Color.gray
                                .opacity(0.2)
                                .cornerRadius(5)
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
                            }
                        }
                        .padding(5)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading) {
                        Button {
                            editingNote = note
                            noteText = note.text ?? ""
                            longPressNote = nil
                        } label: {
                            Label("Edit", systemImage: "pencil.circle")
                        }.tint(.blue)
                        Button {
                            self.showReminderPopover = true
                            self.longPressNote = nil
                            UIImpactFeedbackGenerator.init(style: .heavy).impactOccurred()
                        } label: {
                            Label("Remind", systemImage: "alarm")
                        }.tint(.yellow)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                      Button(role: .destructive, action: { deleteNote(note: note) } ) {
                        Label("Delete", systemImage: "trash")
                      }
                    }
                    .popover(isPresented: $showReminderPopover) {
                        ReminderPopover(note: note, scheduleNotification: viewModel.scheduleNotification, showReminderPopover: $showReminderPopover)
                    }
                }
            }
                .listStyle(PlainListStyle())
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
                    Image(systemName: editingNote == nil ? "plus.circle" : "checkmark.circle.fill")
                        .padding(10)
                        .foregroundColor(Color(.white))
                        .background(Color(.darkGray))
                }
                .cornerRadius(4)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
            }
            .navigationTitle(person.fullName)
            .toolbar {
                GroupSelector (selectionAction: { group in
                    viewModel.updateGroupForPerson(person: person, group: group)
                }, selectedGroup: contactGroup)
            }
        }
        .font(Font.custom("IowanOldStyle-Roman", size: 16))
    }
    
    private func deleteNote(note: Note) {
        withAnimation {
            viewContext.delete(note)
            self.editingNote = nil
            noteText = ""
            try? viewContext.save()
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

struct ReminderPopover: View {
    let note: Note
    let scheduleNotification: (Note, TimeInterval) -> Void
    @Binding var showReminderPopover: Bool
    @State var reminderDate = Date()
    
    var body: some View {
        VStack {
            Group{
                Text(note.text!)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding([.bottom], 20)
                Button("Remind in 1 hour") {
                    scheduleNotification(note, 60*60)
                    showReminderPopover = false
                }.padding(10).background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                Spacer().frame(height: 15)
                Button("Remind in 1 day") {
                    scheduleNotification(note, 60*60*24)
                    showReminderPopover = false
                }.padding(10).background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                Spacer().frame(height: 15)
                Button("Remind in 3 days") {
                    scheduleNotification(note, 60*60*24*3)
                    showReminderPopover = false
                }.padding(10).background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            Group {
                Spacer().frame(height: 15)
                Button("Remind in 7 days") {
                    scheduleNotification(note, 60*60*24*7)
                    showReminderPopover = false
                }.padding(10).background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                Spacer().frame(height: 15)
                Button("Remind in 30 days") {
                    scheduleNotification(note, 60*60*24*30)
                    showReminderPopover = false
                }.padding(10).background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                Spacer().frame(height: 15)
                Button("Remind in 6 months") {
                    scheduleNotification(note, 60*60*24*30*6)
                    showReminderPopover = false
                }.padding(10).background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                Spacer().frame(height: 15)
                
                HStack {
                    DatePicker(
                        "",
                        selection: $reminderDate,
                        displayedComponents: [.date]
                    ).labelsHidden()
                    
                    let days = Calendar.current.dateComponents([.day], from:Calendar.current.startOfDay(for: Date()) , to: Calendar.current.startOfDay(for: reminderDate)).day!
                    if (days > 0) {
                        Button("Remind in \(days) days") {
                            scheduleNotification(note, reminderDate.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate)
                            showReminderPopover = false
                        }
                        .padding([.top, .bottom], 7)
                        .padding([.leading, .trailing], 10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                }
            }
        }.padding(10)
    }
}

