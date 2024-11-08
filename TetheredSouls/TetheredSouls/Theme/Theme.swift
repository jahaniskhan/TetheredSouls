import SwiftUI

enum Theme {
    // TE display colors
    static let text = Color.white.opacity(0.95)  // Digital display text
    static let primary = Color(red: 0.92, green: 0.16, blue: 0.39)    // Pink
    static let secondary = Color(red: 0.996, green: 0.396, blue: 0.208)  // Orange
    static let tertiary = Color(red: 0.2, green: 0.6, blue: 1.0)   // Blue
    static let quaternary = Color(red: 0.996, green: 0.251, blue: 0.176)  // Red
    static let error = Color(red: 0.92, green: 0.25, blue: 0.2)     // Signal Red
    
    static let background = Color(red: 0.07, green: 0.07, blue: 0.07)  // Darker than black
    static let surface = Color(red: 0.12, green: 0.12, blue: 0.12)     // Dark panel
    static let stroke = Color.white.opacity(0.15)
    static let textSecondary = Color.white.opacity(0.4)
    
    enum Typography {
        static let display = Font.system(size: 32, weight: .medium, design: .monospaced)
        static let digital = Font.system(size: 24, weight: .medium, design: .monospaced)
        static let caption = Font.system(size: 12, weight: .medium, design: .monospaced)
    }
    
    enum Layout {
        static let spacing: CGFloat = 4
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 2
        static let gridSpacing: CGFloat = 1
        static let primary = Color("Primary")
        static let secondary = Color("Secondary")
        static let tertiary = Color("Tertiary")
        static let quaternary = Color("Quaternary")
        static let surface = Color("Surface")
        static let background = Color("Background")
        static let stroke = Color("Stroke")
        static let text = Color("Text")
        static let textSecondary = Color("TextSecondary")
        static let signalRed = Color(red: 0.92, green: 0.25, blue: 0.2)
    }
}