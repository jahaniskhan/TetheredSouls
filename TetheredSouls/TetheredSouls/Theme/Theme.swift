import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum Theme {
    // Base colors - paper-like, warm
    static let background = Color(hex: "F5E6D3")  // Warm paper beige
    static let primary = Color(hex: "E2C2B3")     // Soft dusty pink
    static let secondary = Color(hex: "BFD8B8")   // Sage green
    static let tertiary = Color(hex: "E5B25D")    // Muted mustard
    static let quaternary = Color(hex: "D4A5C9")  // Soft purple
    static let surface = Color.white              // Pure white
    static let stroke = Color.black.opacity(0.8)  // Soft black
    
    // Text colors
    static let textPrimary = Color.black.opacity(0.85)
    static let textSecondary = Color.black.opacity(0.7)
    static let textTertiary = Color.black.opacity(0.5)
    
    // Block colors - like colored pencil/marker
    static let block1 = Color(hex: "E8A598")  // Salmon pink
    static let block2 = Color(hex: "BFD8B8")  // Sage
    static let block3 = Color(hex: "E5B25D")  // Mustard
    static let block4 = Color(hex: "B4CCE1")  // Dusty blue
    static let block5 = Color(hex: "D4A5C9")  // Soft purple
    
    // Grid styling - like paper
    static let gridBackground = Color(hex: "F5E6D3")  // Same as background
    static let gridLine = Color(hex: "6B5B4E").opacity(0.2)  // Light pencil lines
    
    static let cellFill = Color(hex: "D8D8D8") // Light gray color for filled cells
    
    enum Layout {
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 20
        static let cornerRadius: CGFloat = 8  // Less rounded, more book-like
        static let gridSpacing: CGFloat = 1
    }
    
    enum Typography {
        static let title = Font.system(size: 24, weight: .medium)
        static let subtitle = Font.system(size: 18, weight: .regular)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 14, weight: .regular)
        static let small = Font.system(size: 12, weight: .regular)
    }
}