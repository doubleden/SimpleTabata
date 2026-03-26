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
    
    /// True when there is a verified, non-revoked auto-renewable entitlement
    /// whose expiration date has not yet passed.
    var isPro: Bool {
        guard hasEntitlement else { return false }
        if let exp = expirationDate, exp <= Date() {
            return false
        }
        return true
    }
    
    private var hasEntitlement = false
    private var expirationDate: Date?
    private var updateTask: Task<Void, Never>?
    
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
               tx.productType == .autoRenewable,
               tx.revocationDate == nil {
                if let exp = tx.expirationDate, exp <= Date() {
                    continue
                }
                active = true
                expDate = tx.expirationDate
                break
            }
        }
        hasEntitlement = active
        expirationDate = expDate
    }
}
