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
    @Environment(\.colorScheme) private var colorScheme
    @State var noteText: String = ""
    private var contactGroup: ContactGroup {
        viewModel.contactGroupOfPerson(person)
    }
    var person: CNContact
    var viewModel: CrewModel
    @State var reminderNote: Note?
    @State var editingNote: Note?
    @State private var showReminderPopover = false
    @State private var lastMessageDate: Date?
    @State private var matrixRoomTextInput: String = ""
    @State private var userWantsToChangeMatrixRoom: Bool = false
    
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
        VStack {
            if (lastMessageDate != nil && !userWantsToChangeMatrixRoom) {
                HStack {
                    Spacer()
                    Button("Last message: \(lastMessageDate!.relativeTimeDescriptionSinceNow)") {
                        self.userWantsToChangeMatrixRoom = true
                    }
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .padding(10)
                    .background(Color.blue.opacity(colorScheme == .dark ? 0.9 : 0.1))
                    .cornerRadius(4)
                    .opacity(0.9)
                    Spacer()
                }.padding(.top, 10)
            } else if (person.matrixRoom == nil || self.userWantsToChangeMatrixRoom) {
                ZStack(alignment: .trailing) {
                    TextField(
                        "Enter matrix room: !xxxx:matrix.carl-ambroselli.de",
                        text: $matrixRoomTextInput
                    )
                        .disableAutocorrection(true)
                        .padding(.trailing, 45)
                        .padding(.leading, 10)
                    if (!self.matrixRoomTextInput.isEmpty) {
                        Button(action: {
                            self.userWantsToChangeMatrixRoom = false
                            viewModel.updateMatrixRoomForPerson(person: person, room: self.matrixRoomTextInput)
                            self.updateLastMessageForRoom(room: self.matrixRoomTextInput)
                        }) {
                            Image(systemName: "arrow.up.and.person.rectangle.portrait")
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 15)
                    }
                }
            }
            List {
                ForEach(notes) { note in
                    ZStack {
                        if (editingNote?.objectID == note.objectID) {
                            Color.gray
                                .opacity(0.2)
                        }
                        VStack {
                            HStack {
                                let nextReminder = self.getNextReminder(note: note)
                                if (nextReminder != nil) {
                                    Image(systemName: "alarm.fill")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                        .padding(.trailing, -5)
                                    Text("\(dateFormatter.string(from: nextReminder!.timestamp!)) |")
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, -5)
                                }
                                if (note.timestamp != nil) {
                                    Text(dateFormatter.string(from: note.timestamp!))
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, 3)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            if (note.text != nil) {
                                Text(note.text!)
                                    .padding(.leading, 6)
                                    .opacity(colorScheme == .dark ? 0.85 : 0.75)
                                    .lineSpacing(1.5)
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
                        } label: {
                            Image(systemName: "pencil.circle")
                        }.tint(.blue)
                        Button {
                            self.reminderNote = note
                            withAnimation {
                                self.showReminderPopover = true
                            }
                        } label: {
                            Image(systemName: "alarm")
                        }.tint(.yellow)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive, action: { deleteNote(note: note) } ) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    if (showReminderPopover && reminderNote?.objectID == note.objectID) {
                        ReminderConfiguration(note: note, scheduleNotification: viewModel.scheduleNotification, showReminderPopover: $showReminderPopover)
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
        .task {
            guard let room = person.matrixRoom else {
                return
            }
            self.updateLastMessageForRoom(room: room)
        }
    }
    
    private func getNextReminder(note: Note) -> Reminder? {
        if (note.reminders != nil && note.reminders!.count > 0) {
            guard let sortedReminders = ((Array(note.reminders!) as? [Reminder])?.sorted  { a, b in
                if (a.timestamp == nil || b.timestamp == nil) {
                    return false
                }
                return a.timestamp! < b.timestamp!
            }) else {
                return nil
            }
            return sortedReminders.first
        } else {
            return nil
        }
    }
    
    private func updateLastMessageForRoom(room: String, retryCount: Int = 0, retryMax: Int = 30) {
        let lastMessageDate = MatrixModel.shared.lastEventDateForUser(roomId: room)
        if (lastMessageDate == nil) {
            if (retryCount < retryMax) {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (timer) in
                    self.updateLastMessageForRoom(room: room, retryCount: retryCount+1, retryMax: retryMax)
                }
            } else {
                StatusModel.shared.show(message: "Failed to load message summary for \(person.fullName).", level: .ERROR)
            }
        } else {
            self.lastMessageDate = lastMessageDate
        }
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

struct ReminderConfiguration: View {
    let note: Note
    let scheduleNotification: (Note, TimeInterval) -> Void
    @Binding var showReminderPopover: Bool
    @State var reminderDate = Date()
    
    var body: some View {
        HStack {
            Spacer()
            if (showReminderPopover) {
                DatePicker(
                    "",
                    selection: $reminderDate,
                    displayedComponents: [.date]
                )
                    .labelsHidden()
                    .onChange(of: reminderDate) { value in
                        withAnimation {
                            scheduleNotification(note, reminderDate.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate)
                            showReminderPopover = false
                        }
                    }
                Spacer()
            }
            Button  {
                withAnimation {
                    showReminderPopover = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill").foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(5)
        }
    }
}

