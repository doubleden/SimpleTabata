//
//  MainTimeView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct MainTimeView: View {
    let time: String
    let textColor: Color
    var fontSize = 130.0
    
    var body: some View {
        Text(time)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(textColor)
            .minimumScaleFactor(0.6)
            .multilineTextAlignment(.center)
            .contentTransition(.identity)
            .animation(nil, value: time)
            .shadow(color: .white, radius: 1)
    }
}

#Preview {
    MainTimeView(time: "00:00", textColor: .cyan)
}
