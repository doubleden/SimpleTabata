//
//  FavoriteTimerView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct FavoriteTimerView: View {
    @Bindable var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showActiveTimerAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if timerVM.workoutHistory.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("No favorites yet")
                            .font(.headline)
                            .minimumScaleFactor(0.6)
                        Text("In Workout plan, tap “Save parameters to favorites” to add one.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(timerVM.workoutHistory) { entry in
                            Button {
                                HapticService.shared.impact()
                                if timerVM.applyPlanFromHistory(entry.plan) {
                                    dismiss()
                                } else {
                                    showActiveTimerAlert = true
                                }
                            } label: {
                                FavoriteWorkoutRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: timerVM.deleteWorkoutHistory)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Favorite timers")
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
            }
            .alert("Workout in progress", isPresented: $showActiveTimerAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Stop or finish the timer on the main screen, then you can apply a favorite.")
            }
        }
    }
}

private struct FavoriteWorkoutRow: View {
    let entry: WorkoutHistoryEntry
    
    private var totalLabel: String {
        let total = TimerViewModel.computeTotalWorkoutSeconds(
            prepare: entry.plan.prepareSeconds,
            work: entry.plan.workSeconds,
            workToRestTransition: entry.plan.workToRestTransitionSeconds,
            rest: entry.plan.restSeconds,
            cycleRest: entry.plan.cycleRestSeconds,
            sets: entry.plan.setsPerCycle,
            cycles: entry.plan.cycles
        )
        return TimerViewModel.formatMMSS(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.name)
                .font(.headline)
                .minimumScaleFactor(0.6)
            Text(entry.savedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Total \(totalLabel) · \(entry.plan.setsPerCycle)× sets · \(entry.plan.cycles) cycles")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavoriteTimerView(timerVM: TimerViewModel())
}
