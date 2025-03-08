import SwiftUI
import Combine

class GameStateManager: ObservableObject {
    static let shared = GameStateManager()
    
    // Add missing physics properties
    private var lastUpdateTime: Date?
    private var velocity: CGVector = .zero
    
    // Remove all background queues
    @Published var selectedBlock: Block? = nil
    @Published var blockPosition: CGPoint? = nil
    @Published var isDragging = false
    @Published var grid = Array(repeating: Array(repeating: false, count: 10), count: 10)
    @Published var score = 0
    @Published var currentStreak = 0
    @Published var blockFrames: [UUID: CGRect] = [:]
    @Published var inventoryFrame: CGRect = .zero
    
    // Computed property for block initial position
    var blockInitialPosition: CGPoint? {
        guard let block = selectedBlock,
              let frame = blockFrames[block.id] else { return nil }
        return CGPoint(x: frame.midX, y: frame.midY)
    }
    
    // Add available blocks array
    @Published var availableBlocks: [Block] = [
        Block(shape: [[true]], color: .softCoral, symbol: "square"),
        Block(shape: [[true, true]], color: .sageGreen, symbol: "rectangle"),
        // Add other initial blocks...
    ]
    
    // Remove physics queue
    func updateBlockPhysics(position: CGPoint, velocity: CGVector) {
        DispatchQueue.main.async {
            let currentTime = Date()
            let deltaTime = self.lastUpdateTime.map { currentTime.timeIntervalSince($0) } ?? 0.016
            
            // Preserve spring calculations
            let springStiffness: CGFloat = 0.3
            let displacement = CGVector(
                dx: (self.blockInitialPosition?.x ?? position.x) - position.x,
                dy: (self.blockInitialPosition?.y ?? position.y) - position.y
            )
            
            let springForce = CGVector(
                dx: displacement.dx * springStiffness,
                dy: displacement.dy * springStiffness
            )
            
            let newVelocity = CGVector(
                dx: (velocity.dx + springForce.dx) * 0.92,
                dy: (velocity.dy + springForce.dy) * 0.92
            )
            
            let newPosition = CGPoint(
                x: position.x + newVelocity.dx * deltaTime,
                y: position.y + newVelocity.dy * deltaTime
            )
            
            withAnimation(.interactiveSpring()) {
                self.blockPosition = newPosition
            }
            
            self.velocity = newVelocity
            self.lastUpdateTime = currentTime
        }
    }
    
    func spawnBlock(at position: CGPoint) {
        let newBlock = Block(
            shape: [[true]], 
            color: .softCoral,
            symbol: "square"
        )
        
        DispatchQueue.main.async {
            self.availableBlocks.removeAll { $0.id == newBlock.id }
            self.selectedBlock = newBlock
            self.blockPosition = position
        }
        
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
            self.isDragging = true
        }
    }
    
    func spawnBlock(blockID: UUID) {
        guard let frame = blockFrames[blockID] else { return }
        
        DispatchQueue.main.async {
            self.blockPosition = CGPoint(
                x: frame.midX,
                y: frame.midY
            )
            self.availableBlocks.removeAll { $0.id == blockID }
        }
    }
} 