import SwiftUI

enum Theme {
    // Colors from Haven by Marc Jacobs + TE aesthetic
    static let primary = Color.orange.opacity(0.9)
    static let background = Color(white: 0.05)
    static let surface = Color.black.opacity(0.6)
    static let stroke = Color.white.opacity(0.1)
    static let text = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    
    // Typography
    enum Typography {
        static let title = Font.system(size: 28, weight: .bold, design: .monospaced)
        static let score = Font.system(size: 20, weight: .medium, design: .monospaced)
        static let caption = Font.system(size: 14, weight: .medium, design: .monospaced)
    }
    
    // Layout
    enum Layout {
        static let spacing: CGFloat = 24
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let gridSpacing: CGFloat = 2
    }
} 
