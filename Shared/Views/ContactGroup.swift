//
//  ContactGroups.swift
//  Crew (iOS)
//
//  Created by dev on 27.02.22.
//

import Foundation

enum ContactGroup: String, CaseIterable, Comparable {
    case ALL_CONTACTS = "All contacts"
    case WEEKS_3 = "3 weeks"
    case MONTHS_2 = "2 months"
    case MONTHS_6 =  "6 months"
    case YEARLY = "yearly"
    
    private var sortOrder: Int {
        switch self {
            case .WEEKS_3:
                    return 0
            case .MONTHS_2:
                    return 1
            case .MONTHS_6:
                    return 2
            case .YEARLY:
                    return 3
            case .ALL_CONTACTS:
                    return 4
        }
    }

    static func ==(lhs: ContactGroup, rhs: ContactGroup) -> Bool {
        return lhs.sortOrder == rhs.sortOrder
    }

    static func <(lhs: ContactGroup, rhs: ContactGroup) -> Bool {
       return lhs.sortOrder < rhs.sortOrder
    }
}
