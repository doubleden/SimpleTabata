//
//  OnBoardingView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 26/3/26.
//

import SwiftUI

struct OnBoardingView: View {
    @Binding var isPresented: Bool
    @State private var page = 0
    @State private var isPaywallPresented = false
    
    var body: some View {
        ZStack {
            background
            
            VStack(spacing: 18) {
                TabView(selection: $page) {
                    WelcomePage()
                        .tag(0)
                    ProBenefitsPage()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                if page < 2 {
                    onboardingCTA
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                }
            }
        }
        .fullScreenCover(isPresented: $isPaywallPresented, onDismiss: {
            isPresented.toggle()
        }) {
            PayWallView(closeButtonStyle: .later)
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
    
    var onboardingCTA: some View {
        VStack(spacing: 10) {
            Button {
                HapticService.shared.selectionChanged()
                withAnimation(.easeInOut(duration: 0.25)) {
                    if page < 1 {
                        page += 1
                    } else {
                        isPaywallPresented.toggle()
                    }
                }
            } label: {
                Text(page == 1 ? "See Pro" : "Continue")
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
            
        }
    }
}

// MARK: - Pages

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 10)
            
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
            Spacer(minLength: 10)
            
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
