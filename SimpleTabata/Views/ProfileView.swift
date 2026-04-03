//
//  ProfileView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 24/3/26.
//

import SwiftUI
import StoreKit

struct ProfileView: View {
    @Bindable var timerVM: TimerViewModel
    @Environment(\.openURL) private var openURL
    
    @State private var showClearDataAlert = false
    @State private var showColorEditor = false
    @State private var showPaywall = false
    @State private var showReviewFallback = false
    @State private var volumePreviewWorkItem: DispatchWorkItem?
    
    private let appStoreAppID = "6760946483"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                reviewCard
                timerColorsCard
                soundCard
                actionsCard
                appVersionFooter
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showColorEditor) {
            TimerColorEditorView(timerVM: timerVM)
        }
        .sheet(isPresented: $showPaywall) {
            PayWallView()
        }
        .alert("Clear all data?", isPresented: $showClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                HapticService.shared.impact(.heavy)
                timerVM.clearAllUserData()
            }
        } message: {
            Text("This will reset timer settings, colors, and favorites permanently.")
        }
    }
    
    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Support the app", systemImage: "star.bubble.fill")
                .font(.headline)
            Text("If you enjoy this app, please leave a short review in the App Store.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.6)
            Button {
                HapticService.shared.impact()
                showReviewFallback = true
            } label: {
                Label("Leave a review", systemImage: "square.and.pencil")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        }
        .confirmationDialog(
            "Review",
            isPresented: $showReviewFallback,
            titleVisibility: .hidden
        ) {
            Button("Open App Store review page") {
                guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreAppID)?action=write-review") else { return }
                openURL(url)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("If you enjoy this app, please leave a short review in the App Store.")
                .minimumScaleFactor(0.6)
        }
    }
    
    private var timerColorsCard: some View {
        Button {
            HapticService.shared.impact()
            if SubscriptionService.shared.isPro {
                showColorEditor = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "paintpalette.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.purple.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Timer colors")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Customize phase colors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                phaseColorDotsPreview
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private var phaseColorDotsPreview: some View {
        HStack(spacing: 4) {
            ForEach(TimerPhaseColorKey.allCases) { key in
                Circle()
                    .fill(timerVM.colorPickerBinding(for: key).wrappedValue)
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    private var soundCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sound", systemImage: "speaker.wave.2.fill")
                .font(.headline)
            
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                Slider(value: $timerVM.soundVolume, in: 0...1, step: 0.01)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }
            
            Text("\(Int((timerVM.soundVolume * 100).rounded()))%")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .minimumScaleFactor(0.6)
            
            Divider()
                .padding(.top, 4)
            
            Toggle(isOn: $timerVM.duckOtherAudio) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ducking other audio")
                        .font(.subheadline.weight(.medium))
                        .minimumScaleFactor(0.6)
                    Text("Temporarily lower music and other sounds while beeps play.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        }
        .onChange(of: timerVM.soundVolume) { _, newValue in
            AudioService.shared.setVolume(newValue)
            timerVM.persistConfigurationToStorage()
            
            volumePreviewWorkItem?.cancel()
            let work = DispatchWorkItem {
                AudioService.shared.playBeep()
            }
            volumePreviewWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
        }
        .onChange(of: timerVM.duckOtherAudio) { _, newValue in
            AudioService.shared.setDuckOtherAudio(newValue)
            timerVM.persistConfigurationToStorage()
            AudioService.shared.playBeep()
        }
    }
    
    private var actionsCard: some View {
        Button {
            showClearDataAlert = true
        } label: {
            rowLabel(title: "Clear data", systemImage: "trash")
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private var appVersionFooter: some View {
        Text("Version \(appVersionString)")
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }
    
    private var appVersionString: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return "\(short)"
    }
    
    private func rowLabel(title: String, systemImage: String) -> some View {
        HStack {
            Label(LocalizedStringResource(stringLiteral:title), systemImage: systemImage)
                .font(.body.weight(.medium))
                .minimumScaleFactor(0.6)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ProfileView(timerVM: TimerViewModel())
}
