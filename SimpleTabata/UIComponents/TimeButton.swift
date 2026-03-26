//
//  TimeButton.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct TimeButton: View {
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let area = geo.size.width * geo.size.height
            let fontSize = sqrt(area) / 2
            
            Button(action: {
                withAnimation {
                    HapticService.shared.impact()
                    action()
                }
            }) {
                Image(systemName: systemImage)
                    .font(.system(size: fontSize))
                    .shadow(radius: 2)
                    .padding()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(color.opacity(0.8))
            }
        }
    }
}

#Preview {
    TimeButton(systemImage: "play", color: .green, action: {})
        .frame(width: 200, height: 200)
}
