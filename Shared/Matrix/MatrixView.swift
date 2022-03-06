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
    
    var body: some View {
        VStack {
            TextField("Username", text: $username).disableAutocorrection(true).textInputAutocapitalization(.never).padding(10).textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password).disableAutocorrection(true).textInputAutocapitalization(.never).padding(10).textFieldStyle(.roundedBorder)
            Button {
                model.login(username: username, password: password)
            } label: {
                Text("Login")
            }
        }
        .padding(10)
    }
}
