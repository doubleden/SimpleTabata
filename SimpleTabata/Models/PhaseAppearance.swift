//
//  PhaseAppearance.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 22/3/26.
//

import SwiftUI
import UIKit

/// sRGB components in 0…1 for persistence.
struct PhaseColorComponents: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = min(1, max(0, red))
        self.green = min(1, max(0, green))
        self.blue = min(1, max(0, blue))
        self.alpha = min(1, max(0, alpha))
    }
    
    init(_ color: Color) {
        let ui = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            self.red = 1
            self.green = 1
            self.blue = 1
            self.alpha = 1
            return
        }
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

/// Colors for each timer phase (main countdown).
struct TimerPhaseColors: Codable, Equatable {
    var begin: PhaseColorComponents
    var prepare: PhaseColorComponents
    var work: PhaseColorComponents
    var workToRestTransition: PhaseColorComponents
    var rest: PhaseColorComponents
    var pause: PhaseColorComponents
    var cycleRest: PhaseColorComponents
    var cooldown: PhaseColorComponents
    
    static let appDefault = TimerPhaseColors(
        begin: PhaseColorComponents(red: 1, green: 1, blue: 1),
        prepare: PhaseColorComponents(red: 1, green: 0.95, blue: 0),
        work: PhaseColorComponents(red: 0.2, green: 0.78, blue: 0.35),
        workToRestTransition: PhaseColorComponents(red: 1, green: 1, blue: 1),
        rest: PhaseColorComponents(red: 0.25, green: 0.52, blue: 1),
        pause: PhaseColorComponents(red: 1, green: 0.58, blue: 0),
        cycleRest: PhaseColorComponents(red: 0.35, green: 0.88, blue: 0.95),
        cooldown: PhaseColorComponents(red: 0.78, green: 0.49, blue: 1)
    )
}

/// Keys for editing phase colors in settings.
enum TimerPhaseColorKey: String, CaseIterable, Identifiable, Hashable {
    case prepare
    case work
    case workToRestTransition
    case rest
    case pause
    case cycleRest
    case cooldown
    
    var id: String { rawValue }
    
    var settingsTitle: String {
        switch self {
        case .prepare: "Prepare"
        case .work: "Work"
        case .workToRestTransition: "Transition"
        case .rest: "Rest"
        case .pause: "Pause"
        case .cycleRest: "Cycle Rest"
        case .cooldown: "Cooldown"
        }
    }
}
