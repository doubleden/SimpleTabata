//
//  StorageService.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Foundation

/// Persists `AppData` under the same key SwiftUI `AppStorage("storage")` uses (`UserDefaults`).
final class StorageService {
    static let shared = StorageService()
    
    private let storageKey = "storage"
    
    private init() {}
    
    func read() -> AppData {
        guard let storageData = UserDefaults.standard.data(forKey: storageKey) else {
            return AppData()
        }
        let storage = try? JSONDecoder().decode(AppData.self, from: storageData)
        return storage ?? AppData()
    }
    
    func save(storage: AppData) {
        guard let encoded = try? JSONEncoder().encode(storage) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }
}
