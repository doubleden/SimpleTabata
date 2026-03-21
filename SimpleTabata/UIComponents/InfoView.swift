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

                Text(time)
                    .multilineTextAlignment(.trailing)
                    .font(.largeTitle.bold())
        }
    }
}

#Preview {
    InfoView(title: "Set", time: "04")
}
