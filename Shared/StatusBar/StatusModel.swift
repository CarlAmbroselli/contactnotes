//
//  StatusModel.swift
//  Crew (iOS)
//
//  Created by dev on 13.03.22.
//

import Foundation
import SwiftUI

class StatusModel: ObservableObject {
    
    static let shared = StatusModel()
    @Published var status: String = ""
    @Published var level: StatusLevel = StatusLevel.NONE
    
    func show(message: String, level: StatusLevel = StatusLevel.INFO, permanent: Bool = false) {
        print("[STATUS - \(level)]: \(message)")
        self.status = message
        self.level = level
        if (!permanent) {
            Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { (timer) in
                DispatchQueue.main.async {
                    if (self.status == message) {
                        withAnimation {
                            self.status = ""
                            self.level = .NONE
                        }
                    }
                }
            }
        }
    }
    
    func statusColor() -> Color {
        switch self.level {
        case .INFO:
            return Color.blue
        case .ERROR:
            return Color.red
        case .NONE:
            return Color.gray
        case .SUCCESS:
            return Color.green
        }
    }
}

enum StatusLevel {
    case NONE
    case INFO
    case ERROR
    case SUCCESS
}
