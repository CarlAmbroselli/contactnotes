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
    @State private var openMatrixView = false
    
    init(viewModel: CrewModel) {
        self.viewModel = viewModel
        UIScrollView.appearance().keyboardDismissMode = .onDrag
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    ContactSearch(searchText: $searchText)
                    
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
                        Button("Matrix") {
                            self.openMatrixView = true
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
            .navigationBarTitleDisplayMode(.inline)
            .background(
                MenuNavigationView(
                    viewModel: viewModel,
                    openDropboxView: $openDropboxView,
                    openAllNotesView: $openAllNotesView,
                    openRemindersView: $openRemindersView,
                    openMatrixView: $openMatrixView
                )
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
            MatrixModel.shared.sync()
            await viewModel.loadPeople()
        }
    }
}

struct MenuNavigationView: View {
    var viewModel: CrewModel
    @Binding var openDropboxView: Bool
    @Binding var openAllNotesView: Bool
    @Binding var openRemindersView: Bool
    @Binding var openMatrixView: Bool
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
            NavigationLink(destination: MatrixView(), isActive: $openMatrixView) {
                EmptyView()
            }
        }
    }
}

struct ContactView: View {
    var contact: CNContact
    let pictureSize = 40.0
    var body: some View {
        HStack {
            ZStack {
                if (contact.imageData != nil) {
                    Image(uiImage: UIImage(data: contact.imageData!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: pictureSize, height: pictureSize, alignment: .center)
                } else {
                    Text("\(contact.givenName) \(contact.familyName)".initials)
                        .foregroundColor(.white)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                }
            }
            .frame(width: pictureSize, height: pictureSize, alignment: .center)
            .background(Color(.lightGray))
            .clipShape(Circle())

            Text("\(contact.givenName) \(contact.familyName)").lineLimit(1)
        }
    }
}

struct ContactList: View {
    var people: [ContactGroup: [CNContact]]
    var searchText: String
    var viewModel: CrewModel
    var viewContext: NSManagedObjectContext
    
    func filteredPeople(key: ContactGroup) -> [CNContact] {
        return people[key]!.filter({ contact in
            if (searchText.isEmpty) {
                return true
            }
            return contact.fullName.lowercased().contains(searchText.lowercased())
        })
    }
    
    var body: some View {
        List {
            ForEach(people.keys.sorted(by: <), id: \.self) { key in
                if (filteredPeople(key: key).count > 0) {
                    Section(header: Text(key.rawValue)) {
                        ForEach(filteredPeople(key: key), id: \.identifier) { person in
                            NavigationLink(destination: PersonView(showPerson: person, context: viewContext , model: viewModel)) {
                                HStack{
                                    Image(systemName: "circle.fill").foregroundColor(Color.blue).font(Font.system(size:8))
                                        .padding(.leading, 5)
                                        .padding(.trailing, -3)
                                    ContactView(contact: person)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    print("Awesome!")
                                } label: {
                                    Label("Mark", systemImage: "envelope.badge.fill")
                                }
                                .tint(.blue)
                            }
                            .listRowInsets(EdgeInsets())
                            .padding([.top, .bottom, .trailing], 10)
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
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
                .disableAutocorrection(true)
                .padding(.trailing, 25)
                .padding(.leading, 10)
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
