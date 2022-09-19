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
    @FetchRequest(
        entity: UnreadStatus.entity(),
        sortDescriptors: []
    )
    private var unreads: FetchedResults<UnreadStatus>
    
    init(viewModel: CrewModel) {
        self.viewModel = viewModel
        UIScrollView.appearance().keyboardDismissMode = .onDrag
    }
    
    var body: some View {
        VStack {
            StatusModelView()
            NavigationView {
                VStack {
                    TopBarView(searchText: $searchText)
                    ContactList(people: viewModel.people, searchText: self.searchText, viewModel: viewModel, viewContext: viewContext, unreads: unreads)
                }
                .navigationBarHidden(true)
                .navigationBarTitle("")
                .navigationBarTitleDisplayMode(.inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .task {
                await viewModel.loadPeople()
            }
        }
    }
}

struct TopBarView: View {
    @Binding var searchText: String
    var body: some View {
        HStack {
            ContactSearch(searchText: $searchText)
            NavigationLink(destination: SettingsView(dropboxViewModel: DropboxViewModel())) {
                Image(systemName: "gear")
            }
            .padding([.leading, .trailing],  10)
        }.padding([.leading, .top, .trailing], 10)
            .padding(.bottom, 2)
    }
}

struct ContactView: View {
    var contact: CNContact
    let pictureSize = 40.0
    let isUnread: Bool
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
            
            Text(contact.fullName).fontWeight(isUnread ? .semibold : .regular).lineLimit(1)
        }
    }
}

struct ContactList: View {
    var people: [ContactGroup: [CNContact]]
    var searchText: String
    var viewModel: CrewModel
    var viewContext: NSManagedObjectContext
    var unreads: FetchedResults<UnreadStatus>
    
    func filteredPeople(key: ContactGroup) -> [CNContact] {
        return people[key]!.filter({ contact in
            if (searchText.isEmpty) {
                return true
            }
            return contact.fullName.lowercased().contains(searchText.lowercased())
        }).sorted { a, b in
            if (unreads.contains(where: { element in
                element.contactIdentifier == a.identifier
            })) {
                return true
            } else if (unreads.contains(where: { element in
                element.contactIdentifier == b.identifier
            })) {
                return false
            } else if (a.fullName < b.fullName) {
                return true
            } else {
                return false
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(people.keys.sorted(by: <), id: \.self) { key in
                if (filteredPeople(key: key).count > 0) {
                    Section(header: Text(key.rawValue)) {
                        ForEach(filteredPeople(key: key), id: \.identifier) { person in
                            let unreads = unreads.filter({ element in
                                element.contactIdentifier == person.identifier
                            })
                            NavigationLink(destination: PersonView(person: person, context: viewContext , model: viewModel)) {
                                HStack {
                                    if (unreads.count > 0) {
                                        Image(systemName: "circle.fill").foregroundColor(Color.blue.opacity(unreads.count > 0 ? 1.0 : 0.0)).font(Font.system(size:8))
                                            .padding(.leading, 5)
                                            .padding(.trailing, -3)
                                    } else {
                                        Image(systemName: "circle.fill").foregroundColor(Color.red.opacity(0.0)).font(Font.system(size:8))
                                            .padding(.leading, 5)
                                            .padding(.trailing, -3)
                                    }
                                    ContactView(contact: person, isUnread: unreads.count > 0)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation {
                                        if (unreads.count > 0) {
                                            unreads.forEach { unread in
                                                viewContext.delete(unread)
                                                try? viewContext.save()
                                            }
                                        } else {
                                            let newUnread = UnreadStatus(context: viewContext)
                                            newUnread.contactIdentifier = person.identifier
                                            try? viewContext.save()
                                        }
                                    }
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

struct CrewList_Previews: PreviewProvider {
    static var previews: some View {
        CrewView(viewModel: CrewModel())
    }
}
