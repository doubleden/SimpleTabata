//
//  TimerView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct TimerView: View {
    @State private var timerVM = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    /// Settings are only available on «Ready» or while paused — not during an active interval.
    private var isTimerRunning: Bool {
        switch timerVM.phase {
        case .begin, .pause: return false
        case .prepare, .work, .rest, .cycleRest: return true
        }
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 10) {
                PhaseTitleView(phase: timerVM.phase.title)
                MainTimeView(time: timerVM.currentTime, phase: timerVM.phase)
                
                InfoSectionView(
                    currentSet: timerVM.currentSetIndex,
                    totalSets: timerVM.set,
                    currentCycle: timerVM.currentCycleIndex,
                    totalCycles: timerVM.cycle,
                    totalTimeLeft: timerVM.totalTime
                )
            }
            .padding()
            
            Spacer()
            ZStack {
                switch timerVM.phase {
                case .begin:
                    TimerOffButtonSectionView(startAction: timerVM.startTimer)
                case .pause:
                    TimerPauseButtonSectionView(
                        continueAction: timerVM.resumeTimer,
                        resetAction: timerVM.resetTimer
                    )
                default:
                    TimerOnButtonSectionView(pauseAction: timerVM.pauseTimer)
                }
            }
            .frame(height: UIScreen.main.bounds.size.height * 0.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                colors: [Color.black, Color.gray],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    HapticService.shared.impact()
                    timerVM.showSettings()
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                }
                .disabled(isTimerRunning)
                .opacity(isTimerRunning ? 0.35 : 1)
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    HapticService.shared.impact()
                    timerVM.showFavoriteTimer()
                }) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                }
                .disabled(isTimerRunning)
                .opacity(isTimerRunning ? 0.35 : 1)
            }
        }
        .sheet(isPresented: $timerVM.isShowSettings) {
            TimerSettingsView(timerVM: timerVM)
        }
        .sheet(isPresented: $timerVM.isShowFavoriteTimer) {
            FavoriteTimerView(timerVM: timerVM)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                timerVM.persistConfigurationToStorage()
            }
        }
    }
}

// MARK: - SubViews
fileprivate struct InfoSectionView: View {
    let currentSet: Int
    let totalSets: Int
    let currentCycle: Int
    let totalCycles: Int
    let totalTimeLeft: String
    
    private var setCaption: String {
        if currentSet == 0 { return "\(totalSets)" }
        return "\(currentSet)/\(totalSets)"
    }
    
    private var cycleCaption: String {
        if currentCycle == 0 { return "\(totalCycles)" }
        return "\(currentCycle)/\(totalCycles)"
    }
    
    var body: some View {
        HStack(spacing: 50) {
            InfoView(title: "Set", time: setCaption)
            if totalCycles > 1 {
                InfoView(title: "Cycle", time: cycleCaption)
            }
            InfoView(title: "Total time", time: totalTimeLeft)
        }
        .foregroundStyle(Color.white)
    }
}

fileprivate struct TimerPauseButtonSectionView: View {
    let continueAction: () -> Void
    let resetAction: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            TimeButton(systemImage: "play", color: .green, action: continueAction)
            TimeButton(systemImage: "stop", color: .gray, action: resetAction)
        }
        .overlay(
            GeometryReader { geo in
                ZStack {
                    Rectangle()
                        .fill(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 4)
                        .shadow(radius: 3)
                        .position(
                            x: geo.size.width * 0.5,
                            y: geo.size.height * 0.0
                        )
                    
                    Rectangle()
                        .fill(.gray)
                        .frame(height: geo.size.height * 1.2)
                        .frame(width: 4)
                        .shadow(radius: 3)
                        .position(
                            x: geo.size.width * 0.5,
                            y: geo.size.height * 0.6
                        )
                }
            }
        )
    }
}

fileprivate struct TimerOnButtonSectionView: View {
    let pauseAction: () -> Void
    var body: some View {
        TimeButton(systemImage: "pause", color: .orange, action: pauseAction)
            .overlay(
                GeometryReader { geo in
                    ZStack {
                        Rectangle()
                            .fill(.gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 4)
                            .shadow(radius: 3)
                            .position(
                                x: geo.size.width * 0.5,
                                y: geo.size.height * 0.0
                            )
                    }
                }
            )
    }
}

fileprivate struct TimerOffButtonSectionView: View {
    let startAction: () -> Void
    var body: some View {
        TimeButton(systemImage: "play", color: .green, action: startAction)
            .overlay(
                GeometryReader { geo in
                    ZStack {
                        Rectangle()
                            .fill(.gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 4)
                            .shadow(radius: 3)
                            .position(
                                x: geo.size.width * 0.5,
                                y: geo.size.height * 0.0
                            )
                    }
                }
            )
    }
}

#Preview {
    NavigationStack {
        TimerView()
    }
}
