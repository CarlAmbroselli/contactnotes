//
//  LastInteractionView.swift
//  Crew (iOS)
//
//  Created by dev on 06.03.22.
//

import SwiftUI
import Contacts
import MatrixSDK

struct LastInteractionView: View {
    let person: CNContact
    @ObservedObject var model = LastInteractionModel()
    
    var body: some View {
        VStack {
            Text(model.lastMessage)
        }
        .task {
            model.initSink(person: self.person)
        }
    }
}
