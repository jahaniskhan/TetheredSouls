enum DoodleType: String, CaseIterable {
    case star = "star.fill"
    case heart = "heart.fill"
    case semicolon = ";"
    case moon = "moon.fill"
    case swirl = "circle.lefthalf.filled"
    case xSmile = "custom.xsmile"
    case sparkle = "sparkles"
    case twentyEight = "28"
    
    var systemName: String {
        switch self {
        case .xSmile:
            return ""
        case .semicolon:
            return ""
        case .twentyEight:
            return ""
        default:
            return self.rawValue
        }
    }
    
    var rotationRange: ClosedRange<Double> {
        switch self {
        case .swirl: return -180...180
        case .sparkle: return 0...360
        case .semicolon: return -30...30
        case .xSmile: return -15...15
        case .twentyEight: return -10...10
        default: return -25...25
        }
    }
    
    // Animation properties for each doodle type
    var animationSpeed: Double {
        switch self {
        case .sparkle: return 1.1
        case .swirl: return 0.9
        case .twentyEight: return 0.7
        case .heart: return 0.85
        default: return 1.0
        }
    }
    
    var movementAmplitude: Double {
        switch self {
        case .sparkle: return 1.2
        case .twentyEight: return 0.8
        case .heart: return 1.1
        default: return 1.0
        }
    }
    
    // Add a new property to control how many doodles of each type appear
    var frequencyWeight: Int {
        switch self {
        case .twentyEight: return 4 // Higher weight means more common
        case .star, .sparkle: return 2
        default: return 1
        }
    }
} 