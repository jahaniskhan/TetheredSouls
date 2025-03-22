import SwiftUI
import Foundation

// A singleton to control ALL doodle positions
class DoodlePositionManager: ObservableObject {
    static let shared = DoodlePositionManager()
    
    // Stores fixed positions for all doodles
    private var doodlePositions: [String: (position: CGPoint, offset: CGSize, rotation: Double)] = [:]
    
    // Flag to completely disable ANY position changes
    private var positionsLocked = true
    
    // Animation properties to improve fluidity
    private var animationProgress: CGFloat = 0.0
    
    // Timer for continuous subtle movements
    private var animationTimer: Timer?
    
    init() {
        // Start a timer for continuous subtle animations
        startAnimationTimer()
    }
    
    private func startAnimationTimer() {
        // Reduce timer frequency even further to decrease CPU usage
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.animationProgress += 0.01 // Half the increment to slow down motion
            
            // Only update a minimal number of doodles
            var updatedCount = 0
            for (id, _) in self.doodlePositions {
                // Only update at most 3 doodles per timer tick, and only at 20% probability
                if Int.random(in: 1...5) == 1 && id.contains("fluid") && updatedCount < 3 {
                    self.applySubtleMovement(to: id)
                    updatedCount += 1
                }
            }
        }
    }
    
    private func applySubtleMovement(to id: String) {
        guard var doodle = doodlePositions[id] else { return }
        
        // Reduce the movement amount even further for ultra-subtle motion
        let xDrift = sin(animationProgress + Double(id.hashValue)) * 0.5  // Reduced from 1.0
        let yDrift = cos(animationProgress * 0.8 + Double(id.hashValue)) * 0.5  // Reduced from 1.0
        
        doodle.offset = CGSize(
            width: doodle.offset.width + CGFloat(xDrift),
            height: doodle.offset.height + CGFloat(yDrift)
        )
        
        // Extremely subtle rotation
        doodle.rotation = doodle.rotation + sin(animationProgress * 0.5) * 0.1  // Reduced from 0.25
        
        doodlePositions[id] = doodle
    }
    
    // Optimize the updatePositionsForScoreChange method to reduce work
    func updatePositionsForScoreChange(newScore: Int) {
        // Temporarily unlock positions
        positionsLocked = false
        
        // Apply animations to fewer doodles
        DispatchQueue.main.async {
            // Get a smaller subset of positions to update (max 10)
            let keysToUpdate = Array(self.doodlePositions.keys.prefix(10))
            
            // Only update this subset with longer delays between
            for (index, id) in keysToUpdate.enumerated() {
                // Longer delay between updates to avoid CPU spikes
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.12) {
                    self.updateDoodlePosition(id: id, seedValue: Double(newScore))
                }
            }
        }
        
        // Re-lock positions after updates complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.positionsLocked = true
        }
    }
    
    private func updateDoodlePosition(id: String, seedValue: Double) {
        guard var doodle = doodlePositions[id] else { return }
        
        // Generate new offset with smaller distance for more subtle movements
        let angle = seedValue * 0.1 + Double(id.hashValue)
        let distance = 20.0 + sin(seedValue * 0.3) * 15.0 // Reduced from 50.0/30.0
        
        doodle.offset = CGSize(
            width: CGFloat(sin(angle) * distance),
            height: CGFloat(cos(angle) * distance)
        )
        
        // Smaller rotation
        doodle.rotation = sin(seedValue * 0.2 + Double(id.hashValue)) * 8.0 // Reduced from 15.0
        
        doodlePositions[id] = doodle
    }
    
    // Get a stable position for a doodle
    func getPosition(for id: String, defaultX: CGFloat, defaultY: CGFloat) -> CGPoint {
        let fluidId = id + ".fluid" // Mark as fluid for continuous animation
        
        if positionsLocked {
            // Return cached position if we have one
            if let position = doodlePositions[fluidId]?.position {
                return position
            }
            
            // Create and cache a new position
            let position = CGPoint(x: defaultX, y: defaultY)
            doodlePositions[fluidId] = (position: position, offset: .zero, rotation: 0)
            return position
        } else {
            // During the brief unlocked period, allow position updates
            let position = CGPoint(x: defaultX, y: defaultY)
            doodlePositions[fluidId] = (position: position, offset: .zero, rotation: 0)
            return position
        }
    }
    
    // Get a stable offset for a doodle
    func getOffset(for id: String, defaultOffset: CGSize) -> CGSize {
        let fluidId = id + ".fluid" // Mark as fluid for continuous animation
        
        if positionsLocked {
            // Return cached offset if we have one
            if let offset = doodlePositions[fluidId]?.offset {
                return offset
            }
            
            // Create and cache a new offset with slight randomization
            let jitterX = CGFloat.random(in: -5...5)
            let jitterY = CGFloat.random(in: -5...5)
            let offset = CGSize(
                width: defaultOffset.width + jitterX,
                height: defaultOffset.height + jitterY
            )
            
            doodlePositions[fluidId] = (position: .zero, offset: offset, rotation: Double.random(in: -5...5))
            return offset
        } else {
            // During the brief unlocked period, allow offset updates
            let offset = defaultOffset
            if var existing = doodlePositions[fluidId] {
                existing.offset = offset
                doodlePositions[fluidId] = existing
            } else {
                doodlePositions[fluidId] = (position: .zero, offset: offset, rotation: 0)
            }
            return offset
        }
    }
    
    // Get rotation for a doodle
    func getRotation(for id: String, defaultRotation: Double) -> Double {
        let fluidId = id + ".fluid" // Mark as fluid for continuous animation
        
        if let rotation = doodlePositions[fluidId]?.rotation {
            return rotation + defaultRotation
        }
        
        doodlePositions[fluidId] = (position: .zero, offset: .zero, rotation: 0)
        return defaultRotation
    }
} 