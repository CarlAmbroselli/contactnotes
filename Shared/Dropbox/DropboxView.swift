//
//  DropboxView.swift
//  Crew (iOS)
//
//  Created by dev on 27.02.22.
//

import Foundation
import SwiftUI
import SwiftyDropbox

struct DropboxView : View {
    @ObservedObject var viewModel: DropboxViewModel
    
    var body : some View {
        VStack {
            AuthenticationStatusView(authenticationStatus: viewModel.authenticationStatus, isAuthenticated: viewModel.isAuthenticated)
            if (viewModel.isAuthenticated == false) {
                ButtonView(action: viewModel.loginButtonPressed, icon: nil, text: "Login to Dropbox")
                    .padding(50)
            }
            if (viewModel.isAuthenticated ?? false) {
                List {
                    ButtonView(action: viewModel.uploadNotes, icon: nil, text: "Upload notes")
                        .padding(50)
                        .listRowSeparator(.hidden)
                    Text(viewModel.syncStatus)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
            } else {
                Spacer()
            }
            if (viewModel.showAuthenticateDropbox) {
                DropboxViewController(isShown: $viewModel.showAuthenticateDropbox, viewModel: viewModel)
            }
            
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: ((viewModel.isAuthenticated ?? false) ? Button(action: viewModel.logout, label: {
            Text("Logout")
        }) : nil))
        .onAppear() {
            try? viewModel.updateDropboxState()
        }
        .onDisappear {
            viewModel.syncStatus = ""
        }
        .onOpenURL { url in
            DropboxClientsManager.handleRedirectURL(url, completion: { result in
                try? viewModel.updateDropboxState()
            })
        }
    }
}

struct AuthenticationStatusView: View {
    
    let authenticationStatus: String
    let isAuthenticated: Bool?
    
    var body: some View {
        Text(authenticationStatus)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background((isAuthenticated ?? false) ? .green : .orange)
    }
}

struct ButtonView: View {
    let action: () -> Void
    let icon: String?
    let text: String
    
    var body: some View {
    
        Button(action: {
            action()
        }) {
            HStack {
                Spacer()
                if (icon != nil ) {
                    Image(systemName: icon!)
                }
                Text(text)
                Spacer()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
        }
    }
}

struct DropboxViewController: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    @Binding var isShown : Bool
    var viewModel: DropboxViewModel

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isShown {
            viewModel.authenticate(controller: uiViewController)
        }
    }

    func makeUIViewController(context _: Self.Context) -> UIViewController {
        return UIViewController()
    }
}
