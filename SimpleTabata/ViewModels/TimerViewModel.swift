//
//  TimerViewModel.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Combine
import Foundation
import Observation
import SwiftUI

struct WorkoutSettingsSnapshot: Equatable {
    var prepareSeconds: Int
    var workSeconds: Int
    var workToRestTransitionSeconds: Int
    var restSeconds: Int
    var cycleRestSeconds: Int
    var cooldownSeconds: Int
    var set: Int
    var cycle: Int
    var phaseColors: TimerPhaseColors
    var soundVolume: Double
    var duckOtherAudio: Bool
    var midWorkCueEnabled: Bool
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
    var prepareSeconds: Int = 0
    /// Work duration (seconds).
    var workSeconds: Int = 20
    /// Move / setup time between work and the next rest (seconds); skipped when duration is 0.
    var workToRestTransitionSeconds: Int = 0
    /// Rest duration (seconds).
    var restSeconds: Int = 10
    /// Pause between cycles (seconds).
    var cycleRestSeconds: Int = 0
    /// Final cooldown after all cycles are completed (seconds).
    var cooldownSeconds: Int = 0
    
    /// Sets (rounds) per cycle.
    var set: Int = 8
    /// Number of workout cycles.
    var cycle: Int = 1
    
    /// Custom colors for the main countdown (per phase).
    var phaseColors: TimerPhaseColors = .appDefault
    
    /// 0…1 sound volume for beep/start.
    var soundVolume: Double = 1
    
    /// If enabled, other audio will be ducked while app sounds play.
    var duckOtherAudio: Bool = false
    
    /// If enabled, plays a cue sound at the midpoint of each Work interval.
    var midWorkCueEnabled: Bool = false
    
    private var midWorkCueWorkItem: DispatchWorkItem?
    /// Wall-clock time when the mid-work cue should fire for the current Work interval.
    private var midWorkCueWallDeadline: Date?
    /// Set when pausing during Work; used to push `midWorkCueWallDeadline` forward on resume.
    private var midWorkCuePauseBeganAt: Date?
    private var midWorkCueDidFire: Bool = false
    
    // MARK: - Progress (main timer)
    
    /// Remaining time in the current phase (seconds).
    var currentPhaseRemainingSeconds: Int = 0
    
    /// Total workout time remaining (seconds); sum of phase durations left — does not tick down during transition pauses at 00:00.
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
            workToRestTransition: workToRestTransitionSeconds,
            rest: restSeconds,
            cycleRest: cycleRestSeconds,
            cooldown: cooldownSeconds,
            sets: set,
            cycles: cycle
        )
    }
    
    var isShowSettings = false
    var isShowFavoriteTimer = false
    var isShowProfile = false
    
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
            cooldownSeconds: cooldownSeconds,
            setsPerCycle: set,
            cycles: cycle,
            workToRestTransitionSeconds: workToRestTransitionSeconds,
            phaseColors: phaseColors,
            soundVolume: soundVolume,
            duckOtherAudio: duckOtherAudio,
            midWorkCueEnabled: midWorkCueEnabled
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
        HapticService.shared.impact()
        workoutHistory.remove(atOffsets: offsets)
        WorkoutHistoryService.shared.save(items: workoutHistory)
    }
    
    /// Loads saved workout plan from `StorageService` (first launch uses defaults inside `AppData`).
    private func loadConfigurationFromStorage() {
        let data = StorageService.shared.read()
        prepareSeconds = data.prepareSeconds
        workSeconds = data.workSeconds
        workToRestTransitionSeconds = data.workToRestTransitionSeconds
        restSeconds = data.restSeconds
        cycleRestSeconds = data.cycleRestSeconds
        cooldownSeconds = data.cooldownSeconds
        set = data.setsPerCycle
        cycle = data.cycles
        phaseColors = data.phaseColors
        soundVolume = data.soundVolume
        duckOtherAudio = data.duckOtherAudio
        midWorkCueEnabled = data.midWorkCueEnabled
        AudioService.shared.setVolume(soundVolume)
        AudioService.shared.setDuckOtherAudio(duckOtherAudio)
    }
    
    /// Writes the current plan to `UserDefaults` (same storage as `AppStorage("storage")`).
    func persistConfigurationToStorage() {
        if !SubscriptionService.shared.isPro, midWorkCueEnabled {
            midWorkCueEnabled = false
            cancelMidWorkCueTracking()
        }
        let data = AppData(
            prepareSeconds: prepareSeconds,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            cycleRestSeconds: cycleRestSeconds,
            cooldownSeconds: cooldownSeconds,
            setsPerCycle: set,
            cycles: cycle,
            workToRestTransitionSeconds: workToRestTransitionSeconds,
            phaseColors: phaseColors,
            soundVolume: soundVolume,
            duckOtherAudio: duckOtherAudio,
            midWorkCueEnabled: midWorkCueEnabled
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
    
    func showProfile() {
        isShowProfile.toggle()
    }
    
    /// Resets saved configuration, colors, and favorites to defaults.
    /// Intended for a "Clear data" action from Profile.
    func clearAllUserData() {
        timerCancellable?.cancel()
        timerCancellable = nil
        cancelMidWorkCueTracking()
        AudioService.shared.stopSound()
        
        let defaults = AppData()
        prepareSeconds = defaults.prepareSeconds
        workSeconds = defaults.workSeconds
        workToRestTransitionSeconds = defaults.workToRestTransitionSeconds
        restSeconds = defaults.restSeconds
        cycleRestSeconds = defaults.cycleRestSeconds
        cooldownSeconds = defaults.cooldownSeconds
        set = defaults.setsPerCycle
        cycle = defaults.cycles
        phaseColors = defaults.phaseColors
        soundVolume = defaults.soundVolume
        duckOtherAudio = defaults.duckOtherAudio
        midWorkCueEnabled = defaults.midWorkCueEnabled
        AudioService.shared.setVolume(soundVolume)
        AudioService.shared.setDuckOtherAudio(duckOtherAudio)
        
        workoutHistory.removeAll()
        WorkoutHistoryService.shared.save(items: [])
        
        pendingPhaseAdvance = false
        phase = .begin
        currentSetIndex = 0
        currentCycleIndex = 0
        currentPhaseRemainingSeconds = prepareSeconds
        remainingTotalSeconds = totalWorkoutDurationSeconds
        persistConfigurationToStorage()
    }
    
    func stripProFeatures() {
        prepareSeconds = 0
        workToRestTransitionSeconds = 0
        cycleRestSeconds = 0
        cooldownSeconds = 0
        phaseColors = .appDefault
        midWorkCueEnabled = false
        cancelMidWorkCueTracking()
        persistConfigurationToStorage()
    }
    
    func makeSettingsSnapshot() -> WorkoutSettingsSnapshot {
        WorkoutSettingsSnapshot(
            prepareSeconds: prepareSeconds,
            workSeconds: workSeconds,
            workToRestTransitionSeconds: workToRestTransitionSeconds,
            restSeconds: restSeconds,
            cycleRestSeconds: cycleRestSeconds,
            cooldownSeconds: cooldownSeconds,
            set: set,
            cycle: cycle,
            phaseColors: phaseColors,
            soundVolume: soundVolume,
            duckOtherAudio: duckOtherAudio,
            midWorkCueEnabled: midWorkCueEnabled
        )
    }
    
    func restoreSettings(_ snapshot: WorkoutSettingsSnapshot) {
        prepareSeconds = snapshot.prepareSeconds
        workSeconds = snapshot.workSeconds
        workToRestTransitionSeconds = snapshot.workToRestTransitionSeconds
        restSeconds = snapshot.restSeconds
        cycleRestSeconds = snapshot.cycleRestSeconds
        cooldownSeconds = snapshot.cooldownSeconds
        set = snapshot.set
        cycle = snapshot.cycle
        phaseColors = snapshot.phaseColors
        soundVolume = snapshot.soundVolume
        duckOtherAudio = snapshot.duckOtherAudio
        midWorkCueEnabled = snapshot.midWorkCueEnabled && SubscriptionService.shared.isPro
        AudioService.shared.setVolume(soundVolume)
        AudioService.shared.setDuckOtherAudio(duckOtherAudio)
    }
    
    func settingsDiffer(from snapshot: WorkoutSettingsSnapshot) -> Bool {
        prepareSeconds != snapshot.prepareSeconds
            || workSeconds != snapshot.workSeconds
            || workToRestTransitionSeconds != snapshot.workToRestTransitionSeconds
            || restSeconds != snapshot.restSeconds
            || cycleRestSeconds != snapshot.cycleRestSeconds
            || cooldownSeconds != snapshot.cooldownSeconds
            || set != snapshot.set
            || cycle != snapshot.cycle
            || midWorkCueEnabled != snapshot.midWorkCueEnabled
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
        workToRestTransitionSeconds = plan.workToRestTransitionSeconds
        restSeconds = plan.restSeconds
        cycleRestSeconds = plan.cycleRestSeconds
        cooldownSeconds = plan.cooldownSeconds
        set = plan.setsPerCycle
        cycle = plan.cycles
        phaseColors = plan.phaseColors
        soundVolume = plan.soundVolume
        AudioService.shared.setVolume(soundVolume)
        duckOtherAudio = plan.duckOtherAudio
        AudioService.shared.setDuckOtherAudio(duckOtherAudio)
        midWorkCueEnabled = plan.midWorkCueEnabled && SubscriptionService.shared.isPro
        remainingTotalSeconds = totalWorkoutDurationSeconds
        currentPhaseRemainingSeconds = prepareSeconds
        currentSetIndex = 0
        currentCycleIndex = 0
        persistConfigurationToStorage()
        return true
    }
    
    deinit {
        timerCancellable?.cancel()
        cancelMidWorkCueTracking()
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
        advanceThroughZeroDurations(playTransitionSound: false)
        guard phase != .begin else { return }
        subscribeToTicks()
    }
    
    /// Continues after Pause.
    func resumeTimer() {
        guard phase == .pause else { return }
        phase = phaseBeforePause
        subscribeToTicks()
        if phase == .work, let pauseStart = midWorkCuePauseBeganAt {
            let pauseSeconds = Date().timeIntervalSince(pauseStart)
            if let d = midWorkCueWallDeadline {
                midWorkCueWallDeadline = d.addingTimeInterval(pauseSeconds)
            }
            midWorkCuePauseBeganAt = nil
            scheduleMidWorkCueIfNeeded()
        }
    }
    
    func pauseTimer() {
        guard phase != .begin, phase != .pause else { return }
        phaseBeforePause = phase
        phase = .pause
        timerCancellable?.cancel()
        timerCancellable = nil
        if phaseBeforePause == .work { midWorkCuePauseBeganAt = Date() }
        cancelMidWorkCueScheduleOnly()
        AudioService.shared.stopSound()
    }
    
    func resetTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        cancelMidWorkCueTracking()
        AudioService.shared.stopSound()
        pendingPhaseAdvance = false
        phase = .begin
        currentSetIndex = 0
        currentCycleIndex = 0
        currentPhaseRemainingSeconds = prepareSeconds
        remainingTotalSeconds = totalWorkoutDurationSeconds
    }
    
    private func subscribeToTicks() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, tolerance: 0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        guard phase != .pause, phase != .begin else { return }
        
        if pendingPhaseAdvance {
            pendingPhaseAdvance = false
            advancePhase()
            advanceThroughZeroDurations()
            return
        }
        
        guard currentPhaseRemainingSeconds > 0 else { return }
        
        if (1...3).contains(currentPhaseRemainingSeconds) {
            AudioService.shared.playBeep()
        }
        
        currentPhaseRemainingSeconds -= 1
        
        // Even work durations: halfway matches a whole second on the countdown (e.g. 60 → bell at 0:30).
        // Wall-clock `Date + half` races with 1 Hz ticks and often fired at 0:29.
        if phase == .work,
           SubscriptionService.shared.isPro,
           midWorkCueEnabled,
           !midWorkCueDidFire,
           workSeconds > 0,
           workSeconds.isMultiple(of: 2),
           currentPhaseRemainingSeconds == workSeconds / 2 {
            midWorkCueDidFire = true
            AudioService.shared.playBell()
        }
        
        remainingTotalSeconds = max(0, remainingTotalSeconds - 1)
        
        if currentPhaseRemainingSeconds == 0 {
            pendingPhaseAdvance = true
        }
    }
    
    /// Skips phases with 0 s duration (e.g. no prepare / no rest).
    private func advanceThroughZeroDurations(playTransitionSound: Bool = true) {
        while phase != .begin && phase != .pause && currentPhaseRemainingSeconds == 0 {
            advancePhase(playTransitionSound: playTransitionSound)
            if phase == .begin { return }
        }
    }
    
    private func advancePhase(playTransitionSound: Bool = true) {
        switch phase {
        case .prepare:
            phase = .work
            currentSetIndex = 1
            currentPhaseRemainingSeconds = workSeconds
            if playTransitionSound { AudioService.shared.playStart() }
            beginMidWorkCueForCurrentInterval()
            
        case .work:
            cancelMidWorkCueTracking()
            if currentSetIndex < set {
                phase = .workToRestTransition
                currentPhaseRemainingSeconds = workToRestTransitionSeconds
                if playTransitionSound { AudioService.shared.playStart() }
            } else if currentCycleIndex < cycle {
                phase = .cycleRest
                currentPhaseRemainingSeconds = cycleRestSeconds
                if playTransitionSound { AudioService.shared.playStart() }
            } else {
                phase = .cooldown
                currentPhaseRemainingSeconds = cooldownSeconds
                if playTransitionSound { AudioService.shared.playStart() }
            }
            
        case .workToRestTransition:
            phase = .rest
            currentPhaseRemainingSeconds = restSeconds
            if playTransitionSound { AudioService.shared.playStart() }
            
        case .rest:
            currentSetIndex += 1
            phase = .work
            currentPhaseRemainingSeconds = workSeconds
            if playTransitionSound { AudioService.shared.playStart() }
            beginMidWorkCueForCurrentInterval()
            
        case .cycleRest:
            currentCycleIndex += 1
            phase = .work
            currentSetIndex = 1
            currentPhaseRemainingSeconds = workSeconds
            if playTransitionSound { AudioService.shared.playStart() }
            beginMidWorkCueForCurrentInterval()
            
        case .cooldown:
            finishWorkout()
            
        case .begin, .pause:
            break
        }
    }
    
    /// Incremented each time a full workout finishes. Observed in TimerView.
    var finishedWorkoutCounter: Int = 0

    private func finishWorkout() {
        timerCancellable?.cancel()
        timerCancellable = nil
        cancelMidWorkCueTracking()
        AudioService.shared.stopSound()
        AudioService.shared.playTimeFinish()
        pendingPhaseAdvance = false
        phase = .begin
        currentSetIndex = 0
        currentCycleIndex = 0
        currentPhaseRemainingSeconds = prepareSeconds
        remainingTotalSeconds = totalWorkoutDurationSeconds

        ReviewService.shared.recordWorkoutCompletion()
        finishedWorkoutCounter += 1
    }
    
    private func beginMidWorkCueForCurrentInterval() {
        cancelMidWorkCueTracking()
        guard SubscriptionService.shared.isPro, midWorkCueEnabled, workSeconds > 0 else { return }
        midWorkCueDidFire = false
        midWorkCuePauseBeganAt = nil
        // Odd durations need sub-second halfway (e.g. 11 → 5.5s); even durations use tick alignment in `tick()`.
        guard !workSeconds.isMultiple(of: 2) else {
            midWorkCueWallDeadline = nil
            return
        }
        let half = Double(workSeconds) / 2.0
        midWorkCueWallDeadline = Date().addingTimeInterval(half)
        scheduleMidWorkCueIfNeeded()
    }
    
    private func scheduleMidWorkCueIfNeeded() {
        midWorkCueWorkItem?.cancel()
        midWorkCueWorkItem = nil
        guard SubscriptionService.shared.isPro,
              midWorkCueEnabled,
              phase == .work,
              !midWorkCueDidFire,
              let deadline = midWorkCueWallDeadline else { return }
        let delay = deadline.timeIntervalSinceNow
        if delay <= 0 {
            midWorkCueDidFire = true
            AudioService.shared.playBell()
            return
        }
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.phase == .work, !self.midWorkCueDidFire else { return }
            self.midWorkCueDidFire = true
            AudioService.shared.playBell()
        }
        midWorkCueWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }
    
    private func cancelMidWorkCueScheduleOnly() {
        midWorkCueWorkItem?.cancel()
        midWorkCueWorkItem = nil
    }
    
    private func cancelMidWorkCueTracking() {
        cancelMidWorkCueScheduleOnly()
        midWorkCueWallDeadline = nil
        midWorkCuePauseBeganAt = nil
        midWorkCueDidFire = false
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
    
    /// Sum of interval durations (prepare, all work/rest in each cycle, cycle rests between cycles). Same value used for estimated total and ticking `remainingTotalSeconds` (transitions at 00:00 are not added).
    static func computePhaseDurationsSum(
        prepare: Int,
        work: Int,
        workToRestTransition: Int,
        rest: Int,
        cycleRest: Int,
        cooldown: Int,
        sets: Int,
        cycles: Int
    ) -> Int {
        let s = max(1, sets)
        let c = max(1, cycles)
        let t = max(0, workToRestTransition)
        let betweenPairs = max(0, s - 1) * (t + rest)
        let workRestInCycle = s * work + betweenPairs
        return prepare + c * workRestInCycle + max(0, c - 1) * cycleRest + max(0, cooldown)
    }
    
    /// Full workout length for UI and `remainingTotalSeconds` — phase durations only (no extra seconds for transitions).
    static func computeTotalWorkoutSeconds(
        prepare: Int,
        work: Int,
        workToRestTransition: Int,
        rest: Int,
        cycleRest: Int,
        cooldown: Int,
        sets: Int,
        cycles: Int
    ) -> Int {
        computePhaseDurationsSum(
            prepare: prepare,
            work: work,
            workToRestTransition: workToRestTransition,
            rest: rest,
            cycleRest: cycleRest,
            cooldown: cooldown,
            sets: sets,
            cycles: cycles
        )
    }
}

extension TimerViewModel {
    func timerTextColor(for phase: Phase) -> Color {
        switch phase {
        case .begin: phaseColors.begin.swiftUIColor
        case .prepare: phaseColors.prepare.swiftUIColor
        case .work: phaseColors.work.swiftUIColor
        case .workToRestTransition: phaseColors.workToRestTransition.swiftUIColor
        case .rest: phaseColors.rest.swiftUIColor
        case .pause: phaseColors.pause.swiftUIColor
        case .cycleRest: phaseColors.cycleRest.swiftUIColor
        case .cooldown: phaseColors.cooldown.swiftUIColor
        }
    }
    
    func colorPickerBinding(for key: TimerPhaseColorKey) -> Binding<Color> {
        switch key {
        case .prepare:
            Binding(
                get: { self.phaseColors.prepare.swiftUIColor },
                set: { v in var pc = self.phaseColors; pc.prepare = PhaseColorComponents(v); self.phaseColors = pc }
            )
        case .work:
            Binding(
                get: { self.phaseColors.work.swiftUIColor },
                set: { v in var pc = self.phaseColors; pc.work = PhaseColorComponents(v); self.phaseColors = pc }
            )
        case .workToRestTransition:
            Binding(
                get: { self.phaseColors.workToRestTransition.swiftUIColor },
                set: { v in var pc = self.phaseColors; pc.workToRestTransition = PhaseColorComponents(v); self.phaseColors = pc }
            )
        case .rest:
            Binding(
                get: { self.phaseColors.rest.swiftUIColor },
                set: { v in var pc = self.phaseColors; pc.rest = PhaseColorComponents(v); self.phaseColors = pc }
            )
        case .pause:
            Binding(
                get: { self.phaseColors.pause.swiftUIColor },
                set: { v in var pc = self.phaseColors; pc.pause = PhaseColorComponents(v); self.phaseColors = pc }
            )
        case .cycleRest:
            Binding(
                get: { self.phaseColors.cycleRest.swiftUIColor },
                set: { v in var pc = self.phaseColors; pc.cycleRest = PhaseColorComponents(v); self.phaseColors = pc }
            )
        case .cooldown:
            Binding(
                get: { self.phaseColors.cooldown.swiftUIColor },
                set: { v in var pc = self.phaseColors; pc.cooldown = PhaseColorComponents(v); self.phaseColors = pc }
            )
        }
    }
}
