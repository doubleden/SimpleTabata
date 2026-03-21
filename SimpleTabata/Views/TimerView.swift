//
//  TimerView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct TimerView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    PhaseTitleView(phase: "Exercise")
                    MainTimeView(time: "00:00")
                    
                    InfoSectionView(
                        set: 4,
                        cycle: 5,
                        totalTimeLeft: "15:34"
                    )
                }
                .padding()
                
                Spacer()
                ButtonSectionView()
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
                Button(action: {}) {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

// MARK: - SubViews
fileprivate struct InfoSectionView: View {
    let set: Int
    let cycle: Int
    let totalTimeLeft: String
    
    var body: some View {
        HStack(spacing: 50) {
            InfoView(title: "Set", time: set.formatted())
            if cycle != 0 {
                InfoView(title: "Cycle", time: cycle.formatted())
            }
            InfoView(title: "Total time", time: totalTimeLeft)
        }
        .foregroundStyle(Color.white)
    }
}

fileprivate struct ButtonSectionView: View {
    var body: some View {
        HStack(spacing: 0) {
            TimeButton(title: "Start", color: .green, action: {})
            TimeButton(title: "Stop", color: .red, action: {})
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


#Preview {
    NavigationStack {
        TimerView()
    }
}
