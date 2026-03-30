//
//  ReviewService.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 30/3/26.
//

import Foundation

final class ReviewService {
    static let shared = ReviewService()

    private let completedKey = "completedWorkoutsCount"
    private let lastPromptKey = "lastReviewPromptDate"

    private let promptEveryN = 5
    private let minDaysBetweenPrompts = 30

    private init() {}

    func recordWorkoutCompletion() {
        let count = UserDefaults.standard.integer(forKey: completedKey) + 1
        UserDefaults.standard.set(count, forKey: completedKey)
    }

    var shouldRequestReview: Bool {
        let count = UserDefaults.standard.integer(forKey: completedKey)
        guard count > 0, count.isMultiple(of: promptEveryN) else { return false }

        if let last = UserDefaults.standard.object(forKey: lastPromptKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            if days < minDaysBetweenPrompts { return false }
        }
        return true
    }

    func markPromptShown() {
        UserDefaults.standard.set(Date(), forKey: lastPromptKey)
    }
}
