//
//  WorkoutHistoryService.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Foundation

private struct WorkoutHistoryFile: Codable {
    var items: [WorkoutHistoryEntry]
}

final class WorkoutHistoryService {
    static let shared = WorkoutHistoryService()
    
    private let storageKey = "workoutHistory"
    
    private init() {}
    
    func load() -> [WorkoutHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        let file = try? JSONDecoder().decode(WorkoutHistoryFile.self, from: data)
        return file?.items ?? []
    }
    
    func save(items: [WorkoutHistoryEntry]) {
        let file = WorkoutHistoryFile(items: items)
        guard let data = try? JSONEncoder().encode(file) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
