//
//  Phase.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Foundation

enum Phase {
    case begin
    case prepare
    case work
    /// Time to move or get ready before rest (after work, when another work round follows).
    case workToRestTransition
    case rest
    case pause
    case cycleRest
    case cooldown
    
    var title: String {
        switch self {
        case .begin: "Ready?"
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
