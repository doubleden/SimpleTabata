//
//  TimerView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct TimerView: View {
    @State private var timerVM = TimerViewModel()
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
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
                Button(action: timerVM.showSettings) {
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $timerVM.isShowSettings) {
            TimerSettingsView(timerVM: timerVM)
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
            TimeButton(title: "Start", color: .green, action: continueAction)
            TimeButton(title: "Reset", color: .gray, action: resetAction)
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
        TimeButton(title: "Pause", color: .orange, action: pauseAction)
    }
}

fileprivate struct TimerOffButtonSectionView: View {
    let startAction: () -> Void
    var body: some View {
        TimeButton(title: "Start", color: .green, action: startAction)
    }
}

#Preview {
    NavigationStack {
        TimerView()
    }
}
