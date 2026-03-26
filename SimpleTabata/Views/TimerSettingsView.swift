//
//  TimerSettingsView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI
import UIKit

private enum SettingsExpandedSection: Equatable {
    case none
    case prepare, work, workToRestTransition, rest, cycleRest, cooldown, sets, cycles
}

struct TimerSettingsView: View {
    @Bindable var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var openingSnapshot: WorkoutSettingsSnapshot?
    @State private var showResetAlert = false
    @State private var expandedSection: SettingsExpandedSection = .none
    @State private var showSaveFavoriteSheet = false
    @State private var showSavedBanner = false
    @State private var showPaywall = false
    @State private var lastPrepareSeconds: Int = 10
    @State private var lastTransitionSeconds: Int = 5
    @State private var lastCycleRestSeconds: Int = 30
    @State private var lastCooldownSeconds: Int = 30
    
    private var isPrepareEnabled: Bool { timerVM.prepareSeconds > 0 }
    private var isTransitionEnabled: Bool { timerVM.workToRestTransitionSeconds > 0 }
    private var isCycleRestEnabled: Bool { timerVM.cycleRestSeconds > 0 }
    private var isCooldownEnabled: Bool { timerVM.cooldownSeconds > 0 }
    private var hasDisabledPhases: Bool { !isPrepareEnabled || !isTransitionEnabled || !isCycleRestEnabled || !isCooldownEnabled }
    
    private var totalWorkoutLabel: String {
        timerVM.formattedTime(timerVM.totalWorkoutDurationSeconds)
    }
    
    var body: some View {
        NavigationStack {
            settingsRoot
        }
    }
    
    private var settingsRoot: some View {
        settingsWithSheets
    }
    
    private var settingsChrome: some View {
        workoutPlanScroll
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Workout plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { settingsToolbar }
    }
    
    private var settingsWithObservers: some View {
        settingsChrome
            .onAppear {
                openingSnapshot = timerVM.makeSettingsSnapshot()
                if timerVM.prepareSeconds > 0 { lastPrepareSeconds = timerVM.prepareSeconds }
                if timerVM.workToRestTransitionSeconds > 0 { lastTransitionSeconds = timerVM.workToRestTransitionSeconds }
                if timerVM.cycleRestSeconds > 0 { lastCycleRestSeconds = timerVM.cycleRestSeconds }
                if timerVM.cooldownSeconds > 0 { lastCooldownSeconds = timerVM.cooldownSeconds }
                if timerVM.workSeconds < 1 { timerVM.workSeconds = 1 }
                if timerVM.restSeconds < 1 { timerVM.restSeconds = 1 }
            }
            .onChange(of: timerVM.prepareSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.workSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.workToRestTransitionSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.restSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.cycleRestSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.cooldownSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.set) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.cycle) { _, _ in onSettingsFieldChanged() }
    }
    
    private var settingsWithAlert: some View {
        settingsWithObservers
            .alert("Reset timer?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {
                    if let snap = openingSnapshot {
                        timerVM.restoreSettings(snap)
                    }
                }
                Button("Reset", role: .destructive) {
                    timerVM.resetTimer()
                    timerVM.applyConfigurationFromSettings()
                    openingSnapshot = timerVM.makeSettingsSnapshot()
                    timerVM.persistConfigurationToStorage()
                }
            } message: {
                Text("Changing the workout plan will reset the current timer. Are you sure?")
            }
            .onDisappear {
                if timerVM.phase == .pause,
                   let snap = openingSnapshot,
                   timerVM.settingsDiffer(from: snap) {
                    timerVM.restoreSettings(snap)
                }
                timerVM.applyConfigurationFromSettings()
                timerVM.persistConfigurationToStorage()
            }
    }
    
    private var settingsWithSheets: some View {
        settingsWithAlert
            .sheet(isPresented: $showPaywall) {
                PayWallView()
            }
            .sheet(isPresented: $showSaveFavoriteSheet) {
                SaveFavoriteParametersSheet(
                    onCancel: { showSaveFavoriteSheet = false },
                    onSave: { name in
                        showSaveFavoriteSheet = false
                        timerVM.addWorkoutToHistory(name: name)
                        presentSavedBanner()
                    }
                )
            }
            .overlay(alignment: .bottom) {
                if showSavedBanner {
                    savedBannerContent
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: showSavedBanner)
    }
    
    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                HapticService.shared.impact()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Close")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                HapticService.shared.impact()
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
    
    @ViewBuilder
    private var workoutPlanScroll: some View {
        ScrollView {
            VStack(spacing: 20) {
                totalSummaryCard
                
                if isPrepareEnabled {
                    durationCard(
                        section: .prepare,
                        title: "Prepare",
                        subtitle: "Warm-up before work intervals",
                        systemImage: "figure.cooldown",
                        tint: timerVM.intervalCardTint(for: .prepare),
                        binding: $timerVM.prepareSeconds,
                        onToggle: togglePrepare
                    )
                }
                
                durationCard(
                    section: .work,
                    title: "Work",
                    subtitle: "High-intensity interval",
                    systemImage: "flame.fill",
                    tint: timerVM.intervalCardTint(for: .work),
                    binding: $timerVM.workSeconds
                )
                if isTransitionEnabled {
                    durationCard(
                        section: .workToRestTransition,
                        title: "Transition",
                        subtitle: "Time to move before rest (between work rounds)",
                        systemImage: "figure.walk",
                        tint: timerVM.intervalCardTint(for: .workToRestTransition),
                        binding: $timerVM.workToRestTransitionSeconds,
                        onToggle: toggleTransition
                    )
                }
                durationCard(
                    section: .rest,
                    title: "Rest",
                    subtitle: "Recovery between work rounds",
                    systemImage: "leaf.fill",
                    tint: timerVM.intervalCardTint(for: .rest),
                    binding: $timerVM.restSeconds
                )
                
                if isCycleRestEnabled {
                    durationCard(
                        section: .cycleRest,
                        title: "Cycle rest",
                        subtitle: "Break between full cycles",
                        systemImage: "pause.circle.fill",
                        tint: timerVM.intervalCardTint(for: .cycleRest),
                        binding: $timerVM.cycleRestSeconds,
                        onToggle: toggleCycleRest
                    )
                }
                
                if isCooldownEnabled {
                    durationCard(
                        section: .cooldown,
                        title: "Cooldown",
                        subtitle: "Final recovery after all cycles",
                        systemImage: "wind",
                        tint: timerVM.intervalCardTint(for: .cooldown),
                        binding: $timerVM.cooldownSeconds,
                        onToggle: toggleCooldown
                    )
                }
                
                countsCard
                
                if hasDisabledPhases {
                    disabledPhasesCard
                }
                
                saveToFavoritesCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
    
    private var savedBannerContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
            Text("Parameters saved")
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        }
        .padding(.bottom, 20)
    }
    
    private func presentSavedBanner() {
        withAnimation(.spring(duration: 0.35)) {
            showSavedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.28)) {
                showSavedBanner = false
            }
        }
    }
    
    private func onSettingsFieldChanged() {
        guard timerVM.phase == .pause, let snap = openingSnapshot else {
            showResetAlert = false
            return
        }
        showResetAlert = timerVM.settingsDiffer(from: snap)
    }
    
    private func toggleSection(_ section: SettingsExpandedSection) {
        guard section != .none else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            expandedSection = expandedSection == section ? .none : section
        }
    }
    
    // MARK: - Optional phase toggles
    
    private func togglePrepare() {
        if !isPrepareEnabled && !SubscriptionService.shared.isPro {
            showPaywall = true; return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            if isPrepareEnabled {
                lastPrepareSeconds = timerVM.prepareSeconds
                timerVM.prepareSeconds = 0
                if expandedSection == .prepare { expandedSection = .none }
            } else {
                timerVM.prepareSeconds = max(1, lastPrepareSeconds)
            }
        }
    }
    
    private func toggleTransition() {
        if !isTransitionEnabled && !SubscriptionService.shared.isPro {
            showPaywall = true; return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            if isTransitionEnabled {
                lastTransitionSeconds = timerVM.workToRestTransitionSeconds
                timerVM.workToRestTransitionSeconds = 0
                if expandedSection == .workToRestTransition { expandedSection = .none }
            } else {
                timerVM.workToRestTransitionSeconds = max(1, lastTransitionSeconds)
            }
        }
    }
    
    private func toggleCycleRest() {
        if !isCycleRestEnabled && !SubscriptionService.shared.isPro {
            showPaywall = true; return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            if isCycleRestEnabled {
                lastCycleRestSeconds = timerVM.cycleRestSeconds
                timerVM.cycleRestSeconds = 0
                if expandedSection == .cycleRest { expandedSection = .none }
            } else {
                timerVM.cycleRestSeconds = max(1, lastCycleRestSeconds)
            }
        }
    }
    
    private func toggleCooldown() {
        if !isCooldownEnabled && !SubscriptionService.shared.isPro {
            showPaywall = true; return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            if isCooldownEnabled {
                lastCooldownSeconds = timerVM.cooldownSeconds
                timerVM.cooldownSeconds = 0
                if expandedSection == .cooldown { expandedSection = .none }
            } else {
                timerVM.cooldownSeconds = max(1, lastCooldownSeconds)
            }
        }
    }
    
    // MARK: - Disabled phases section
    
    private var disabledPhasesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Additional phases", systemImage: "plus.circle")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 0) {
                disabledPhasesContent
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    @ViewBuilder
    private var disabledPhasesContent: some View {
        let items: [(id: String, title: String, subtitle: String, icon: String, action: () -> Void)] = {
            var arr: [(String, String, String, String, () -> Void)] = []
            if !isPrepareEnabled { arr.append(("prepare", "Prepare", "Warm-up before work", "figure.cooldown", togglePrepare)) }
            if !isTransitionEnabled { arr.append(("transition", "Transition", "Move between work and rest", "figure.walk", toggleTransition)) }
            if !isCycleRestEnabled { arr.append(("cycleRest", "Cycle rest", "Break between cycles", "pause.circle.fill", toggleCycleRest)) }
            if !isCooldownEnabled { arr.append(("cooldown", "Cooldown", "Recovery after workout", "wind", toggleCooldown)) }
            return arr
        }()
        
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            if index > 0 {
                Divider().padding(.leading, 40)
            }
            disabledPhaseRow(
                title: item.title,
                subtitle: item.subtitle,
                systemImage: item.icon,
                onToggle: item.action
            )
        }
    }
    
    private func disabledPhaseRow(
        title: String,
        subtitle: String,
        systemImage: String,
        onToggle: @escaping () -> Void
    ) -> some View {
        DisabledPhaseToggleRow(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            onToggle: onToggle
        )
    }
    
    private var totalSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Estimated total", systemImage: "clock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(totalWorkoutLabel)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.identity)
                .animation(nil, value: totalWorkoutLabel)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("Sum of all interval durations. Updates live as you change settings.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
    
    private func durationCard(
        section: SettingsExpandedSection,
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        binding: Binding<Int>,
        onToggle: (() -> Void)? = nil
    ) -> some View {
        let isExpanded = expandedSection == section
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.6)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                if let onToggle {
                    Toggle("", isOn: Binding(
                        get: { binding.wrappedValue > 0 },
                        set: { _ in onToggle() }
                    ))
                    .labelsHidden()
                }
            }
            
            Button {
                toggleSection(section)
            } label: {
                HStack {
                    Text(timerVM.formattedTime(binding.wrappedValue))
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .foregroundStyle(tint)
                        .minimumScaleFactor(0.6)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                DurationWheelPicker(totalSeconds: binding, minimum: 1)
                    .frame(height: 160)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.14))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.32), lineWidth: 1)
        }
    }
    
    private var countsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Rounds & cycles", systemImage: "repeat")
                .font(.headline)
            
            VStack(spacing: 0) {
                countExpandableRow(
                    section: .sets,
                    title: "Sets",
                    detail: "Work + rest rounds in one cycle",
                    value: $timerVM.set,
                    range: 1...99
                )
                Divider().padding(.leading, 4)
                countExpandableRow(
                    section: .cycles,
                    title: "Cycles",
                    detail: "How many full cycles to run",
                    value: $timerVM.cycle,
                    range: 1...50
                )
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private var saveToFavoritesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Favorites", systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(.pink)
            Text("Save the current parameters under a name to reuse them from Favorite timers.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.6)
            Button {
                HapticService.shared.impact()
                if SubscriptionService.shared.isPro {
                    showSaveFavoriteSheet = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Text("Save parameters to favorites")
                        .font(.body.weight(.semibold))
                        .minimumScaleFactor(0.6)
                    Spacer()
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.body.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private func countExpandableRow(
        section: SettingsExpandedSection,
        title: String,
        detail: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        let isExpanded = expandedSection == section
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                toggleSection(section)
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .minimumScaleFactor(0.6)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 8)
                    Text("\(value.wrappedValue)")
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            
            if isExpanded {
                Picker(title, selection: value) {
                    ForEach(Array(range), id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipped()
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Disabled phase toggle row

private struct DisabledPhaseToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let onToggle: () -> Void
    
    @State private var isAnimatingOn = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .minimumScaleFactor(0.6)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { isAnimatingOn },
                set: { _ in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isAnimatingOn = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onToggle()
                        isAnimatingOn = false
                    }
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Duration wheel (minutes + seconds)

private struct DurationWheelPicker: View {
    @Binding var totalSeconds: Int
    var minimum: Int = 0
    
    private var minutes: Int {
        max(0, totalSeconds) / 60
    }
    
    private var seconds: Int {
        max(0, totalSeconds) % 60
    }
    
    private var minSeconds: Int {
        minutes == 0 && minimum > 0 ? minimum : 0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Picker("Minutes", selection: Binding(
                get: { minutes },
                set: { newMin in
                    let s = seconds
                    let floor = newMin == 0 && minimum > 0 ? minimum : 0
                    let clamped = max(floor, s)
                    totalSeconds = min(3599, newMin * 60 + clamped)
                }
            )) {
                ForEach(0..<60, id: \.self) { m in
                    Text("\(m) min").tag(m)
                }
            }
            .pickerStyle(.wheel)
            
            Picker("Seconds", selection: Binding(
                get: { seconds },
                set: { newSec in
                    let m = minutes
                    totalSeconds = min(3599, max(minimum, m * 60 + newSec))
                }
            )) {
                ForEach(minSeconds..<60, id: \.self) { s in
                    Text(String(format: "%02d sec", s)).tag(s)
                }
            }
            .pickerStyle(.wheel)
        }
        .onAppear {
            if totalSeconds < minimum { totalSeconds = minimum }
        }
    }
}

extension TimerViewModel {
    fileprivate func intervalCardTint(for section: SettingsExpandedSection) -> Color {
        switch section {
        case .none, .sets, .cycles:
            Color.accentColor
        case .prepare:
            phaseColors.prepare.swiftUIColor
        case .work:
            phaseColors.work.swiftUIColor
        case .workToRestTransition:
            phaseColors.workToRestTransition.swiftUIColor
        case .rest:
            phaseColors.rest.swiftUIColor
        case .cycleRest:
            phaseColors.cycleRest.swiftUIColor
        case .cooldown:
            phaseColors.cooldown.swiftUIColor
        }
    }
}

#Preview {
    TimerSettingsView(timerVM: TimerViewModel())
}
