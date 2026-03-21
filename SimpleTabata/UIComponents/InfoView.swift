//
//  InfoView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct InfoView: View {
    let title: String
    let time: String
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text(title)
                .font(.title3.bold())
                .minimumScaleFactor(0.6)

                Text(time)
                    .multilineTextAlignment(.trailing)
                    .font(.largeTitle.bold())
                    .minimumScaleFactor(0.6)
        }
    }
}

#Preview {
    InfoView(title: "Set", time: "04")
}
