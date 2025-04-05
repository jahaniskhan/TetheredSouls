import Foundation
import SwiftUI

extension Notification.Name {
    static let didUpdateGrid = Notification.Name("didUpdateGrid")
    static let didSelectBlock = Notification.Name("didSelectBlock")
    static let didDeselectBlock = Notification.Name("didDeselectBlock")
    static let didClearRow = Notification.Name("didClearRow")
    static let didAttemptBlockPlacement = Notification.Name("didAttemptBlockPlacement")
    static let placementFailed = Notification.Name("placementFailed")
    static let placementSucceeded = Notification.Name("placementSucceeded")
} 