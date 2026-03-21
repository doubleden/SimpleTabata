//
//  HapticService.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import UIKit

final class HapticService {
    static let shared = HapticService()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {}
    
    /// Short vibration / tap (buttons, ticks).
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light: generator = impactLight
        case .medium: generator = impactMedium
        case .heavy: generator = impactHeavy
        case .soft:
            generator = UIImpactFeedbackGenerator(style: .soft)
        case .rigid:
            generator = UIImpactFeedbackGenerator(style: .rigid)
        @unknown default:
            generator = impactMedium
        }
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Stronger feedback for events (phase change, timer end, errors).
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.prepare()
        notification.notificationOccurred(type)
    }
    
    /// Light click when switching values (pickers, segments).
    func selectionChanged() {
        selection.prepare()
        selection.selectionChanged()
    }
}
