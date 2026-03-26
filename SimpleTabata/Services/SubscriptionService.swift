//
//  SubscriptionService.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 26/3/26.
//

import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()
    
    private(set) var isPro = false
    
    private var expirationDate: Date?
    private var updateTask: Task<Void, Never>?
    private var expirationTimer: Task<Void, Never>?
    
    private init() {
        updateTask = Task { [weak self] in
            await self?.refreshStatus()
            for await verificationResult in Transaction.updates {
                if case .verified(let tx) = verificationResult {
                    await tx.finish()
                }
                await self?.refreshStatus()
            }
        }
    }
    
    func refreshStatus() async {
        var active = false
        var expDate: Date?
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.revocationDate == nil {
                if tx.productType == .nonConsumable {
                    active = true
                    expDate = nil
                    break
                }
                if tx.productType == .autoRenewable {
                    if let exp = tx.expirationDate, exp <= Date() {
                        continue
                    }
                    active = true
                    expDate = tx.expirationDate
                    break
                }
            }
        }
        expirationDate = expDate
        isPro = active
        scheduleExpirationCheck()
    }
    
    private func scheduleExpirationCheck() {
        expirationTimer?.cancel()
        guard isPro, let exp = expirationDate else { return }
        let delay = exp.timeIntervalSinceNow
        guard delay > 0 else {
            isPro = false
            return
        }
        expirationTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.refreshStatus()
        }
    }
}
