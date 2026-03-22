//
//  MainTimeView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct MainTimeView: View {
    let time: String
    let phase: Phase
    
    private var textColor: Color {
        switch phase {
        case .begin: .white
        case .prepare: .yellow
        case .work: .red
        case .workToRestTransition: .white
        case .rest: .green
        case .pause: .orange
        case .cycleRest: .cyan
        }
    }
    
    var body: some View {
        Text(time)
            .font(.system(size: 130, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(textColor)
            .minimumScaleFactor(0.6)
            .multilineTextAlignment(.center)
            .contentTransition(.identity)
            .animation(nil, value: time)
    }
}

#Preview {
    MainTimeView(time: "00:00", phase: .begin)
}
