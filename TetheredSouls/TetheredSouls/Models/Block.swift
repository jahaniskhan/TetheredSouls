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
    
    var color: Color {
        switch self {
        case .softCoral:   return Theme.block1
        case .mutedPink:   return Theme.block2
        case .warmBeige:   return Theme.block3
        case .dustyRose:   return Theme.block4
        case .sageGreen:   return Theme.block5
        case .paleYellow:  return Theme.block3
        case .lightGray:   return Theme.quaternary
        }
    }
}

struct Block: Identifiable, Equatable {
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
    
    static let blocks: [Block] = [
        Block(
            shape: [[true]],
            color: .softCoral,
            symbol: "square"
        ),
    ]
    
    private static func generateRotations(_ shape: [[Bool]]) -> [[[Bool]]] {
        return [shape]
    }
} 