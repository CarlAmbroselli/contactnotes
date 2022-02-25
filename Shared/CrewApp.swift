//
//  CrewApp.swift
//  Shared
//
//  Created by dev on 25.02.22.
//

import SwiftUI

@main
struct CrewApp: App {
//    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CrewView(viewModel: CrewModel())
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
