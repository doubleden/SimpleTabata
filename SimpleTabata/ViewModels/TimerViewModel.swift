//
//  TimerViewModel.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Foundation
import Observation

@Observable
final class TimerViewModel {
    var phase = Phase.begin
    
    // MARK: - Configuration (settings)
    
    /// Prepare phase duration (seconds).
    var prepareSeconds: Int = 10
    /// Work duration (seconds).
    var workSeconds: Int = 20
    /// Rest duration (seconds).
    var restSeconds: Int = 10
    /// Pause between cycles (seconds).
    var cycleRestSeconds: Int = 60
    
    /// Sets (rounds) per cycle.
    var set: Int = 8
    /// Number of workout cycles.
    var cycle: Int = 1
    
    // MARK: - Progress (main timer)
    
    /// Remaining time in the current phase (seconds).
    var currentPhaseRemainingSeconds: Int = 0
    
    /// Total workout time remaining (seconds); decreases with the timer.
    var remainingTotalSeconds: Int = 0
    
    /// Current set within the cycle (1…`set`), or 0 before start.
    var currentSetIndex: Int = 0
    /// Current cycle (1…`cycle`), or 0 before start.
    var currentCycleIndex: Int = 0
    
    /// Formatted remaining time for the current phase.
    var currentTime: String {
        Self.formatMMSS(currentPhaseRemainingSeconds)
    }
    
    /// Formatted total workout time remaining.
    var totalTime: String {
        Self.formatMMSS(remainingTotalSeconds)
    }
    
    var totalWorkoutDurationSeconds: Int {
        Self.computeTotalWorkoutSeconds(
            prepare: prepareSeconds,
            work: workSeconds,
            rest: restSeconds,
            cycleRest: cycleRestSeconds,
            sets: set,
            cycles: cycle
        )
    }
    
    var isShowSettings = false
    
    init() {
        currentPhaseRemainingSeconds = prepareSeconds
        remainingTotalSeconds = totalWorkoutDurationSeconds
    }
    
    func showSettings() {
        isShowSettings.toggle()
    }
    
    /// Call after changing durations or set/cycle counts so totals and idle display stay in sync.
    func applyConfigurationFromSettings() {
        guard phase == .begin else { return }
        remainingTotalSeconds = totalWorkoutDurationSeconds
        currentPhaseRemainingSeconds = prepareSeconds
        currentSetIndex = 0
        currentCycleIndex = 0
    }
    
    func startTimer() {
        
    }
    
    func pauseTimer() {
        
    }
    
    func resetTimer() {
        
    }
    
    func formattedTime(_ seconds: Int) -> String {
        Self.formatMMSS(seconds)
    }
    
    static func formatMMSS(_ sec: Int) -> String {
        let s = max(0, sec)
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
    
    /// Full workout length: `prepare` once at the start; each cycle is `sets`×work + rests; `cycleRest` between cycles.
    static func computeTotalWorkoutSeconds(
        prepare: Int,
        work: Int,
        rest: Int,
        cycleRest: Int,
        sets: Int,
        cycles: Int
    ) -> Int {
        let s = max(1, sets)
        let c = max(1, cycles)
        let workRestInCycle = s * work + max(0, s - 1) * rest
        return prepare + c * workRestInCycle + max(0, c - 1) * cycleRest
    }
}
