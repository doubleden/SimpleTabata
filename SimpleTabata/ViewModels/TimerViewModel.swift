//
//  TimerViewModel.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Foundation
import Observation

@Observable
final class TimerViewModel {
    var phase = Phase.prepare
    var currentTime = "00:00"
    var set = 0
    var cycle = 0
    var totalTime = "00:00"
    
    var isShowSettings = false
    
    func showSettings() {
        isShowSettings.toggle()
    }
    
    func startTimer() {
        
    }
    
    func pauseTimer() {
        
    }
    
    func resetTimer() {
        
    }
    
    
}
