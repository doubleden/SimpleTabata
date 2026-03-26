//
//  PayWallViewModel.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 26/3/26.
//

import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class PayWallViewModel {
    var products: [Product] = []
    var selectedProductID: String = "tabata.year"
    var isLoading = false
    var isPurchasing = false
    var errorMessage: String?
    var didPurchase = false
    
    private static let productIDs: Set<String> = ["tabata.pro", "tabata.six", "tabata.year"]
    
    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            let order = ["tabata.year", "tabata.six", "tabata.pro"]
            products = fetched.sorted { (order.firstIndex(of: $0.id) ?? 99) < (order.firstIndex(of: $1.id) ?? 99) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func purchase() async {
        guard let product = products.first(where: { $0.id == selectedProductID }) else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    await SubscriptionService.shared.refreshStatus()
                    didPurchase = true
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await SubscriptionService.shared.refreshStatus()
            if SubscriptionService.shared.isPro {
                didPurchase = true
            } else {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func periodLabel(for product: Product) -> String {
        guard let sub = product.subscription else { return "" }
        switch sub.subscriptionPeriod.unit {
        case .month:
            return sub.subscriptionPeriod.value == 1 ? "month" : "\(sub.subscriptionPeriod.value) months"
        case .year:
            return sub.subscriptionPeriod.value == 1 ? "year" : "\(sub.subscriptionPeriod.value) years"
        default:
            return ""
        }
    }
    
    func savingsLabel(for product: Product) -> String? {
        guard let monthly = products.first(where: { $0.id == "tabata.pro" }),
              let sub = product.subscription,
              product.id != "tabata.pro" else { return nil }
        let monthlyPrice = monthly.price
        let totalMonths: Decimal
        switch sub.subscriptionPeriod.unit {
        case .month: totalMonths = Decimal(sub.subscriptionPeriod.value)
        case .year: totalMonths = Decimal(sub.subscriptionPeriod.value * 12)
        default: return nil
        }
        guard totalMonths > 0 else { return nil }
        let equivalentFull = monthlyPrice * totalMonths
        guard equivalentFull > 0 else { return nil }
        let saved = equivalentFull - product.price
        let pct = (saved / equivalentFull) * 100
        let rounded = NSDecimalNumber(decimal: pct).intValue
        return rounded > 0 ? "Save \(rounded)%" : nil
    }
    
    func badgeLabel(for product: Product) -> String? {
        switch product.id {
        case "tabata.year": return "Best value"
        case "tabata.six": return "Popular"
        default: return nil
        }
    }
    
    func monthlyEquivalentLabel(for product: Product) -> String? {
        guard let sub = product.subscription else { return nil }
        let totalMonths: Decimal
        switch sub.subscriptionPeriod.unit {
        case .month:
            totalMonths = Decimal(sub.subscriptionPeriod.value)
        case .year:
            totalMonths = Decimal(sub.subscriptionPeriod.value * 12)
        default: return nil
        }
        guard totalMonths > 1 else { return nil }
        let perMonth = product.price / totalMonths
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.priceFormatStyle.currencyCode
        formatter.maximumFractionDigits = 2
        guard let formatted = formatter.string(from: perMonth as NSDecimalNumber) else { return nil }
        return "\(formatted)/mo"
    }
    
    func freeTrialLabel(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        
        let period = offer.period
        let value = period.value
        guard value > 0 else { return nil }
        
        let unitText: String
        switch period.unit {
        case .day: unitText = value == 1 ? "day" : "days"
        case .week: unitText = value == 1 ? "week" : "weeks"
        case .month: unitText = value == 1 ? "month" : "months"
        case .year: unitText = value == 1 ? "year" : "years"
        @unknown default:
            return nil
        }
        
        return "\(value)-\(unitText) free trial"
    }
}
