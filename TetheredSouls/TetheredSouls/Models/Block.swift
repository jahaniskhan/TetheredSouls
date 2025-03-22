import SwiftUI
import Foundation

enum BlockColor: String, CaseIterable {
    case softCoral
    case mutedPink
    case warmBeige
    case dustyRose
    case sageGreen
    case paleYellow
    case lightGray
    case paleBlue
    case lightTeal
    case goldenYellow
    case lavender
    case deepTeal
    
    var color: Color {
        switch self {
        case .softCoral:    return Theme.block1
        case .mutedPink:    return Theme.block2
        case .warmBeige:    return Theme.block3
        case .dustyRose:    return Theme.block4
        case .sageGreen:    return Theme.block5
        case .paleYellow:   return Color(hex: "F8D56B")
        case .lightGray:    return Theme.quaternary
        case .paleBlue:     return Color(hex: "A0C8E0")
        case .lightTeal:    return Color(hex: "80CBC4")
        case .goldenYellow: return Color(hex: "FFD54F")
        case .lavender:     return Color(hex: "D1C4E9")
        case .deepTeal:     return Color(hex: "4DB6AC")
        }
    }
}

struct Block: Identifiable, Equatable, Hashable {
    let id: UUID
    let shape: [[Bool]]
    let color: BlockColor
    let rotationStates: [[[Bool]]]
    let symbol: String
    let randomRotation: Double
    
    init(id: UUID = UUID(), shape: [[Bool]], color: BlockColor, symbol: String) {
        self.id = id
        self.shape = shape
        self.color = color
        self.symbol = symbol
        self.rotationStates = Block.generateRotations(shape)
        self.randomRotation = Double.random(in: -12...12) // More noticeable tilt
    }
    
    static let blocks: [Block] = [
        // Basic Blocks
        Block(shape: [[true]], color: .softCoral, symbol: "square"), // 1x1
        Block(shape: [[true, true], [true, true]], color: .mutedPink, symbol: "square.fill.on.square"), // 2x2
        Block(shape: [[true], [true], [true]], color: .sageGreen, symbol: "line.vertical"), // 3x1 Vertical
        Block(shape: [[true, false, false], 
                     [true, false, false], 
                     [true, true, true]], color: .warmBeige, symbol: "l.square"), // L-shape
        
        // Intermediate Blocks
        Block(shape: [[true, true, true], 
                     [false, true, false], 
                     [false, true, false]], color: .dustyRose, symbol: "t.square"), // T-shape
        Block(shape: [[true, true, true, true]], color: .paleBlue, symbol: "line.horizontal"), // 4x1 Horizontal
        Block(shape: [[true, true, false], 
                     [false, true, true]], color: .lightTeal, symbol: "z.square"), // Z-shape
        
        // Special Blocks
        Block(shape: [[true, false, true], 
                     [true, true, true], 
                     [true, false, true]], color: .goldenYellow, symbol: "u.square"), // U-shape
        Block(shape: [[false, true, false], 
                     [true, true, true], 
                     [false, true, false]], color: .lavender, symbol: "plus"), // Cross
        Block(shape: [[false, true, true, false], 
                     [true, true, true, true], 
                     [true, true, true, true], 
                     [false, true, true, false]], color: .deepTeal, symbol: "diamond") // Diamond
    ]
    
    private static func generateRotations(_ shape: [[Bool]]) -> [[[Bool]]] {
        return [shape]
    }

    // Add a static method to create a random block
    static func createRandom() -> Block {
        return blocks.randomElement() ?? blocks[0]
    }
}

struct GameBlock: Identifiable {
    let id = UUID()
    let cells: [[Bool]] // Matrix representation
    let systemImageName: String  // Using SF Symbols as placeholders
    
    // Example blocks from screenshots:
    static let tShape = GameBlock(
        cells: [
            [true, true, true],
            [false, true, false]
        ],
        systemImageName: "square.fill"
    )
    
    static let lShape = GameBlock(
        cells: [
            [true, false],
            [true, false],
            [true, true]
        ],
        systemImageName: "triangle.fill"
    )
} 