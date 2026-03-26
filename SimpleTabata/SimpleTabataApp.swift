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
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
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
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await SubscriptionService.shared.refreshStatus()
                    }
                }
            }
        }
    }
}
