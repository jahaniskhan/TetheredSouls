import Foundation

extension Notification.Name {
    /// Notification to reset the idle timer when user interacts with the cat's eyes
    /// This manifests in the NotionFace component when:
    /// 1. The cat's eyes follow touch movements
    /// 2. The user taps or drags on the cat's face
    /// 3. The cat wakes up from sleep state
    static let resetIdleTimer = Notification.Name("resetIdleTimer")
    
    /// Notification to generate heart particles at a specific location
    /// This is posted when:
    /// 1. The user taps directly on the cat face
    /// 2. When tapping on cells in the game board
    /// The notification includes location data in the userInfo dictionary
    static let generateHeartParticle = Notification.Name("generateHeartParticle")
    
    /// Notification sent when a block is successfully placed on the grid
    /// Includes position and block information in userInfo
    static let blockPlaced = Notification.Name("blockPlaced")
}