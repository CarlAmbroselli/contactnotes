//
//  PersonModel.swift
//  Crew
//
//  Created by dev on 27.03.22.
//

import Foundation
import Contacts
import CoreData

public class PersonModel: ObservableObject {
    let person: CNContact
    @Published var editingNote: Note?
    @Published var noteTextInputValue = ""
    
    private var viewContext: NSManagedObjectContext
    
    init(person: CNContact, context: NSManagedObjectContext) {
        self.person = person
        self.viewContext = context
    }
    
    func getNextReminder(note: Note) -> Reminder? {
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
    
    func deleteNote(note: Note) {
        viewContext.delete(note)
        self.editingNote = nil
        self.noteTextInputValue = ""
        try? viewContext.save()
    }
    
    func addNote(text: String) {
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
