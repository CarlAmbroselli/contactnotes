//
//  DropboxViewModel.swift
//  Crew (iOS)
//
//  Created by dev on 27.02.22.
//

import SwiftUI
import SwiftyDropbox

/// A ViewModel that publishes data retrieved from DropboxModel. Each View will have its own ViewModel.
class DropboxViewModel: ObservableObject {
    
    @Published var showAuthenticateDropbox = false
    @Published var authenticationStatus = "Loading..."
    @Published var isAuthenticated: Bool?
    @Published var isUploading = false
    @Published var syncStatus = ""
    private var authenticationTriggered = false
    
    private let dropboxModel = DropboxModel.shared
    
    func updateDropboxState() throws {
        if (DropboxClientsManager.authorizedClient == nil) {
            self.isAuthenticated = false
            authenticationStatus = "Not authenticated"
        } else {
            dropboxModel.updateDropboxState() { isAuthenticated, authenticationStatus in
                self.isAuthenticated = isAuthenticated
                self.authenticationStatus = authenticationStatus
            }
        }
    }
    
    func authenticate(controller: UIViewController?) {
        if (!authenticationTriggered) {
            authenticationTriggered = true
            let scopeRequest = ScopeRequest(scopeType: .user, scopes: [
                "account_info.read",
                "files.content.read",
                "files.content.write",
                "files.metadata.read"
            ], includeGrantedScopes: false)
            DropboxClientsManager.authorizeFromControllerV2(
                UIApplication.shared,
                controller: controller,
                loadingStatusDelegate: nil,
                openURL: { (url: URL) -> Void in
                    if (url.path.hasSuffix("/cancel")) {
                        self.authenticationTriggered = false
                        self.showAuthenticateDropbox = false
                    }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                },
                scopeRequest: scopeRequest
            )
        }
    }
    
    func loginButtonPressed() {
        authenticationTriggered = false
        showAuthenticateDropbox = true
    }
    
    func logout() {
        DropboxClientsManager.unlinkClients()
        self.authenticationTriggered = false
        self.showAuthenticateDropbox = false
        self.authenticationStatus = "Logged out"
        self.isAuthenticated = false
    }
    
    func uploadNotes() {
        self.syncStatus = "Loading..."
        self.isUploading = true
        dropboxModel.uploadNotes { result in
            self.syncStatus = result
            self.isUploading = false
            
        }
    }
}
