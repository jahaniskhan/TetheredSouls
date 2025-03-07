import SwiftUI
import Foundation
extension Int {
    func clamped(to range: Range<Int>) -> Int {
        let lower = range.lowerBound
        let upper = range.upperBound - 1
        return Swift.min(Swift.max(self, lower), upper)
    }
} 
