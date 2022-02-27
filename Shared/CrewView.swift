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
    @State private var openDropboxView = false
    
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
                    
                    GroupSelector(selectionAction: { group in
                        viewModel.filteredGroup = group
                    }, selectedGroup: viewModel.filteredGroup)
                    
                    Menu(content: {
                        Button("Dropbox") {
                            self.openDropboxView = true
                        }
                    }, label: {
                        Image(systemName: "gear")
                    })
                }.padding([.leading, .top, .trailing], 10)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
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
            .background(
                NavigationLink(destination: DropboxView(viewModel: CrewModel.dropboxViewModel), isActive: $openDropboxView) {
                    EmptyView()
                })
        }
        .task {
            await viewModel.loadPeople()
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
