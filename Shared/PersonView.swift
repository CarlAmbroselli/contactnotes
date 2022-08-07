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
    @ObservedObject var viewModel: PersonModel
    
    var crewModel: CrewModel
    
    @ObservedObject var matrixModel: MatrixModel
    @State var noteText: String = ""
    
    private var contactGroup: ContactGroup {
        ContactUtils.contactGroupOfPerson(viewModel.person)
    }
    @State var reminderNote: Note?
    @State var matrixRoomLink: String
    @State private var showReminderPopover = false
    @State private var userWantsToChangeMatrixRoom: Bool = false

    private var fetchRequest: FetchRequest<Note>
    private var notes: FetchedResults<Note> {
        fetchRequest.wrappedValue
    }
    
    init(person: CNContact, context: NSManagedObjectContext, model: CrewModel) {
        fetchRequest = FetchRequest<Note>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Note.timestamp, ascending: false)],
            predicate: NSPredicate(format: "contactId == %@", person.identifier),
            animation: .default)
        crewModel = model
        viewModel = PersonModel(person: person, context: context)
        _matrixRoomLink = State(initialValue: person.matrixRoom ?? "")
        matrixModel = MatrixModel.shared
    }
    
    var body: some View {
        VStack {
            if (matrixModel.isAuthenticated) {
                if (viewModel.person.matrixRoom != nil && !userWantsToChangeMatrixRoom) {
                    LastMessageInfo(userWantsToChangeMatrixRoom: $userWantsToChangeMatrixRoom, roomId: matrixRoomLink)
                        .onAppear {
                            MatrixModel.shared.loadLatestState(silent: true)
                        }
                } else {
                    MatrixRoomInput(
                        matrixRoomLink: $matrixRoomLink,
                        userWantsToChangeMatrixRoom: $userWantsToChangeMatrixRoom,
                        person: viewModel.person,
                        updateMatrixRoomForPerson: crewModel.updateMatrixRoomForPerson
                    )
                }
            }
            List {
                ForEach(notes) { note in
                    ZStack {
                        if (viewModel.editingNote?.objectID == note.objectID) {
                            Color.gray
                                .opacity(0.2)
                        }
                        NoteRow(text: note.text, timestamp: note.timestamp, nextReminder: viewModel.getNextReminder(note: note))
                            .padding(5)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.editingNote = note
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
                        Button(role: .destructive, action: { viewModel.deleteNote(note: note) } ) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    if (showReminderPopover && reminderNote?.objectID == note.objectID) {
                        ReminderConfiguration(note: note, scheduleNotification: crewModel.scheduleNotification, showReminderPopover: $showReminderPopover)
                    }
                }
            }
            .listStyle(PlainListStyle())
            NoteTextBox(noteText: $noteText, personModel: viewModel, isEditingNote: viewModel.editingNote == nil)
                .navigationTitle(viewModel.person.fullName)
                .padding(5)
            .toolbar {
                GroupSelector (selectionAction: { group in
                    crewModel.updateGroupForPerson(person: viewModel.person, group: group)
                }, selectedGroup: contactGroup)
            }
        }
        .font(Font.custom("IowanOldStyle-Roman", size: 16))
    }
}

struct NoteTextBox: View {
    @Binding var noteText: String
    let personModel: PersonModel
    let isEditingNote: Bool
    
    var body: some View {
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
                if (!noteText.isEmpty) {
                    personModel.addNote(text: noteText)
                    self.noteText = ""
                }
            } label: {
                Image(systemName: isEditingNote ? "plus.circle" : "checkmark.circle.fill")
                    .padding(10)
                    .foregroundColor(Color(.white))
                    .background(Color(.darkGray))
            }
            .cornerRadius(4)
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

struct LastMessageInfo : View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var userWantsToChangeMatrixRoom: Bool
    let roomId: String
    @FetchRequest private var roomDetails: FetchedResults<MatrixRoom>
    
    var buttonText: String {
        if (roomDetails.isEmpty) {
            return "No message details loaded yet."
        } else {
            if (roomDetails.first!.lastMessageTimestamp != nil) {
                return "Last message: \(roomDetails.first!.lastMessageTimestamp!.relativeTimeDescriptionSinceNow)"
            } else {
                return "No messages in this chat found."
            }
        }
    }
    
    init(userWantsToChangeMatrixRoom: Binding<Bool>, roomId: String) {
        self._userWantsToChangeMatrixRoom = userWantsToChangeMatrixRoom
        self._roomDetails = FetchRequest(
            entity: MatrixRoom.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \MatrixRoom.lastMessageTimestamp, ascending: false)],
            predicate: NSPredicate(format: "roomId == %@", roomId),
            animation: .default)
        self.roomId = roomId
    }
    
    var body: some View {
        HStack {
            Spacer()
            Link(destination: URL(string: "https://mobile.element.io/#/room/\(self.roomId)")!) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .opacity(0.0)
            }
            Button(buttonText) {
                userWantsToChangeMatrixRoom = true
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            .padding(10)
            .background(Color.blue.opacity(colorScheme == .dark ? 0.9 : 0.1))
            .cornerRadius(4)
            .opacity(0.9)
            Link(destination: URL(string: "https://mobile.element.io/#/room/\(self.roomId)")!) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            Spacer()
        }.padding(.top, 10)
    }
}

struct MatrixRoomInput: View {
    @Binding var matrixRoomLink: String
    @Binding var userWantsToChangeMatrixRoom: Bool
    
    let person: CNContact
    let updateMatrixRoomForPerson: (CNContact, String) -> Void
    
    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(
                "Enter matrix room: !xxxx:matrix.org",
                text: $matrixRoomLink
            )
                .disableAutocorrection(true)
                .padding(.trailing, 45)
                .padding(.leading, 10)
            if (!matrixRoomLink.isEmpty) {
                Button(action: {
                    withAnimation {
                        self.userWantsToChangeMatrixRoom = false
                        updateMatrixRoomForPerson(person, self.matrixRoomLink)
                    }
                }) {
                    Image(systemName: "arrow.up.and.person.rectangle.portrait")
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 15)
            }
        }
    }
}

struct NoteRow: View {
    let text: String?
    let timestamp: Date?
    let nextReminder: Reminder?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                if (nextReminder != nil) {
                    Image(systemName: "alarm.fill")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                        .padding(.trailing, -5)
                    Text("\(nextReminder!.timestamp!.formatted) |")
                        .foregroundColor(.secondary)
                        .padding(.trailing, -5)
                }
                if (timestamp != nil) {
                    Text(timestamp!.formatted)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            if (text != nil) {
                Text(text!)
                    .padding(.leading, 6)
                    .opacity(colorScheme == .dark ? 0.85 : 0.75)
                    .lineSpacing(1.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

