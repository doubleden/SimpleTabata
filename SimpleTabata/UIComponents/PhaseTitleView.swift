//
//  PhaseTitleView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct PhaseTitleView: View {
    let phase: String
    var body: some View {
        Text(phase)
            .padding()
            .font(.largeTitle.italic())
            .foregroundStyle(Color.white)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PhaseTitleView(phase: "Work")
        .background(Color.gray)
}
