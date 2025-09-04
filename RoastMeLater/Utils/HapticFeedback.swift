import UIKit

class HapticFeedback {
    static let shared = HapticFeedback()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard Constants.UI.hapticFeedbackEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard Constants.UI.hapticFeedbackEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        guard Constants.UI.hapticFeedbackEnabled else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // Convenience methods for common app actions
    func roastGenerated() {
        notification(.success)
    }
    
    func roastFavorited() {
        impact(.light)
    }
    
    func buttonTapped() {
        impact(.light)
    }
    
    func errorOccurred() {
        notification(.error)
    }
    
    func categorySelected() {
        selection()
    }
    
    func spiceLevelChanged() {
        impact(.light)
    }
}
