//
//  TimerViewModel.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Combine
import Foundation
import Observation

struct WorkoutSettingsSnapshot: Equatable {
    var prepareSeconds: Int
    var workSeconds: Int
    var restSeconds: Int
    var cycleRestSeconds: Int
    var set: Int
    var cycle: Int
}

@Observable
final class TimerViewModel {
    var phase = Phase.begin
    
    /// Phase before user tapped Pause (restored on resume).
    private var phaseBeforePause: Phase = .prepare
    
    private var timerCancellable: AnyCancellable?
    
    /// After counting down to 0 we show `00:00` for one tick, then advance (`tick()` runs once per second).
    private var pendingPhaseAdvance = false
    
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
    var isShowFavoriteTimer = false
    
    /// Saved favorites (newest first).
    var workoutHistory: [WorkoutHistoryEntry] = []
    
    init() {
        loadConfigurationFromStorage()
        loadWorkoutHistory()
        syncIdleUIWithConfiguration()
    }
    
    private func loadWorkoutHistory() {
        workoutHistory = WorkoutHistoryService.shared.load()
    }
    
    /// Appends a history item from the current plan, then caller should call `resetTimer()`.
    func addWorkoutToHistory(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let plan = AppData(
            prepareSeconds: prepareSeconds,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            cycleRestSeconds: cycleRestSeconds,
            setsPerCycle: set,
            cycles: cycle
        )
        let entry = WorkoutHistoryEntry(
            id: UUID(),
            savedAt: Date(),
            name: trimmed,
            plan: plan
        )
        workoutHistory.insert(entry, at: 0)
        WorkoutHistoryService.shared.save(items: workoutHistory)
    }
    
    func deleteWorkoutHistory(at offsets: IndexSet) {
        workoutHistory.remove(atOffsets: offsets)
        WorkoutHistoryService.shared.save(items: workoutHistory)
    }
    
    /// Loads saved workout plan from `StorageService` (first launch uses defaults inside `AppData`).
    private func loadConfigurationFromStorage() {
        let data = StorageService.shared.read()
        prepareSeconds = data.prepareSeconds
        workSeconds = data.workSeconds
        restSeconds = data.restSeconds
        cycleRestSeconds = data.cycleRestSeconds
        set = data.setsPerCycle
        cycle = data.cycles
    }
    
    /// Writes the current plan to `UserDefaults` (same storage as `AppStorage("storage")`).
    func persistConfigurationToStorage() {
        let data = AppData(
            prepareSeconds: prepareSeconds,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            cycleRestSeconds: cycleRestSeconds,
            setsPerCycle: set,
            cycles: cycle
        )
        StorageService.shared.save(storage: data)
    }
    
    private func syncIdleUIWithConfiguration() {
        currentPhaseRemainingSeconds = prepareSeconds
        remainingTotalSeconds = totalWorkoutDurationSeconds
        currentSetIndex = 0
        currentCycleIndex = 0
    }
    
    func showSettings() {
        isShowSettings.toggle()
    }
    
    func showFavoriteTimer() {
        isShowFavoriteTimer.toggle()
    }
    
    func makeSettingsSnapshot() -> WorkoutSettingsSnapshot {
        WorkoutSettingsSnapshot(
            prepareSeconds: prepareSeconds,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            cycleRestSeconds: cycleRestSeconds,
            set: set,
            cycle: cycle
        )
    }
    
    func restoreSettings(_ snapshot: WorkoutSettingsSnapshot) {
        prepareSeconds = snapshot.prepareSeconds
        workSeconds = snapshot.workSeconds
        restSeconds = snapshot.restSeconds
        cycleRestSeconds = snapshot.cycleRestSeconds
        set = snapshot.set
        cycle = snapshot.cycle
    }
    
    func settingsDiffer(from snapshot: WorkoutSettingsSnapshot) -> Bool {
        prepareSeconds != snapshot.prepareSeconds
            || workSeconds != snapshot.workSeconds
            || restSeconds != snapshot.restSeconds
            || cycleRestSeconds != snapshot.cycleRestSeconds
            || set != snapshot.set
            || cycle != snapshot.cycle
    }
    
    /// Call after changing durations or set/cycle counts so totals and idle display stay in sync.
    func applyConfigurationFromSettings() {
        guard phase == .begin else { return }
        remainingTotalSeconds = totalWorkoutDurationSeconds
        currentPhaseRemainingSeconds = prepareSeconds
        currentSetIndex = 0
        currentCycleIndex = 0
    }
    
    /// Applies a saved plan as the current timer configuration. Only succeeds on the Ready screen (`phase == .begin`).
    @discardableResult
    func applyPlanFromHistory(_ plan: AppData) -> Bool {
        guard phase == .begin else { return false }
        prepareSeconds = plan.prepareSeconds
        workSeconds = plan.workSeconds
        restSeconds = plan.restSeconds
        cycleRestSeconds = plan.cycleRestSeconds
        set = plan.setsPerCycle
        cycle = plan.cycles
        remainingTotalSeconds = totalWorkoutDurationSeconds
        currentPhaseRemainingSeconds = prepareSeconds
        currentSetIndex = 0
        currentCycleIndex = 0
        persistConfigurationToStorage()
        return true
    }
    
    deinit {
        timerCancellable?.cancel()
    }
    
    /// Starts the workout from the «Ready» screen.
    func startTimer() {
        guard phase == .begin else { return }
        pendingPhaseAdvance = false
        remainingTotalSeconds = totalWorkoutDurationSeconds
        currentCycleIndex = 1
        currentSetIndex = 0
        phase = .prepare
        currentPhaseRemainingSeconds = prepareSeconds
        advanceThroughZeroDurations()
        guard phase != .begin else { return }
        subscribeToTicks()
    }
    
    /// Continues after Pause.
    func resumeTimer() {
        guard phase == .pause else { return }
        phase = phaseBeforePause
        subscribeToTicks()
    }
    
    func pauseTimer() {
        guard phase != .begin, phase != .pause else { return }
        phaseBeforePause = phase
        phase = .pause
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    func resetTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        pendingPhaseAdvance = false
        phase = .begin
        currentSetIndex = 0
        currentCycleIndex = 0
        currentPhaseRemainingSeconds = prepareSeconds
        remainingTotalSeconds = totalWorkoutDurationSeconds
    }
    
    private func subscribeToTicks() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        guard phase != .pause, phase != .begin else { return }
        
        if pendingPhaseAdvance {
            pendingPhaseAdvance = false
            remainingTotalSeconds = max(0, remainingTotalSeconds - 1)
            advancePhase()
            advanceThroughZeroDurations()
            return
        }
        
        guard currentPhaseRemainingSeconds > 0 else { return }
        
        currentPhaseRemainingSeconds -= 1
        remainingTotalSeconds = max(0, remainingTotalSeconds - 1)
        
        if currentPhaseRemainingSeconds == 0 {
            pendingPhaseAdvance = true
        }
    }
    
    /// Skips phases with 0 s duration (e.g. no prepare / no rest).
    private func advanceThroughZeroDurations() {
        while phase != .begin && phase != .pause && currentPhaseRemainingSeconds == 0 {
            advancePhase()
            if phase == .begin { return }
        }
    }
    
    private func advancePhase() {
        switch phase {
        case .prepare:
            phase = .work
            currentSetIndex = 1
            currentPhaseRemainingSeconds = workSeconds
            
        case .work:
            if currentSetIndex < set {
                phase = .rest
                currentPhaseRemainingSeconds = restSeconds
            } else if currentCycleIndex < cycle {
                phase = .cycleRest
                currentPhaseRemainingSeconds = cycleRestSeconds
            } else {
                finishWorkout()
            }
            
        case .rest:
            currentSetIndex += 1
            phase = .work
            currentPhaseRemainingSeconds = workSeconds
            
        case .cycleRest:
            currentCycleIndex += 1
            phase = .work
            currentSetIndex = 1
            currentPhaseRemainingSeconds = workSeconds
            
        case .begin, .pause:
            break
        }
    }
    
    private func finishWorkout() {
        timerCancellable?.cancel()
        timerCancellable = nil
        pendingPhaseAdvance = false
        phase = .begin
        currentSetIndex = 0
        currentCycleIndex = 0
        currentPhaseRemainingSeconds = prepareSeconds
        remainingTotalSeconds = totalWorkoutDurationSeconds
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
    
    /// Full workout length: phase durations + one second per phase transition (full second on `00:00` before switching).
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
        let phaseSum = prepare + c * workRestInCycle + max(0, c - 1) * cycleRest
        /// One tick per transition: prepare→work, work↔rest, last work→cycleRest/done, cycleRest→work.
        let transitionCount = 2 * s * c
        return phaseSum + transitionCount
    }
}
