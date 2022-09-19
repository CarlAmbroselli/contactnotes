//
//  CrewApp.swift
//  Shared
//
//  Created by dev on 25.02.22.
//

import SwiftUI
import SwiftyContacts

@main
struct CrewApp: App {
    let persistenceController = PersistenceController.shared
    @State private var contactPermissions = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
    
    var body: some Scene {
        WindowGroup {
            switch (contactPermissions) {
            case CNAuthorizationStatus.notDetermined,CNAuthorizationStatus.restricted:
                ScrollView {
                    VStack {
                        Spacer()
                        Text("Contact Notes").font(.largeTitle)
                            .padding()
                        Text("CRM for Minimalists").font(.headline)
                            .padding(.bottom, 10)
                        Image("screenshot")
                            .padding()
                        Button(action: {
                            Task {
                                _ = (try? await requestAccess()) ?? false
                                DispatchQueue.main.async {
                                    contactPermissions = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
                                }
                            }
                        }, label: {
                            Text("Allow contact access")
                        })
                        Text("Contact access is required to add notes.")
                            .padding()
                    }
                    Spacer()
                }
            case CNAuthorizationStatus.denied:
                Text("⚠️").font(.largeTitle).padding()
                Text("The contact notes app needs access to your contacts in order to add notes to them.\n\nPlease enable access to contacts in your phone settings.")
                    .padding()
                    .multilineTextAlignment(.center)
                    Button(action: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    }, label: {
                        Text("Change Settings")
                    })
                    .padding()
            default:
                CrewView(viewModel: CrewModel())
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
