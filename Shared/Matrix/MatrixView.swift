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
        
        TextField("Username", text: $username)
        TextField("Password", text: $password)
        Button {
            model.login(username: username, password: password)
        } label: {
            Text("Login")
        }

    }
}
