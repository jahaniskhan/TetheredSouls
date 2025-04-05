import SwiftUI
import Foundation

struct CellView: View {
    let isOccupied: Bool
    let row: Int
    let column: Int
    let selectedBlock: Block?
    let isPreview: Bool
    let blockColor: Color?
    @State private var showHeart = false
    @StateObject private var touchCoordinator = GridTouchCoordinator.shared
    
    // Add a state to track active heart particles with IDs
    @State private var activeHeartParticles: [UUID: Color] = [:]
    
    // Default initializer with optional blockColor
    init(isOccupied: Bool, row: Int, column: Int, selectedBlock: Block?, isPreview: Bool, blockColor: Color? = nil) {
        self.isOccupied = isOccupied
        self.row = row
        self.column = column
        self.selectedBlock = selectedBlock
        self.isPreview = isPreview
        self.blockColor = blockColor
    }
    
    private let colors: [Color] = [
        Theme.primary,
        Theme.secondary,
        Theme.tertiary,
        Theme.quaternary
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .overlay(
                        Rectangle()
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                
                // Show an overlay when cell is part of a projection
                if isPreview {
                    Rectangle()
                        .fill(previewColor)
                        .opacity(0.5)
                }
                
                // Display hearts with IDs
                ForEach(Array(activeHeartParticles.keys), id: \.self) { id in
                    if let color = activeHeartParticles[id] {
                        HeartParticle(color: color, id: id)
                            .position(CGPoint(x: geo.size.width/2, y: geo.size.height/2))
                            .onAppear {
                                // Remove the heart after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    activeHeartParticles.removeValue(forKey: id)
                                    if activeHeartParticles.isEmpty {
                                        showHeart = false
                                    }
                                }
                            }
                    }
                }
            }
            // Add tap gesture to create heart
            .onTapGesture(coordinateSpace: .global) { location in
                // Update touch coordinator when cell is tapped
                touchCoordinator.touchLocation = location
                
                // Create heart in the cell
                createHeart()
                
                // Reset touch location after a delay to allow eye movement to register
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    // Only reset if no new touches occurred
                    if touchCoordinator.touchLocation == location {
                        touchCoordinator.touchLocation = nil
                    }
                }
            }
            // Track drag gestures in the cell for eye movement
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        // Update cat eye tracking with current finger position
                        touchCoordinator.touchLocation = value.location
                    }
                    .onEnded { _ in
                        // Keep touch visible for a moment before resetting
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            touchCoordinator.touchLocation = nil
                        }
                    }
            )
        }
    }
    
    // New method to create a heart
    private func createHeart() {
        // Create multiple hearts for more impact
        for _ in 0..<3 {
            // Generate a unique ID for each heart
            let heartId = UUID()
            
            // Add this heart to the active particles with a random color
            activeHeartParticles[heartId] = colors.randomElement() ?? Theme.primary
        }
        
        // Ensure the showHeart flag is on
        if !showHeart {
            showHeart = true
        }
        
        // Provide more noticeable haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.7)
        
        // Inform the cat about interaction
        NotificationCenter.default.post(name: .resetIdleTimer, object: nil)
    }
    
    private var backgroundColor: Color {
        if isOccupied {
            // When a cell is occupied, we want to keep the block's color instead of the theme primary
            if isPreview {
                // For preview of current dragged block, use block color with transparency
                if let block = selectedBlock {
                    return block.color.color.opacity(0.3)
                } else {
                    return Color.white.opacity(0.3)
                }
            } else {
                // For permanently placed cells, use the passed blockColor or a light pink default
                return blockColor?.opacity(0.7) ?? Theme.block1.opacity(0.7)
            }
        } else {
            return Color.white.opacity(0.05)
        }
    }
    
    private var previewColor: Color {
        guard let block = selectedBlock else { return .clear }
        return block.color.color
    }
}
