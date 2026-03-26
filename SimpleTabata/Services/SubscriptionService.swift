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
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productType == .autoRenewable,
               tx.revocationDate == nil {
                active = true
                break
            }
        }
        isPro = active
    }
}
