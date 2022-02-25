//
//  CrewModel.swift
//  Crew
//
//  Created by dev on 25.02.22.
//

import Foundation
import SwiftyContacts

class CrewModel: ObservableObject {
    @Published var people = ["one", "two", "three"]
    
    func loadPeople() async {
        let access = try? await requestAccess()
    }
}
