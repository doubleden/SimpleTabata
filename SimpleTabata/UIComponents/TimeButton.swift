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
    
    let screen = UIScreen.main.bounds.size
    
    var body: some View {
        GeometryReader { geo in
            Button(action: {
                withAnimation {
                    HapticService.shared.impact()
                    action()
                }
            }) {
                Image(systemName: systemImage)
                    .font(.system(size: geo.size.width * 0.5))
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
