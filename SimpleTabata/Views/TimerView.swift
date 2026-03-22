//
//  TimerView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI
import StoreKit

struct TimerView: View {
    @State private var timerVM = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) var requestReview
    
    /// Settings are only available on «Ready» or while paused — not during an active interval.
    private var isTimerRunning: Bool {
        switch timerVM.phase {
        case .begin, .pause: return false
        case .prepare, .work, .workToRestTransition, .rest, .cycleRest: return true
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                HorizontalView(timerVM: timerVM, geometry: geometry)
            } else {
                VerticalView(timerVM: timerVM, geometry: geometry)
            }
        }
        .background {
            Color.black
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
            
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    HapticService.shared.impact()
                    requestReview()
                }) {
                    Image(systemName: "hand.thumbsup")
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
                if isTimerRunning {
                    timerVM.pauseTimer()
                }
                timerVM.persistConfigurationToStorage()
            }
        }
    }
}

// MARK: - Geometry Views
fileprivate struct VerticalView: View {
    @Bindable var timerVM: TimerViewModel
    let geometry: GeometryProxy
    
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
            .frame(height: geometry.size.height * 0.3)
        }
    }
}

fileprivate struct HorizontalView: View {
    @Bindable var timerVM: TimerViewModel
    let geometry: GeometryProxy
    
    var body: some View {
        HStack {
            VStack(spacing: 0) {
                HStack {
                    Text(timerVM.phase.title)
                        .padding()
                        .font(.largeTitle.italic())
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    InfoSectionView(
                        currentSet: timerVM.currentSetIndex,
                        totalSets: timerVM.set,
                        currentCycle: timerVM.currentCycleIndex,
                        totalCycles: timerVM.cycle,
                        totalTimeLeft: timerVM.totalTime
                    )
                }
                Spacer()
            }
            .padding(.top, 40)
            .overlay(
                GeometryReader { geo in
                    MainTimeView(time: timerVM.currentTime, phase: timerVM.phase, fontSize: geo.size.height * 0.6)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.6)
                    
                }
            )
            
            
            Spacer()
            ZStack {
                switch timerVM.phase {
                case .begin:
                    TimeButton(systemImage: "play", color: .green, action: timerVM.startTimer)
                        .overlay(
                            GeometryReader { geo in
                                ZStack {
                                    Rectangle()
                                        .fill(.gray)
                                        .frame(height: geo.size.height * 1.3)
                                        .frame(width: 4)
                                        .shadow(radius: 3)
                                        .position(
                                            x: geo.size.width * 0,
                                            y: geo.size.height * 0.6
                                        )
                                }
                            }
                        )
                case .pause:
                    TimerPauseButtonSectionHorizontalView(
                        continueAction: timerVM.resumeTimer,
                        resetAction: timerVM.resetTimer
                    )
                default:
                    TimeButton(systemImage: "pause", color: .orange, action: timerVM.pauseTimer)
                        .overlay(
                            GeometryReader { geo in
                                ZStack {
                                    Rectangle()
                                        .fill(.gray)
                                        .frame(height: geo.size.height * 1.3)
                                        .frame(width: 4)
                                        .shadow(radius: 3)
                                        .position(
                                            x: geo.size.width * 0,
                                            y: geo.size.height * 0.6
                                        )
                                }
                            }
                        )
                }
            }
            .frame(width: geometry.size.height * 0.45)
        }
        .padding()
        .ignoresSafeArea()
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

fileprivate struct TimerPauseButtonSectionHorizontalView: View {
    let continueAction: () -> Void
    let resetAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            TimeButton(systemImage: "stop", color: .gray, action: resetAction)
            TimeButton(systemImage: "play", color: .green, action: continueAction)
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
                            y: geo.size.height * 0.5
                        )
                    
                    Rectangle()
                        .fill(.gray)
                        .frame(height: geo.size.height * 1.3)
                        .frame(width: 4)
                        .shadow(radius: 3)
                        .position(
                            x: geo.size.width * 0,
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
