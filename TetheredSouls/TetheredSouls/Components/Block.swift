import SwiftUI

struct Block: Identifiable {
    let id = UUID()
    let shape: [[Bool]]
    let color: BlockColor
    let rotationStates: [[[Bool]]]
    let symbol: String
    
    init(shape: [[Bool]], color: BlockColor, symbol: String) {
        self.shape = shape
        self.color = color
        self.symbol = symbol
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
        Block(shape: [[true]], color: .softCoral, symbol: "■"),
        
        // 2x2 Square
        Block(shape: [
            [true, true],
            [true, true]
        ], color: .mutedPink, symbol: "■"),
        
        // 1x3 Line
        Block(shape: [[true, true, true]], color: .warmBeige, symbol: "■"),
        
        // 2x2 L-shape
        Block(shape: [
            [true, false],
            [true, true]
        ], color: .dustyRose, symbol: "■"),
        
        // 3x3 Cross
        Block(shape: [
            [false, true, false],
            [true, true, true],
            [false, true, false]
        ], color: .sageGreen, symbol: "■"),
        
        // 3x3 L-shape
        Block(shape: [
            [true, false, false],
            [true, false, false],
            [true, true, true]
        ], color: .paleYellow, symbol: "■"),
        
        // 3x2 T-shape
        Block(shape: [
            [true, true, true],
            [false, true, false]
        ], color: .lightGray, symbol: "■"),
        
        // 3x2 Zigzag
        Block(shape: [
            [true, true, false],
            [false, true, true]
        ], color: .softCoral, symbol: "■"),
        
        // 1x4 Line
        Block(shape: [[true, true, true, true]], color: .mutedPink, symbol: "■"),
        
        // 3x3 Square
        Block(shape: [
            [true, true, true],
            [true, true, true],
            [true, true, true]
        ], color: .dustyRose, symbol: "■"),
        
        // 3x3 Corner
        Block(shape: [
            [true, true, true],
            [true, false, false],
            [true, false, false]
        ], color: .mutedPink, symbol: "■")
    ]
}

enum BlockColor {
    case softCoral
    case mutedPink
    case warmBeige
    case dustyRose
    case sageGreen
    case paleYellow
    case lightGray
    
    var color: Color {
        switch self {
        case .softCoral:   return Theme.block1    // Soft beige
        case .mutedPink:   return Theme.block2    // Sage green
        case .warmBeige:   return Theme.block3    // Muted yellow
        case .dustyRose:   return Theme.block4    // Dusty rose
        case .sageGreen:   return Theme.block5    // Soft blue
        case .paleYellow:  return Theme.block3    // Use solid muted yellow
        case .lightGray:   return Theme.quaternary // Use solid light gray
        }
    }
}