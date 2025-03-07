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
    
    // Add available blocks array
    @Published var availableBlocks: [Block] = [
        Block(shape: [[true]], color: .softCoral, symbol: "square"),
        Block(shape: [[true, true]], color: .blue, symbol: "rectangle"),
        // Add other initial blocks...
    ]
    
    // Remove physics queue
    func updateBlockPhysics(position: CGPoint, velocity: CGVector) {
        DispatchQueue.main.async {  // Handle physics on main thread
            let currentTime = Date()
            let deltaTime = self.lastUpdateTime.map { currentTime.timeIntervalSince($0) } ?? 0.016
            
            let damping: CGFloat = 0.92
            let springStiffness: CGFloat = 0.3
            
            let newPosition = CGPoint(
                x: position.x + velocity.dx * deltaTime,
                y: position.y + velocity.dy * deltaTime
            )
            
            let newVelocity = CGVector(
                dx: velocity.dx * damping,
                dy: velocity.dy * damping
            )
            
            withAnimation(.interpolatingSpring(stiffness: springStiffness, damping: 0.8)) {
                self.blockPosition = newPosition
            }
            self.velocity = newVelocity
            self.lastUpdateTime = currentTime
        }
    }
} 