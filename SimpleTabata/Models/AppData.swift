//
//  AppData.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Foundation

struct AppData: Codable, Equatable {
    var prepareSeconds: Int
    var workSeconds: Int
    var restSeconds: Int
    var cycleRestSeconds: Int
    var setsPerCycle: Int
    var cycles: Int
    /// Optional move / setup time between work and the following rest (per work→rest pair within a cycle).
    var workToRestTransitionSeconds: Int
    /// Custom colors for the main timer digits per phase.
    var phaseColors: TimerPhaseColors
    
    enum CodingKeys: String, CodingKey {
        case prepareSeconds
        case workSeconds
        case restSeconds
        case cycleRestSeconds
        case setsPerCycle
        case cycles
        case workToRestTransitionSeconds
        case phaseColors
    }
    
    init(
        prepareSeconds: Int = 10,
        workSeconds: Int = 20,
        restSeconds: Int = 10,
        cycleRestSeconds: Int = 60,
        setsPerCycle: Int = 8,
        cycles: Int = 1,
        workToRestTransitionSeconds: Int = 0,
        phaseColors: TimerPhaseColors = .appDefault
    ) {
        self.prepareSeconds = prepareSeconds
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.cycleRestSeconds = cycleRestSeconds
        self.setsPerCycle = setsPerCycle
        self.cycles = cycles
        self.workToRestTransitionSeconds = workToRestTransitionSeconds
        self.phaseColors = phaseColors
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        prepareSeconds = try c.decodeIfPresent(Int.self, forKey: .prepareSeconds) ?? 10
        workSeconds = try c.decodeIfPresent(Int.self, forKey: .workSeconds) ?? 20
        restSeconds = try c.decodeIfPresent(Int.self, forKey: .restSeconds) ?? 10
        cycleRestSeconds = try c.decodeIfPresent(Int.self, forKey: .cycleRestSeconds) ?? 60
        setsPerCycle = try c.decodeIfPresent(Int.self, forKey: .setsPerCycle) ?? 8
        cycles = try c.decodeIfPresent(Int.self, forKey: .cycles) ?? 1
        workToRestTransitionSeconds = try c.decodeIfPresent(Int.self, forKey: .workToRestTransitionSeconds) ?? 0
        phaseColors = try c.decodeIfPresent(TimerPhaseColors.self, forKey: .phaseColors) ?? .appDefault
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(prepareSeconds, forKey: .prepareSeconds)
        try c.encode(workSeconds, forKey: .workSeconds)
        try c.encode(restSeconds, forKey: .restSeconds)
        try c.encode(cycleRestSeconds, forKey: .cycleRestSeconds)
        try c.encode(setsPerCycle, forKey: .setsPerCycle)
        try c.encode(cycles, forKey: .cycles)
        try c.encode(workToRestTransitionSeconds, forKey: .workToRestTransitionSeconds)
        try c.encode(phaseColors, forKey: .phaseColors)
    }
}
