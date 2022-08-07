//
//  DateUtils.swift
//  Crew
//
//  Created by dev on 27.03.22.
//

import Foundation

extension Date {
    var formatted: String {
        return self.formatted(date: Date.FormatStyle.DateStyle.numeric, time: Date.FormatStyle.TimeStyle.shortened)
    }
}
