//
//  CrewList.swift
//  Crew
//
//  Created by dev on 25.02.22.
//

import SwiftUI
import Contacts

struct CrewView: View {
    @ObservedObject var viewModel: CrewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var selectedGroup = "All contacts"
    
    init(viewModel: CrewModel) {
        self.viewModel = viewModel
        UIScrollView.appearance().keyboardDismissMode = .onDrag
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
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
                    
                    Menu(selectedGroup) {
                        Button("All contacts", action: {
                            selectedGroup = "All contacts"
                            Task.init(priority: .high, operation: {
                                await refreshList()
                            })
                        })
                        Button("3 weeks", action: {
                            selectedGroup = "3 weeks"
                            Task.init(priority: .high, operation: {
                                await refreshList()
                            })
                        })
                        Button("2 months", action: {
                            selectedGroup = "2 months"
                            Task.init(priority: .high, operation: {
                                await refreshList()
                            })
                        })
                        Button("6 months", action: {
                            selectedGroup = "6 months"
                            Task.init(priority: .high, operation: {
                                await refreshList()
                            })
                        })
                        Button("yearly", action: {
                            selectedGroup = "yearly"
                            Task.init(priority: .high, operation: {
                                await refreshList()
                            })
                        })
                    }
                }.padding([.leading, .top, .trailing], 10)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                        ForEach(viewModel.people.filter({ contact in
                            if (searchText.isEmpty) {
                                return true
                            }
                            return "\(contact.givenName) \(contact.familyName)".contains(searchText)
                        }), id: \.identifier) { person in
                            NavigationLink(destination: PersonView(showPerson: person, context: viewContext, model: viewModel)) {
                                ContactView(contact: person)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationBarTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .task {
            await self.refreshList()
        }
    }
    
    func refreshList() async {
        await viewModel.loadPeople(group: self.selectedGroup == "All contacts" ? nil : self.selectedGroup)
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
                        .frame(width: 70, height: 70, alignment: .center)
                } else {
                    Text("\(contact.givenName) \(contact.familyName)".initials)
                        .foregroundColor(.white)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.semibold)
                }
            }
            .frame(width: 70, height: 70, alignment: .center)
            .background(Color(.lightGray))
            .clipShape(Circle())
            
            Text(contact.givenName).lineLimit(1)
            Text(contact.familyName).lineLimit(1)
        }
        .frame(width: 80, height: 140, alignment: .center)
        .font(.footnote)
        .foregroundColor(.primary)
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
