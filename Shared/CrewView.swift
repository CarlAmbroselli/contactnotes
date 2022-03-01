//
//  CrewList.swift
//  Crew
//
//  Created by dev on 25.02.22.
//

import SwiftUI
import Contacts
import UserNotifications
import CoreData

struct CrewView: View {
    @ObservedObject var viewModel: CrewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var openDropboxView = false
    @State private var openAllNotesView = false
    @State private var openRemindersView = false
    
    init(viewModel: CrewModel) {
        self.viewModel = viewModel
        UIScrollView.appearance().keyboardDismissMode = .onDrag
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    ContactSearch(searchText: $searchText)
                    
                    GroupSelector(selectionAction: { group in
                        viewModel.filteredGroup = group
                    }, selectedGroup: viewModel.filteredGroup)
                    
                    Menu(content: {
                        Button("All Notes") {
                            self.openAllNotesView = true
                        }
                        Button("Reminders") {
                            self.openRemindersView = true
                        }
                        Button("Dropbox") {
                            self.openDropboxView = true
                        }
                    }, label: {
                        Image(systemName: "gear")
                    })
                        .padding([.leading, .trailing],  10)
                }.padding([.leading, .top, .trailing], 10)
                
                ContactList(people: viewModel.people, searchText: self.searchText, viewModel: viewModel, viewContext: viewContext)
                
            }
            .navigationBarHidden(true)
            .navigationBarTitle("")
            .background(
                MenuNavigationView(viewModel: viewModel, openDropboxView: $openDropboxView, openAllNotesView: $openAllNotesView, openRemindersView: $openRemindersView)
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
            await viewModel.loadPeople()
        }
    }
}

struct MenuNavigationView: View {
    var viewModel: CrewModel
    @Binding var openDropboxView: Bool
    @Binding var openAllNotesView: Bool
    @Binding var openRemindersView: Bool
    var body: some View {
        Group {
            NavigationLink(destination: DropboxView(viewModel: CrewModel.dropboxViewModel), isActive: $openDropboxView) {
                EmptyView()
            }
            NavigationLink(destination: AllNotesView(), isActive: $openAllNotesView) {
                EmptyView()
            }
            NavigationLink(destination: RemindersView(viewModel: viewModel), isActive: $openRemindersView) {
                EmptyView()
            }
        }
    }
}

struct ContactView: View {
    var contact: CNContact
    var body: some View {
        VStack {
            ZStack {
                if (contact.imageData != nil) {
                    Image(uiImage: UIImage(data: contact.imageData!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 95, height: 95, alignment: .center)
                } else {
                    Text("\(contact.givenName) \(contact.familyName)".initials)
                        .foregroundColor(.white)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.semibold)
                }
            }
            .frame(width: 95, height: 95, alignment: .center)
            .background(Color(.lightGray))
            .clipShape(Circle())
            
            Text("\(contact.givenName) \(contact.familyName)").lineLimit(1)
        }
        .frame(width: 110, height: 130, alignment: .center)
        .font(.system(size: 11))
        .foregroundColor(.primary)
    }
}

struct ContactList: View {
    var people: [CNContact]
    var searchText: String
    var viewModel: CrewModel
    var viewContext: NSManagedObjectContext
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
                ForEach(people.filter({ contact in
                    if (searchText.isEmpty) {
                        return true
                    }
                    return "\(contact.givenName) \(contact.familyName)".contains(searchText)
                }), id: \.identifier) { person in
                    NavigationLink(destination: PersonView(showPerson: person, context: viewContext , model: viewModel)) {
                        ContactView(contact: person)
                    }
                }
            }
        }
    }
}

struct ContactSearch: View {
    @Binding var searchText: String
    
    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(
                "Search",
                text: $searchText
            )
                .padding(.trailing, 25)
            if (!self.searchText.isEmpty) {
                Button(action: {
                    self.searchText = ""
                }) {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

extension String {
    var initials: String {
        return self.components(separatedBy: " ")
            .reduce("") {
                ($0.isEmpty ? "" : "\($0.first?.uppercased() ?? "")") +
                ($1.isEmpty ? "" : "\($1.first?.uppercased() ?? "")")
            }
    }
}

struct CrewList_Previews: PreviewProvider {
    static var previews: some View {
        CrewView(viewModel: CrewModel())
    }
}
