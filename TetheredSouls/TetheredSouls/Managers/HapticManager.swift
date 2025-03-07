import UIKit

class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    static func triggerPlacementFeedback() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
    
    static func triggerDragFeedback() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
} 