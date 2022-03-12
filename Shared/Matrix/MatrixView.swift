//
//  MatrixView.swift
//  Crew (iOS)
//
//  Created by dev on 01.03.22.
//

import SwiftUI

struct MatrixView: View {
    var model = MatrixModel.shared
    @State var username: String = ""
    @State var password: String = ""
    @State var homeserver: String = ""
    
    var body: some View {
        VStack {
            if (!model.isAuthenticated) {
                VStack {
                    TextField("Homeserver", text: $homeserver).disableAutocorrection(true).textInputAutocapitalization(.never).padding(10).textFieldStyle(.roundedBorder)
                    TextField("Username", text: $username).disableAutocorrection(true).textInputAutocapitalization(.never).padding(10).textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password).disableAutocorrection(true).textInputAutocapitalization(.never).padding(10).textFieldStyle(.roundedBorder)
                    Button {
                        model.login(username: username, password: password, homeserver: homeserver)
                    } label: {
                        Text("Login")
                    }
                }
                .padding(10)
            } else {
                Text("Already authenticated.")
                
                
                Button {
//                    model.printRoomsWithUser(name: "0xca")
                } label: {
                    Text("Print rooms with 0xca")
                }
                
                
                Button {
                    model.logout()
                } label: {
                    Text("Logout")
                }
            }
            
        }
    }
}
