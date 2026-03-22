//
//  TimerSettingsView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

private enum SettingsExpandedSection: Equatable {
    case none
    case prepare, work, workToRestTransition, rest, cycleRest, sets, cycles
}

struct TimerSettingsView: View {
    @Bindable var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var openingSnapshot: WorkoutSettingsSnapshot?
    @State private var showResetAlert = false
    @State private var expandedSection: SettingsExpandedSection = .none
    @State private var showSaveFavoriteSheet = false
    @State private var showSavedBanner = false
    
    private var totalWorkoutLabel: String {
        timerVM.formattedTime(timerVM.totalWorkoutDurationSeconds)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalSummaryCard
                    
                    Group {
                        durationCard(
                            section: .prepare,
                            title: "Prepare",
                            subtitle: "Warm-up before work intervals",
                            systemImage: "figure.cooldown",
                            tint: .yellow,
                            binding: $timerVM.prepareSeconds
                        )
                        durationCard(
                            section: .work,
                            title: "Work",
                            subtitle: "High-intensity interval",
                            systemImage: "flame.fill",
                            tint: .green,
                            binding: $timerVM.workSeconds
                        )
                        durationCard(
                            section: .workToRestTransition,
                            title: "Transition",
                            subtitle: "Time to move before rest (between work rounds)",
                            systemImage: "figure.walk",
                            tint: colorScheme == .dark ? .white : Color(white: 0.38),
                            binding: $timerVM.workToRestTransitionSeconds
                        )
                        durationCard(
                            section: .rest,
                            title: "Rest",
                            subtitle: "Recovery between work rounds",
                            systemImage: "leaf.fill",
                            tint: .blue,
                            binding: $timerVM.restSeconds
                        )
                        durationCard(
                            section: .cycleRest,
                            title: "Cycle rest",
                            subtitle: "Break between full cycles",
                            systemImage: "pause.circle.fill",
                            tint: .cyan,
                            binding: $timerVM.cycleRestSeconds
                        )
                    }
                    
                    countsCard
                    
                    saveToFavoritesCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Workout plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
            .onAppear {
                openingSnapshot = timerVM.makeSettingsSnapshot()
            }
            .onChange(of: timerVM.prepareSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.workSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.workToRestTransitionSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.restSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.cycleRestSeconds) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.set) { _, _ in onSettingsFieldChanged() }
            .onChange(of: timerVM.cycle) { _, _ in onSettingsFieldChanged() }
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
        binding: Binding<Int>
    ) -> some View {
        let isExpanded = expandedSection == section
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                toggleSection(section)
            } label: {
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
                    Text(timerVM.formattedTime(binding.wrappedValue))
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .foregroundStyle(tint)
                        .minimumScaleFactor(0.6)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                DurationWheelPicker(totalSeconds: binding)
                    .frame(height: 160)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
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
                showSaveFavoriteSheet = true
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

// MARK: - Duration wheel (minutes + seconds)

private struct DurationWheelPicker: View {
    @Binding var totalSeconds: Int
    
    private var minutes: Int {
        max(0, totalSeconds) / 60
    }
    
    private var seconds: Int {
        max(0, totalSeconds) % 60
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Picker("Minutes", selection: Binding(
                get: { minutes },
                set: { newMin in
                    let s = seconds
                    totalSeconds = min(3599, max(0, newMin * 60 + s))
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
                    totalSeconds = min(3599, max(0, m * 60 + newSec))
                }
            )) {
                ForEach(0..<60, id: \.self) { s in
                    Text(String(format: "%02d sec", s)).tag(s)
                }
            }
            .pickerStyle(.wheel)
        }
    }
}

#Preview {
    TimerSettingsView(timerVM: TimerViewModel())
}
