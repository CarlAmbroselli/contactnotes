//
//  SettingsView.swift
//  Crew
//
//  Created by dev on 27.03.22.
//

import Foundation
import SwiftUI
import SwiftyDropbox

struct SettingsView: View {
    @ObservedObject var dropboxViewModel: DropboxViewModel
    var dropboxModel = DropboxModel.shared
    
    var body: some View {
        List {
            Section(header: Text("Dropbox Backup")) {
                ZStack {
                    HStack {
                        Text("Dropbox status")
                        Spacer()
                        if (dropboxViewModel.isAuthenticated == true) {
                            Text("Connected").foregroundColor(.green)
                        } else {
                            Text("Not Connected")
                        }
                    }
                    
                    if (dropboxViewModel.showAuthenticateDropbox) {
                        DropboxViewController(isShown: $dropboxViewModel.showAuthenticateDropbox, viewModel: dropboxViewModel)
                    }
                }
                
                if (dropboxViewModel.isAuthenticated == true) {
                    
                    if (dropboxModel.lastDropboxUpdate != nil) {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text("\(dropboxModel.lastDropboxUpdate!.formatted)")
                        }
                    }
                    
                    if (!dropboxViewModel.isUploading) {
                        Button(action: {
                            dropboxViewModel.uploadNotes()
                        }, label: {
                            HStack {
                                Spacer()
                                Text("Sync now")
                                Spacer()
                            }
                        })
                    } else {
                        HStack {
                            Spacer()
                            Text("Syncing notes...")
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        dropboxViewModel.logout()
                    }, label: {
                        HStack {
                            Spacer()
                            Text("Logout from Dropbox")
                            Spacer()
                        }
                    })
                } else if (dropboxViewModel.isAuthenticated == false) {
                    
                    Button(action: {
                        dropboxViewModel.loginButtonPressed()
                    }, label: {
                        HStack {
                            Spacer()
                            Text("Login to Dropbox")
                            Spacer()
                        }
                    })
                }
            }
            
            Section(header: Text("Utilities")) {
                NavigationLink(destination: AllNotesView()) {
                    Text("Show all notes")
                }
                NavigationLink(destination: RemindersView()) {
                    Text("Show all reminders")
                }
            }
        }
        .navigationBarHidden(false)
        .navigationBarTitle("Settings")
        .onAppear() {
            try? dropboxViewModel.updateDropboxState()
        }
        .onDisappear {
            dropboxModel.syncStatus = ""
        }
        .onOpenURL { url in
            DropboxClientsManager.handleRedirectURL(url, completion: { result in
                try? dropboxViewModel.updateDropboxState()
            })
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


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(dropboxViewModel: DropboxViewModel())
    }
}
