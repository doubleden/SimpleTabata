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
    case rest
    case pause
    case cycleRest
    
    var title: String {
        switch self {
        case .begin: "Ready?"
        case .prepare: "Prepare"
        case .work: "Work"
        case .rest: "Rest"
        case .pause: "Pause"
        case .cycleRest: "Cycle Rest"
        }
    }
}
