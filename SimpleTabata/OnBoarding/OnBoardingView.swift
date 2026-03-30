//
//  OnBoardingView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 26/3/26.
//

import SwiftUI
import StoreKit

fileprivate enum OnboardingTab: Int, Hashable, CaseIterable {
    case welcome = 0
    case proBenefits = 1
    case customColors = 2
    case savePresets = 3
    case extraPhases = 4
    case payWall = 5
}

// MARK: - Root

struct OnBoardingView: View {
    @Binding var isPresented: Bool
    @State private var tab: OnboardingTab = .welcome
    @State private var paywallVM = PayWallViewModel()

    private var isLastBeforePaywall: Bool { tab == .extraPhases }
    private var isPaywall: Bool { tab == .payWall }

    var body: some View {
        ZStack {
            background

            VStack {
                pageIndicator
                    .padding(.top, 8)
                Spacer()
            }
            
            VStack {
                TabView(selection: $tab) {
                    WelcomePage().tag(OnboardingTab.welcome)
                    ProBenefitsPage().tag(OnboardingTab.proBenefits)
                    CustomColorsPage().tag(OnboardingTab.customColors)
                    SavePresetsPage().tag(OnboardingTab.savePresets)
                    ExtraPhasesPage().tag(OnboardingTab.extraPhases)
                    OnBoardingPayWall(vm: paywallVM, isPresented: $isPresented)
                        .tag(OnboardingTab.payWall)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                onboardingCTA
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
            }

            if paywallVM.isPurchasing {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .overlay { ProgressView().controlSize(.large).tint(.white) }
            }
        }
        .task { await paywallVM.loadProducts() }
        .onChange(of: paywallVM.didPurchase) { _, ok in if ok { isPresented.toggle() } }
        .alert("Error", isPresented: .init(
            get: { paywallVM.errorMessage != nil },
            set: { if !$0 { paywallVM.errorMessage = nil } }
        )) {
            Button("OK") { paywallVM.errorMessage = nil }
        } message: { Text(paywallVM.errorMessage ?? "") }
    }
}

#Preview { OnBoardingView(isPresented: .constant(true)) }

// MARK: - Chrome

private extension OnBoardingView {
    var background: some View {
        LinearGradient(
            colors: [Color(red: 0.06, green: 0.06, blue: 0.12), Color(red: 0.02, green: 0.02, blue: 0.06)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            RadialGradient(colors: [Color.orange.opacity(0.18), .clear], center: .top, startRadius: 20, endRadius: 420)
                .ignoresSafeArea()
        }
    }

    var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingTab.allCases, id: \.rawValue) { t in
                Capsule()
                    .fill(t == tab ? Color.orange : Color.white.opacity(0.2))
                    .frame(width: t == tab ? 22 : 8, height: 6)
                    .animation(.spring(response: 0.3), value: tab)
            }
        }
    }

    var buttonTitle: String {
        switch tab {
        case .welcome: return "Get Started"
        case .proBenefits, .customColors, .savePresets: return "Continue"
        case .extraPhases: return "See Plans"
        case .payWall:
            let sel = paywallVM.products.first { $0.id == paywallVM.selectedProductID }
            if sel?.id == "tabata.lifetime" { return "Purchase" }
            if let s = sel, paywallVM.freeTrialLabel(for: s) != nil { return "Start free trial" }
            return "Purchase"
        }
    }

    var onboardingCTA: some View {
        Button {
            HapticService.shared.selectionChanged()
            if isPaywall {
                Task { await paywallVM.purchase() }
            } else if let next = OnboardingTab(rawValue: tab.rawValue + 1) {
                withAnimation(.easeInOut(duration: 0.25)) { tab = next }
            }
        } label: {
            Text(buttonTitle)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.orange, Color(red: 1, green: 0.35, blue: 0.1)], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .disabled(isPaywall && paywallVM.products.isEmpty)
    }
}

// MARK: - 1. Welcome

private struct WelcomePage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer(minLength: 14)
                ZStack {
                    Circle().fill(.white.opacity(0.06)).frame(width: 110, height: 110)
                        .overlay { Circle().strokeBorder(.white.opacity(0.10), lineWidth: 1) }
                    Image(systemName: "timer")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(spacing: 10) {
                    Text("Welcome to SimpleTabata")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white).multilineTextAlignment(.center).minimumScaleFactor(0.6)
                    Text("A simple Tabata timer — no ads, no clutter.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center).minimumScaleFactor(0.6)
                }.padding(.horizontal, 24)

                VStack(spacing: 12) {
                    bullet(icon: "bolt.fill", title: "Fast setup", sub: "Start a workout in seconds.")
                    bullet(icon: "speaker.wave.2.fill", title: "Sound cues", sub: "Beep countdown & phase transitions.")
                    bullet(icon: "iphone.gen3", title: "Works offline", sub: "No internet needed. Train anywhere.")
                }
                .padding(18)
                .background { onboardingCard }
                .padding(.horizontal, 24)

                Spacer(minLength: 80)
            }
        }
    }

    private func bullet(icon: String, title: String, sub: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.body.weight(.semibold)).foregroundStyle(.orange)
                .frame(width: 34, height: 34)
                .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).minimumScaleFactor(0.6)
                Text(sub).font(.caption).foregroundStyle(.white.opacity(0.55)).minimumScaleFactor(0.6)
            }
            Spacer()
        }
    }
}

// MARK: - 2. Pro Benefits Overview

private struct ProBenefitsPage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer(minLength: 14)
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white.opacity(0.06)).frame(width: 130, height: 90)
                        .overlay { RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.10), lineWidth: 1) }
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(spacing: 10) {
                    Text("Go Pro").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.white).minimumScaleFactor(0.6)
                    Text("Unlock everything to personalize your workouts.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center).minimumScaleFactor(0.6)
                }.padding(.horizontal, 24)

                VStack(spacing: 14) {
                    benefitRow(icon: "paintpalette.fill", color: .purple, title: "Custom colors", sub: "Color-code each phase for easy recognition.")
                    benefitRow(icon: "heart.fill", color: .pink, title: "Saved presets", sub: "Save different workouts for quick access.")
                    benefitRow(icon: "figure.cooldown", color: .yellow, title: "Extra phases", sub: "Prepare, Transition, Cycle Rest, Cooldown.")
                    benefitRow(icon: "bell.fill", color: .cyan, title: "Mid-work cue", sub: "A bell at the halfway point of each Work interval.")
                }
                .padding(20)
                .background { onboardingCard }
                .padding(.horizontal, 24)

                Text("Swipe to explore each feature →")
                    .font(.caption).foregroundStyle(.white.opacity(0.4)).minimumScaleFactor(0.6).padding(.top, 2)
                Spacer(minLength: 80)
            }
        }
    }

    private func benefitRow(icon: String, color: Color, title: String, sub: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.body.weight(.semibold)).foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).minimumScaleFactor(0.6)
                Text(sub).font(.caption).foregroundStyle(.white.opacity(0.55)).minimumScaleFactor(0.6)
            }
            Spacer()
            Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(.green)
        }
    }
}

// MARK: - 3. Custom Colors (interactive)

private struct CustomColorsPage: View {
    @State private var selectedPhase = 0
    @State private var colors: [Color] = [.green, .orange, .white, .cyan, .yellow, .purple]

    private let phaseNames = ["Prepare", "Work", "Transition", "Rest", "Cycle Rest", "Cooldown"]
    private let defaultTimes = ["00:10", "00:20", "00:05", "00:10", "01:00", "00:30"]
    private let palette: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .white, .mint]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer(minLength: 14)
                VStack(spacing: 10) {
                    Text("Custom Timer Colors")
                        .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(.white).minimumScaleFactor(0.6)
                    Text("Color-code each phase so you know where you are at a glance. Try it — tap a color below!")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center).minimumScaleFactor(0.6)
                }.padding(.horizontal, 24)

                timerPreview
                phaseSelector
                colorPalette

                Text("This is a demo — nothing is saved.")
                    .font(.caption2).foregroundStyle(.white.opacity(0.3)).minimumScaleFactor(0.6)
                Spacer(minLength: 80)
            }
        }
    }

    private var timerPreview: some View {
        VStack(spacing: 6) {
            Text(phaseNames[selectedPhase])
                .font(.caption.weight(.semibold))
                .foregroundStyle(colors[selectedPhase].opacity(0.8))
                .textCase(.uppercase)
                .minimumScaleFactor(0.6)
            Text(defaultTimes[selectedPhase])
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(colors[selectedPhase])
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: selectedPhase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.black.opacity(0.5))
                .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(colors[selectedPhase].opacity(0.3), lineWidth: 1) }
        }
        .padding(.horizontal, 24)
    }

    private var phaseSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<phaseNames.count, id: \.self) { i in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPhase = i }
                    } label: {
                        Text(phaseNames[i])
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(i == selectedPhase ? .black : .white.opacity(0.7))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(i == selectedPhase ? colors[i] : Color.white.opacity(0.08), in: Capsule())
                            .minimumScaleFactor(0.6)
                    }
                }
            }.padding(.horizontal, 24)
        }
    }

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick a color for \(phaseNames[selectedPhase])")
                .font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.5)).minimumScaleFactor(0.6)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(0..<palette.count, id: \.self) { i in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { colors[selectedPhase] = palette[i] }
                        HapticService.shared.selectionChanged()
                    } label: {
                        Circle().fill(palette[i]).frame(width: 36, height: 36)
                            .overlay {
                                if colors[selectedPhase] == palette[i] {
                                    Circle().strokeBorder(.white, lineWidth: 3)
                                }
                            }
                    }
                }
            }
        }
        .padding(20)
        .background { onboardingCard }
        .padding(.horizontal, 24)
    }
}

// MARK: - 4. Saved Presets

private struct SavePresetsPage: View {
    private let presets: [(name: String, icon: String, work: String, rest: String, sets: String)] = [
        ("Classic Tabata", "flame.fill", "20s", "10s", "8 sets"),
        ("Cycling Sprints", "bicycle", "30s", "15s", "6 sets"),
        ("Boxing Rounds", "figure.boxing", "45s", "20s", "10 sets"),
        ("Quick HIIT", "bolt.fill", "15s", "5s", "12 sets"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer(minLength: 14)
                VStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 36)).foregroundStyle(.pink)
                    Text("Save Your Presets")
                        .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(.white).minimumScaleFactor(0.6)
                    Text("Don't re-enter settings every time. Save different workouts and switch in one tap.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center).minimumScaleFactor(0.6)
                }.padding(.horizontal, 24)

                VStack(spacing: 10) {
                    ForEach(0..<presets.count, id: \.self) { i in
                        presetCard(presets[i])
                    }
                }
                .padding(.horizontal, 24)

                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill").font(.title2).foregroundStyle(.orange.opacity(0.6))
                    Text("One tap to load your plan — no typing needed.")
                        .font(.caption).foregroundStyle(.white.opacity(0.45)).multilineTextAlignment(.center).minimumScaleFactor(0.6)
                }.padding(.top, 4)

                Spacer(minLength: 80)
            }
        }
    }

    private func presetCard(_ p: (name: String, icon: String, work: String, rest: String, sets: String)) -> some View {
        HStack(spacing: 14) {
            Image(systemName: p.icon).font(.title3.weight(.semibold)).foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(p.name).font(.subheadline.weight(.semibold)).foregroundStyle(.white).minimumScaleFactor(0.6)
                HStack(spacing: 10) {
                    miniTag("Work \(p.work)")
                    miniTag("Rest \(p.rest)")
                    miniTag(p.sets)
                }
            }
            Spacer()
        }
        .padding(14)
        .background { onboardingCard }
    }

    private func miniTag(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.white.opacity(0.08), in: Capsule())
            .minimumScaleFactor(0.6)
    }
}

// MARK: - 5. Extra Phases + Mid‑work cue

private struct ExtraPhasesPage: View {
    private let phases: [(name: String, icon: String, color: Color, desc: String)] = [
        ("Prepare", "figure.cooldown", .green, "Warm up before the first set."),
        ("Work", "flame.fill", .orange, "High-intensity interval."),
        ("Mid-work bell", "bell.fill", .cyan, "A bell sounds at the halfway point — switch sides or exercises."),
        ("Transition", "figure.walk", .white, "Walk to the next station between work & rest."),
        ("Rest", "leaf.fill", .blue, "Recover between work rounds."),
        ("Cycle Rest", "pause.circle.fill", .purple, "Longer break between full cycles."),
        ("Cooldown", "wind", .yellow, "Stretch and cool down after all cycles."),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer(minLength: 14)
                VStack(spacing: 10) {
                    Image(systemName: "list.bullet.rectangle.fill")
                        .font(.system(size: 36)).foregroundStyle(.yellow)
                    Text("Advanced Phases")
                        .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(.white).minimumScaleFactor(0.6)
                    Text("Build a workout that fits your routine exactly. Add warm-up, transitions, and cooldowns.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center).minimumScaleFactor(0.6)
                }.padding(.horizontal, 24)

                phaseTimeline

                midWorkCueHighlight

                Spacer(minLength: 80)
            }
        }
    }

    private var phaseTimeline: some View {
        VStack(spacing: 0) {
            ForEach(0..<phases.count, id: \.self) { i in
                let p = phases[i]
                HStack(spacing: 14) {
                    VStack(spacing: 0) {
                        Circle().fill(p.color).frame(width: 10, height: 10)
                        if i < phases.count - 1 {
                            Rectangle().fill(p.color.opacity(0.3)).frame(width: 2, height: 34)
                        }
                    }.frame(width: 10)

                    Image(systemName: p.icon).font(.body.weight(.semibold)).foregroundStyle(p.color)
                        .frame(width: 30, height: 30)
                        .background(p.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name).font(.caption.weight(.semibold)).foregroundStyle(.white).minimumScaleFactor(0.6)
                        Text(p.desc).font(.caption2).foregroundStyle(.white.opacity(0.5)).minimumScaleFactor(0.6)
                    }
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding(20)
        .background { onboardingCard }
        .padding(.horizontal, 24)
    }

    private var midWorkCueHighlight: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "bell.fill").font(.title3).foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mid-work cue").font(.subheadline.weight(.semibold)).foregroundStyle(.white).minimumScaleFactor(0.6)
                    Text("Perfect for exercises with two sides: push-ups → switch to sit-ups at the bell. Works with any Work duration — even odd numbers (e.g. 11s → bell at 5.5s).")
                        .font(.caption).foregroundStyle(.white.opacity(0.55)).minimumScaleFactor(0.6)
                }
            }
        }
        .padding(16)
        .background { onboardingCard }
        .padding(.horizontal, 24)
    }
}

// MARK: - 6. Onboarding Paywall

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
            .padding(.top, 25)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "flame.circle.fill").font(.system(size: 54))
                .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("Unlock Pro").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(.white).minimumScaleFactor(0.6)
            Text("Choose a plan to personalize your workouts.").font(.subheadline)
                .foregroundStyle(.white.opacity(0.6)).multilineTextAlignment(.center).minimumScaleFactor(0.6)
        }
    }

    private var features: some View {
        VStack(spacing: 14) {
            featureRow(icon: "paintpalette.fill", color: .purple, text: "Custom timer colors")
            featureRow(icon: "heart.fill", color: .pink, text: "Save favorite workouts")
            featureRow(icon: "figure.cooldown", color: .yellow, text: "Extra phases")
            featureRow(icon: "bell.fill", color: .cyan, text: "Mid-work cue")
        }
        .padding(20)
        .background { onboardingCard }
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.body.weight(.semibold)).foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(text).font(.subheadline.weight(.medium)).foregroundStyle(.white).minimumScaleFactor(0.6)
            Spacer()
            Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(.green)
        }
    }

    private var planCards: some View {
        VStack(spacing: 10) {
            if vm.isLoading {
                ProgressView().tint(.white).frame(height: 80)
            } else {
                ForEach(vm.products, id: \.id) { product in planCard(product) }
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
            withAnimation(.easeInOut(duration: 0.2)) { vm.selectedProductID = product.id }
        } label: {
            planCardLabel(
                isSelected: isSelected, badge: badge, discount: discount,
                perMonth: perMonth, trial: trial, fakeOld: fakeOld,
                subtitle: subtitle, product: product
            )
        }
        .buttonStyle(.plain)
    }

    private func planCardLabel(
        isSelected: Bool, badge: String?, discount: String?,
        perMonth: String?, trial: String?, fakeOld: String?,
        subtitle: String, product: Product
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().strokeBorder(isSelected ? Color.orange : Color.white.opacity(0.25), lineWidth: 2).frame(width: 24, height: 24)
                    if isSelected { Circle().fill(Color.orange).frame(width: 14, height: 14) }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.periodLabel(for: product)).font(.subheadline.weight(.semibold)).foregroundStyle(.white).minimumScaleFactor(0.6)
                    HStack(spacing: 6) {
                        if let fakeOld {
                            Text(fakeOld).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.35))
                                .strikethrough(true, color: .white.opacity(0.35)).minimumScaleFactor(0.6)
                        }
                        Text(product.displayPrice).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85)).minimumScaleFactor(0.6)
                        if let discount {
                            Text(discount).font(.caption2.weight(.bold)).foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.green.opacity(0.85), in: Capsule())
                        }
                    }
                    if let perMonth { Text(perMonth).font(.caption2.weight(.semibold)).foregroundStyle(.orange).minimumScaleFactor(0.6) }
                    if let trial { Text(trial).font(.caption2.weight(.semibold)).foregroundStyle(.green).minimumScaleFactor(0.6) }
                    if !subtitle.isEmpty { Text(subtitle).font(.caption2).foregroundStyle(.white.opacity(0.4)).minimumScaleFactor(0.6) }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, badge != nil ? 8 : 16)
            .padding(.bottom, badge != nil ? 6 : 0)
        }
        .overlay(
            VStack {
                if let badge {
                    HStack {
                        Spacer()
                        Text(badge).font(.caption2.weight(.heavy)).textCase(.uppercase).foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(
                                product.id == "tabata.lifetime"
                                ? LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.orange, Color(red: 1, green: 0.35, blue: 0.1)], startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                    }.padding(.trailing, 12).padding(.top, 10).padding(.bottom, 4)
                }
                Spacer()
            }
        )
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.orange.opacity(0.12) : Color.white.opacity(0.05))
                .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(isSelected ? Color.orange.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1.5) }
        }
    }

    private var restoreButton: some View {
        Button { Task {
            await vm.restorePurchases()
        } } label: {
            Text("Restore purchases").font(.caption).foregroundStyle(.white.opacity(0.45)).minimumScaleFactor(0.6)
        }.buttonStyle(.bordered)
    }

    private var buyLaterButton: some View {
        Button { isPresented.toggle() } label: {
            Text("Maybe later").font(.callout).foregroundStyle(.white.opacity(0.45)).minimumScaleFactor(0.6)
        }.buttonStyle(.bordered)
    }

    private static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private static let privacyURL = URL(string: "https://YOUR-PRIVACY-POLICY-URL.com")!

    private var legalFooter: some View {
        VStack(spacing: 6) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage and cancel your subscriptions in your App Store account settings after purchase.")
                .font(.caption2).foregroundStyle(.white.opacity(0.25)).multilineTextAlignment(.center).minimumScaleFactor(0.6)
            HStack(spacing: 12) {
                Link("Terms of Use (EULA)", destination: Self.termsURL)
                Text("•").foregroundStyle(.white.opacity(0.15))
                Link("Privacy Policy", destination: Self.privacyURL)
            }.font(.caption2).foregroundStyle(.white.opacity(0.35))
        }
    }
}

// MARK: - Shared card style

private var onboardingCard: some View {
    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.06))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.08), lineWidth: 1) }
}
