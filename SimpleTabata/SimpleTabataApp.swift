//
//  SimpleTabataApp.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

@main
struct SimpleTabataApp: App {
    @AppStorage("onboardingCompleted") var isOnboardingCompleted = false
    
    init() {
        // Start StoreKit transaction observer at app launch.
        _ = SubscriptionService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !isOnboardingCompleted {
                    OnBoardingView(isPresented: $isOnboardingCompleted)
                        .transition(.move(edge: .bottom))
                } else {
                    NavigationStack {
                        TimerView()
                            .transition(.opacity)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
