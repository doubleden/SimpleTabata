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
    
    init(
        prepareSeconds: Int = 10,
        workSeconds: Int = 20,
        restSeconds: Int = 10,
        cycleRestSeconds: Int = 60,
        setsPerCycle: Int = 8,
        cycles: Int = 1
    ) {
        self.prepareSeconds = prepareSeconds
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.cycleRestSeconds = cycleRestSeconds
        self.setsPerCycle = setsPerCycle
        self.cycles = cycles
    }
}
