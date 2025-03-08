enum DoodleType: String, CaseIterable {
    case star = "star.fill"
    case heart = "heart.fill"
    case semicolon = "semicolon"
    case moon = "moon.fill"
    case swirl = "circle.lefthalf.filled"
    case xSmile = "x.squareroot"
    case sparkle = "sparkles"
    case puzzle = "puzzlepiece"
    
    var systemName: String {
        return self.rawValue
    }
    
    var rotationRange: ClosedRange<Double> {
        switch self {
        case .swirl: return -180...180
        case .sparkle: return 0...360
        default: return -25...25
        }
    }
} 