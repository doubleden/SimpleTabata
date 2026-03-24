//
//  TimerColorEditorView.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 24/3/26.
//

import SwiftUI

struct TimerColorEditorView: View {
    @Bindable var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: TimerPhaseColors
    @State private var selectedPage: Int = 0
    
    private let phases = TimerPhaseColorKey.allCases
    
    init(timerVM: TimerViewModel) {
        self.timerVM = timerVM
        _draft = State(initialValue: timerVM.phaseColors)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                timerPreview
                phasePager
                colorPickerSection
                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Timer colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { editorToolbar }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Timer preview
    
    private var timerPreview: some View {
        VStack(spacing: 8) {
            Text(phases[selectedPage].settingsTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            
            Text("00:29")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(currentDraftColor)
                .shadow(color: currentDraftColor.opacity(0.5), radius: 12)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .animation(.easeInOut(duration: 0.25), value: selectedPage)
    }
    
    // MARK: - Phase pager
    
    private var phasePager: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                    Button {
                        HapticService.shared.selectionChanged()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedPage = index
                        }
                    } label: {
                        Text(phase.settingsTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedPage == index ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background {
                                if selectedPage == index {
                                    Capsule()
                                        .fill(draftColor(for: phase).opacity(0.3))
                                        .overlay {
                                            Capsule()
                                                .strokeBorder(draftColor(for: phase).opacity(0.7), lineWidth: 1.5)
                                        }
                                } else {
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Color picker
    
    private var colorPickerSection: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.15))
            
            ColorPicker(
                "Phase color",
                selection: currentDraftBinding,
                supportsOpacity: false
            )
            .font(.body.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                HapticService.shared.impact()
                dismiss()
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Save") {
                HapticService.shared.impact()
                timerVM.phaseColors = draft
                timerVM.persistConfigurationToStorage()
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
    
    // MARK: - Draft helpers
    
    private var currentDraftColor: Color {
        draftColor(for: phases[selectedPage])
    }
    
    private func draftColor(for key: TimerPhaseColorKey) -> Color {
        switch key {
        case .prepare: draft.prepare.swiftUIColor
        case .work: draft.work.swiftUIColor
        case .workToRestTransition: draft.workToRestTransition.swiftUIColor
        case .rest: draft.rest.swiftUIColor
        case .pause: draft.pause.swiftUIColor
        case .cycleRest: draft.cycleRest.swiftUIColor
        case .cooldown: draft.cooldown.swiftUIColor
        }
    }
    
    private var currentDraftBinding: Binding<Color> {
        Binding(
            get: { currentDraftColor },
            set: { setDraftColor($0) }
        )
    }
    
    private func setDraftColor(_ color: Color) {
        let c = PhaseColorComponents(color)
        switch phases[selectedPage] {
        case .prepare: draft.prepare = c
        case .work: draft.work = c
        case .workToRestTransition: draft.workToRestTransition = c
        case .rest: draft.rest = c
        case .pause: draft.pause = c
        case .cycleRest: draft.cycleRest = c
        case .cooldown: draft.cooldown = c
        }
    }
}

#Preview {
    TimerColorEditorView(timerVM: TimerViewModel())
}
