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
    var fontSize = 130.0
    
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
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
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
