//
//  OnBoardingView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 26/3/26.
//

import SwiftUI
import StoreKit

/// Страницы TabView — только те, что реально лежат внутри `TabView`. Paywall открывается отдельно (`fullScreenCover`).
fileprivate enum OnboardingTab: Hashable, CaseIterable {
    case welcome
    case proBenefits
    case payWall
}

struct OnBoardingView: View {
    @Binding var isPresented: Bool
    @State private var tab: OnboardingTab = .welcome
    @State private var paywallVM = PayWallViewModel()
    
    var body: some View {
        ZStack {
            background
            
            VStack(spacing: 18) {
                TabView(selection: $tab) {
                    WelcomePage()
                        .tag(OnboardingTab.welcome)
                    ProBenefitsPage()
                        .tag(OnboardingTab.proBenefits)
                    OnBoardingPayWall(vm: paywallVM, isPresented: $isPresented)
                        .tag(OnboardingTab.payWall)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
            }
            
            VStack {
                Spacer()
                onboardingCTA
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
            }
            
            if paywallVM.isPurchasing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .controlSize(.large)
                            .tint(.white)
                    }
            }
        }
        .task { await paywallVM.loadProducts() }
        .onChange(of: paywallVM.didPurchase) { _, didPurchase in
            if didPurchase {
                isPresented.toggle()
            }
        }
        .alert("Error", isPresented: .init(
            get: { paywallVM.errorMessage != nil },
            set: { if !$0 { paywallVM.errorMessage = nil } }
        )) {
            Button("OK") { paywallVM.errorMessage = nil }
        } message: {
            Text(paywallVM.errorMessage ?? "")
        }
    }
}

#Preview {
    OnBoardingView(isPresented: .constant(true))
}

// MARK: - Background

private extension OnBoardingView {
    var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.06, blue: 0.12),
                Color(red: 0.02, green: 0.02, blue: 0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            RadialGradient(
                colors: [
                    Color.orange.opacity(0.18),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }
    
    var buttonTitle: String {
        switch tab {
        case .welcome: return "Get Started"
        case .proBenefits: return "See Pro"
        case .payWall:
            let selected = paywallVM.products.first(where: { $0.id == paywallVM.selectedProductID })
            let isLifetime = selected?.id == "tabata.lifetime"
            let hasTrial = selected.flatMap { paywallVM.freeTrialLabel(for: $0) } != nil
            if isLifetime { return "Purchase" }
            if hasTrial { return "Start free trial" }
            return "Purchase"
        }
    }
    
    var onboardingCTA: some View {
        VStack(spacing: 10) {
            Button {
                HapticService.shared.selectionChanged()
                switch tab {
                case .welcome:
                    withAnimation(.easeInOut(duration: 0.25)) { tab = .proBenefits }
                case .proBenefits:
                    withAnimation(.easeInOut(duration: 0.25)) { tab = .payWall }
                case .payWall:
                    Task { await paywallVM.purchase() }
                }
            } label: {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.orange, Color(red: 1, green: 0.35, blue: 0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
            .disabled(tab == .payWall && paywallVM.products.isEmpty)
            
        }
    }
}

// MARK: - Pages

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 110, height: 110)
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                    }
                Image(systemName: "timer")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            VStack(spacing: 10) {
                Text("Welcome to SimpleTabata")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                
                Text("A simple Tabata timer — no ads, no clutter.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                bullet(icon: "bolt.fill", title: "Fast setup", subtitle: "Start a workout in seconds.")
                bullet(icon: "speaker.wave.2.fill", title: "Sound cues", subtitle: "Beep countdown and phase start.")
                bullet(icon: "paintpalette.fill", title: "Clean UI", subtitle: "Focus on training, not settings.")
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 24)
            
            Spacer(minLength: 40)
        }
        .padding(.top, 30)
    }
    
    private func bullet(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.orange)
                .frame(width: 34, height: 34)
                .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .minimumScaleFactor(0.6)
            }
            Spacer()
        }
    }
}

private struct ProBenefitsPage: View {
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .frame(width: 130, height: 90)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                    }
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            VStack(spacing: 10) {
                Text("Go Pro")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                
                Text("Personalize your timer and unlock advanced phases.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 14) {
                benefit(icon: "paintpalette.fill", color: .purple, title: "Custom colors", subtitle: "Make phases easy to recognize.")
                benefit(icon: "heart.fill", color: .pink, title: "Favorites", subtitle: "Save your best Tabata presets.")
                benefit(icon: "figure.cooldown", color: .yellow, title: "Extra phases", subtitle: "Prepare, Transition, Cycle Rest, Cooldown.")
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 24)
            
            Text("Next: choose a plan (you can also do this later).")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
                .minimumScaleFactor(0.6)
                .padding(.top, 2)
            
            Spacer(minLength: 40)
        }
        .padding(.top, 30)
    }
    
    private func benefit(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .minimumScaleFactor(0.6)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
        }
    }
}

private struct OnBoardingPayWall: View {
    @Bindable var vm: PayWallViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                header
                features
                planCards
                buyLaterButton
                restoreButton
                legalFooter
                    .padding(.bottom, 100)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "flame.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Unlock Pro")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
            
            Text("Choose a plan to personalize your workouts.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
        }
    }
    
    private var features: some View {
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
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                }
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
                                .foregroundStyle(.white.opacity(0.85))
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
                .overlay(
                    VStack {
                        if let badge {
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
                            .padding(.trailing, 12)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                        }
                        Spacer()
                    }
                )
            }
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
    
    private var restoreButton: some View {
        Button {
            Task { await vm.restorePurchases() }
        } label: {
            Text("Restore purchases")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
                .minimumScaleFactor(0.6)
        }
        .buttonStyle(.bordered)
    }
    
    private var buyLaterButton: some View {
        Button {
            isPresented.toggle()
        } label: {
            Text("Buy later")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.45))
                .minimumScaleFactor(0.6)
        }
        .buttonStyle(.bordered)
    }
    
    private static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private static let privacyURL = URL(string: "https://YOUR-PRIVACY-POLICY-URL.com")!
    
    private var legalFooter: some View {
        VStack(spacing: 6) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage and cancel your subscriptions in your App Store account settings after purchase.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
            
            HStack(spacing: 12) {
                Link("Terms of Use (EULA)", destination: Self.termsURL)
                Text("•").foregroundStyle(.white.opacity(0.15))
                Link("Privacy Policy", destination: Self.privacyURL)
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.35))
        }
    }
}
