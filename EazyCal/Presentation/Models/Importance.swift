//
//  Importance.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

extension ReminderPriority {
    var localizedTitle: String {
        switch self {
        case .none:
            String(localized: "IMPORTANCE_DEFAULT")
        case .low:
            String(localized: "LOW")
        case .medium:
            String(localized: "MID")
        case .high:
            String(localized: "HIGH")
        }
    }

    var symbol: String {
        switch self {
        case .none: "-"
        case .low: "!"
        case .medium: "!!"
        case .high: "!!!"
        }
    }
}
