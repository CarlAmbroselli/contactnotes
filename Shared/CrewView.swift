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
        
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    ForEach(viewModel.people, id: \.identifier) { person in
                        NavigationLink(destination: PersonView(showPerson: person, context: viewContext, model: viewModel)) {
                            ContactView(contact: person)
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
            
            Text(contact.givenName)
            Text(contact.familyName)
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
