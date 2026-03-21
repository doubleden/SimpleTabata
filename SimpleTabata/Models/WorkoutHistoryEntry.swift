//
//  WorkoutHistoryEntry.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Foundation

struct WorkoutHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var savedAt: Date
    var name: String
    /// Workout plan snapshot at the time of saving.
    var plan: AppData
}
