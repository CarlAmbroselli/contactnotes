//
//  GroupSelector.swift
//  Crew (iOS)
//
//  Created by dev on 27.02.22.
//

import SwiftUI

struct GroupSelector: View {
    let selectionAction: (_: ContactGroup) -> Void
    @State var selectedGroup = ContactGroup.ALL_CONTACTS
    
    var body: some View {
        Menu(selectedGroup.rawValue) {
            ForEach(ContactGroup.allCases, id: \.self, content: { group in
                Button(group.rawValue, action: {
                    selectedGroup = group
                    selectionAction(group)
                })
            })
        }
    }
}
