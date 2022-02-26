//
//  PersonView.swift
//  Crew
//
//  Created by dev on 26.02.22.
//

import SwiftUI
import Contacts

struct PersonView: View {
    var person: CNContact
    var body: some View {
        Text(person.note)
    }
}
