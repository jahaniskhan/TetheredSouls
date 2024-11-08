import SwiftUI

struct Block: Identifiable {
    let id = UUID()
    let shape: [[Bool]]
    let color: BlockColor
    let rotationStates: [[[Bool]]]
    
    init(shape: [[Bool]], color: BlockColor) {
        self.shape = shape
        self.color = color
        self.rotationStates = Block.generateRotations(shape)
    }
    
    static func generateRotations(_ shape: [[Bool]]) -> [[[Bool]]] {
        var rotations: [[[Bool]]] = [shape]
        var current = shape
        
        // Generate 3 more rotations (90°, 180°, 270°)
        for _ in 1...3 {
            current = rotate90Degrees(current)
            rotations.append(current)
        }
        
        return rotations
    }
    
    static func rotate90Degrees(_ shape: [[Bool]]) -> [[Bool]] {
        let rows = shape.count
        let cols = shape[0].count
        var rotated = Array(repeating: Array(repeating: false, count: rows), count: cols)
        
        for i in 0..<rows {
            for j in 0..<cols {
                rotated[j][rows - 1 - i] = shape[i][j]
            }
        }
        
        return rotated
    }
    
    static let blocks: [Block] = [
        // 1x1 Single
        Block(shape: [[true]], color: .neonCyan),
        
        // 2x2 Square
        Block(shape: [
            [true, true],
            [true, true]
        ], color: .plasmaOrange),
        
        // 1x3 Line
        Block(shape: [[true, true, true]], color: .digitalYellow),
        
        // 2x2 L-shape
        Block(shape: [
            [true, false],
            [true, true]
        ], color: .techPurple),
        
        // 3x3 Cross
        Block(shape: [
            [false, true, false],
            [true, true, true],
            [false, true, false]
        ], color: .signalRed),
        
        // 3x3 L-shape
        Block(shape: [
            [true, false, false],
            [true, false, false],
            [true, true, true]
        ], color: .synthBlue),
        
        // 3x2 T-shape
        Block(shape: [
            [true, true, true],
            [false, true, false]
        ], color: .matrixGreen),
        
        // 3x2 Zigzag
        Block(shape: [
            [true, true, false],
            [false, true, true]
        ], color: .neonCyan),
        
        // 1x4 Line
        Block(shape: [[true, true, true, true]], color: .plasmaOrange),
        
        // 3x3 Square
        Block(shape: [
            [true, true, true],
            [true, true, true],
            [true, true, true]
        ], color: .techPurple),
        
        // 3x3 Corner
        Block(shape: [
            [true, true, true],
            [true, false, false],
            [true, false, false]
        ], color: .plasmaOrange)
    ]
}

enum BlockColor {
    case neonCyan      // OP-1 display cyan
    case plasmaOrange  // OP-Z warning orange  
    case digitalYellow // PO status yellow
    case matrixGreen   // OP-1 terminal green
    case synthBlue     // TX-6 electric blue
    case techPurple    // Field purple
    case signalRed     // Alert red
    
    var color: Color {
        switch self {
        case .neonCyan:      return Color(red: 0.15, green: 0.85, blue: 0.78) // Deeper cyan
        case .plasmaOrange:  return Color(red: 0.98, green: 0.42, blue: 0.08) // Richer orange
        case .digitalYellow: return Color(red: 0.98, green: 0.88, blue: 0.12) // Warmer yellow
        case .matrixGreen:   return Color(red: 0.18, green: 0.92, blue: 0.45) // Deeper green
        case .synthBlue:     return Color(red: 0.28, green: 0.72, blue: 0.95) // Richer blue
        case .techPurple:    return Color(red: 0.65, green: 0.18, blue: 0.92) // Deeper purple
        case .signalRed:     return Color(red: 0.95, green: 0.18, blue: 0.18) // Richer red
        }
    }
}