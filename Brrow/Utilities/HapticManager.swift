import UIKit

/// Manager for handling haptic feedback
class HapticManager {
    
    /// Trigger impact feedback
    /// - Parameter style: The impact style (light, medium, heavy, soft, rigid)
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger notification feedback
    /// - Parameter type: The notification type (success, warning, error)
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Trigger selection feedback
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}