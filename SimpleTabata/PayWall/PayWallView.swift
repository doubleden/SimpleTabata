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
                if purchased { dismiss() }
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
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
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
        let savings = vm.savingsLabel(for: product)
        return Button {
            HapticService.shared.selectionChanged()
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectedProductID = product.id
            }
        } label: {
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
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                        if let savings {
                            Text(savings)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange, in: Capsule())
                        }
                    }
                    Text(product.displayPrice + " / " + vm.periodLabel(for: product))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .minimumScaleFactor(0.6)
                }
                
                Spacer()
            }
            .padding(16)
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
        Button {
            HapticService.shared.impact()
            Task { await vm.purchase() }
        } label: {
            Text("Continue")
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
            Text("Recurring billing. Cancel anytime in Settings.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.25))
                .minimumScaleFactor(0.6)
            HStack(spacing: 12) {
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Text("•").foregroundStyle(.white.opacity(0.15))
                Link("Privacy Policy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.25))
        }
        .multilineTextAlignment(.center)
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
