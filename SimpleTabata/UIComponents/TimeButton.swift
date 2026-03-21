//
//  TimeButton.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct TimeButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: {
            withAnimation {
                action()
            }
        }) {
            Text(title)
                .font(.largeTitle.bold())
                .shadow(radius: 2)
                .padding()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color.opacity(0.8))
        }
    }
}

#Preview {
    TimeButton(title: "Start", color: .green, action: {})
        .frame(width: 200, height: 200)
}
