//
//  TimerHistoryView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct TimerHistoryView: View {
    @Bindable var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Workout history")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}

#Preview {
    TimerHistoryView(timerVM: TimerViewModel())
}
