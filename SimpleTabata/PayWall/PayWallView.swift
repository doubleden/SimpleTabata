//
//  PayWallView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 26/3/26.
//

import SwiftUI
import StoreKit

struct PayWallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = PayWallViewModel()
    
    enum CloseButtonStyle: Equatable {
        case xmark
        case later
    }
    
    var closeButtonStyle: CloseButtonStyle = .xmark
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                background
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                        featuresGrid
                        planCards
                        purchaseButton
                        restoreButton
                        legalFooter
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                
                if vm.isPurchasing {
                    purchasingOverlay
                }
            }
            .task { await vm.loadProducts() }
            .onChange(of: vm.didPurchase) { _, purchased in
                if purchased { close() }
            }
            .alert("Error", isPresented: .init(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticService.shared.impact()
                        close()
                    } label: {
                        switch closeButtonStyle {
                        case .xmark:
                            Image(systemName: "xmark")
                                .foregroundStyle(.white)
                        case .later:
                            Text("Later")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .minimumScaleFactor(0.6)
                        }
                    }
                }
            }
        }
    }
    
    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
    
    // MARK: - Background
    
    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.08, blue: 0.14),
                Color(red: 0.04, green: 0.04, blue: 0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Unlock Pro")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
            
            Text("Take full control of your workouts")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .minimumScaleFactor(0.6)
        }
    }
    
    // MARK: - Features
    
    private var featuresGrid: some View {
        VStack(spacing: 14) {
            featureRow(icon: "paintpalette.fill", color: .purple, text: "Custom timer colors")
            featureRow(icon: "heart.fill", color: .pink, text: "Save favorite workouts")
            featureRow(icon: "figure.cooldown", color: .yellow, text: "Prepare & Cooldown phases")
            featureRow(icon: "figure.walk", color: .cyan, text: "Transition & Cycle rest phases")
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.06))
        }
    }
    
    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
        }
    }
    
    // MARK: - Plan cards
    
    private var planCards: some View {
        VStack(spacing: 10) {
            if vm.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(height: 80)
            } else {
                ForEach(vm.products, id: \.id) { product in
                    planCard(product)
                }
            }
        }
    }
    
    private func planCard(_ product: Product) -> some View {
        let isSelected = vm.selectedProductID == product.id
        let discount = vm.savingsLabel(for: product)
        let badge = vm.badgeLabel(for: product)
        let perMonth = vm.monthlyEquivalentLabel(for: product)
        let trial = vm.freeTrialLabel(for: product)
        let fakeOld = vm.fakePreviousPrice(for: product)
        let subtitle = vm.subtitleLabel(for: product)
        
        return Button {
            HapticService.shared.selectionChanged()
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectedProductID = product.id
            }
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? Color.orange : Color.white.opacity(0.25), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 14, height: 14)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(vm.periodLabel(for: product))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                        
                        HStack(spacing: 6) {
                            if let fakeOld {
                                Text(fakeOld)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.35))
                                    .strikethrough(true, color: .white.opacity(0.35))
                                    .minimumScaleFactor(0.6)
                            }
                            Text(product.displayPrice)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .minimumScaleFactor(0.6)
                            if let discount {
                                Text(discount)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.85), in: Capsule())
                            }
                        }
                        
                        if let perMonth {
                            Text(perMonth)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                                .minimumScaleFactor(0.6)
                        }
                        
                        if let trial {
                            Text(trial)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.green)
                                .minimumScaleFactor(0.6)
                        }
                        
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                                .minimumScaleFactor(0.6)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, badge != nil ? 8 : 16)
                .padding(.bottom, badge != nil ? 6 : 0)
            }
            .overlay(
                ZStack {
                    if let badge {
                        VStack {
                            HStack {
                                Spacer()
                                Text(badge)
                                    .font(.caption2.weight(.heavy))
                                    .textCase(.uppercase)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        product.id == "tabata.lifetime"
                                        ? LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [.orange, Color(red: 1, green: 0.35, blue: 0.1)], startPoint: .leading, endPoint: .trailing),
                                        in: Capsule()
                                    )
                            }
                            Spacer()
                        }
                        .padding()
                    }
                }
            )
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.orange.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isSelected ? Color.orange.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1.5)
                    }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Purchase
    
    private var purchaseButton: some View {
        let selected = vm.products.first(where: { $0.id == vm.selectedProductID })
        let isLifetime = selected?.id == "tabata.lifetime"
        let trial = selected.flatMap { vm.freeTrialLabel(for: $0) }
        let title = isLifetime ? "Purchase" : (trial != nil ? "Start free trial" : "Continue")
        
        return Button {
            HapticService.shared.impact()
            Task { await vm.purchase() }
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.orange, Color(red: 1, green: 0.35, blue: 0.1)], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .disabled(vm.products.isEmpty)
    }
    
    private var restoreButton: some View {
        Button {
            Task { await vm.restorePurchases() }
        } label: {
            Text("Restore purchases")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
    
    // MARK: - Legal
    
    private var legalFooter: some View {
        VStack(spacing: 4) {
            Text("By continuing, you agree to the Terms of Use and Privacy Policy.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
            
            Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. You can manage or cancel in Settings.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
            HStack(spacing: 12) {
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Text("•").foregroundStyle(.white.opacity(0.15))
                Link("Privacy Policy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.25))
        }
    }
    
    // MARK: - Purchasing overlay
    
    private var purchasingOverlay: some View {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
            .overlay {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
    }
}

#Preview {
    PayWallView()
}
