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
        case .rest: .green
        case .pause: .orange
        case .cycleRest: .green
        }
    }
    
    var body: some View {
        Text(time)
            .font(.system(size: 130, weight: .bold, design: .rounded))
            .foregroundStyle(textColor)
            .minimumScaleFactor(0.8)
            .padding()
    }
}

#Preview {
    MainTimeView(time: "00:00", phase: .begin)
}
