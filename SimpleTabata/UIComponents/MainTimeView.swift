//
//  MainTimeView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct MainTimeView: View {
    let time: String
    
    var body: some View {
        Text(time)
            .font(.system(size: 130, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .minimumScaleFactor(0.8)
            .padding()
    }
}

#Preview {
    MainTimeView(time: "00:00")
}
