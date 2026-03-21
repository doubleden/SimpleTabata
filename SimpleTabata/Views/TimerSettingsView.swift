//
//  TimerSettingsView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct TimerSettingsView: View {
    @Bindable var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                            title: "Prepare",
                            subtitle: "Warm-up before work intervals",
                            systemImage: "figure.cooldown",
                            tint: .yellow,
                            binding: $timerVM.prepareSeconds
                        )
                        durationCard(
                            title: "Work",
                            subtitle: "High-intensity interval",
                            systemImage: "flame.fill",
                            tint: .red,
                            binding: $timerVM.workSeconds
                        )
                        durationCard(
                            title: "Rest",
                            subtitle: "Recovery between work rounds",
                            systemImage: "leaf.fill",
                            tint: .green,
                            binding: $timerVM.restSeconds
                        )
                        durationCard(
                            title: "Cycle rest",
                            subtitle: "Break between full cycles",
                            systemImage: "pause.circle.fill",
                            tint: .cyan,
                            binding: $timerVM.cycleRestSeconds
                        )
                    }
                    
                    countsCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Workout plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        timerVM.applyConfigurationFromSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: timerVM.prepareSeconds) { _ in timerVM.applyConfigurationFromSettings() }
            .onChange(of: timerVM.workSeconds) { _ in timerVM.applyConfigurationFromSettings() }
            .onChange(of: timerVM.restSeconds) { _ in timerVM.applyConfigurationFromSettings() }
            .onChange(of: timerVM.cycleRestSeconds) { _ in timerVM.applyConfigurationFromSettings() }
            .onChange(of: timerVM.set) { _ in timerVM.applyConfigurationFromSettings() }
            .onChange(of: timerVM.cycle) { _ in timerVM.applyConfigurationFromSettings() }
        }
    }
    
    private var totalSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Estimated total", systemImage: "clock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(totalWorkoutLabel)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("Total time updates live as you change intervals, sets, and cycles.")
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
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        binding: Binding<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.6)
                }
                Spacer(minLength: 0)
                Text(timerVM.formattedTime(binding.wrappedValue))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(tint)
                    .minimumScaleFactor(0.6)
            }
            
            DurationWheelPicker(totalSeconds: binding)
                .frame(height: 160)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private var countsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Rounds & cycles", systemImage: "repeat")
                .font(.headline)
            
            VStack(spacing: 0) {
                stepperRow(
                    title: "Sets per cycle",
                    detail: "Work + rest rounds in one cycle",
                    value: $timerVM.set,
                    range: 1...99
                )
                Divider().padding(.leading, 4)
                stepperRow(
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
    
    private func stepperRow(
        title: String,
        detail: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 8)
            Picker(title, selection: value) {
                ForEach(Array(range), id: \.self) { n in
                    Text("\(n)").tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100, height: 120)
            .clipped()
        }
        .padding(.vertical, 8)
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
