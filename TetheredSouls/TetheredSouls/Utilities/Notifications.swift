import Foundation

extension Notification.Name {
    /// Notification to reset the idle timer when user interacts with the cat's eyes
    /// This manifests in the NotionFace component when:
    /// 1. The cat's eyes follow touch movements
    /// 2. The user taps or drags on the cat's face
    /// 3. The cat wakes up from sleep state
    static let resetIdleTimer = Notification.Name("resetIdleTimer")
}