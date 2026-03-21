//
//  TimeActionButton.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

enum TimeActionButton {
    case start
    case pause
    case reset
    
    var title: String {
        switch self {
        case .start: "Start"
        case .pause: "Pause"
        case .reset: "Reset"
        }
    }
    
    var color: Color {
        switch self {
        case .start: .green
        case .pause: .orange
        case .reset: .gray
        }
    }
}
