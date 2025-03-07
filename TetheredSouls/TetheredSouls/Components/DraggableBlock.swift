import SwiftUI
import CoreGraphics
import Dispatch

extension CoordinateSpace {
    static let gameArea = CoordinateSpace.named("gameArea")
}

struct DraggableBlock: View {
    // MARK: - Configuration
    private enum Constants {
        static let blockSize: CGFloat = 60
        static let throttleInterval: DispatchTimeInterval = .milliseconds(16)
        static let returnAnimation = Animation.interactiveSpring(
            response: 0.3, 
            dampingFraction: 0.86
        )
    }
    
    // MARK: - Properties
    @Binding var selectedBlock: Block?
    @Binding var position: CGPoint?
    @Binding var isDragging: Bool
    @Binding var grid: [[Bool]]
    
    let block: Block
    @State private var initialPosition: CGPoint = .zero
    @State private var lastUpdateTime: DispatchTime?
    
    // MARK: - Gesture Handling
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged(handleDragChange)
            .onEnded(handleDragEnd)
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
        let now = DispatchTime.now()
        guard now > (lastUpdateTime ?? .now()) + Constants.throttleInterval else {
            return
        }
        
        // Get game area frame through geometry reader
        let gameAreaFrame = UIScreen.main.bounds  // Temporary until proper geometry is passed
        let globalLocation = value.location
        
        // Convert using screen bounds
        let convertedLocation = CGPoint(
            x: globalLocation.x - gameAreaFrame.origin.x,
            y: globalLocation.y - gameAreaFrame.origin.y
        )
        
        position = convertedLocation
        lastUpdateTime = now
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        let finalPosition = value.location
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isValidPlacement {
                let snappedPos = snapToGrid(finalPosition)
                position = snappedPos
                commitToGrid(position: snappedPos)
                GridTouchCoordinator.shared.isBlockActive = true
                
                // Immediately hide inventory block
                DispatchQueue.main.async {
                    self.selectedBlock = nil
                }
            } else {
                returnToInventory()
                GridTouchCoordinator.shared.isBlockActive = false
            }
        }
    }
    
    private func commitToGrid(position: CGPoint) {
        if isValidPlacement {
            // Add visual/audio feedback
            HapticManager.triggerPlacementFeedback()
            AudioManager.playSound(.blockSnap)
            
            NotificationCenter.default.post(
                name: .init("BlockPlaced"),
                object: nil,
                userInfo: [
                    "points": 100,
                    "position": position,  // Add placement location
                    "blockType": block.symbol  // Add block type
                ]
            )
            
            let globalPosition = geometryProxy.frame(in: .global).origin
            BackgroundEffectCoordinator.shared.animateEffects(for: block, at: globalPosition)
        }
        
        // Reset position before animation
        self.position = nil
        
        // Convert to global screen coordinates
        let globalPosition = CGPoint(
            x: position.x + UIScreen.main.bounds.width/2,  // Adjust based on your layout
            y: position.y + UIScreen.main.bounds.height/2
        )
        
        let (col, row) = convertToGridCoordinates(position)
        
        // Update grid state
        for (r, rowArray) in block.shape.enumerated() {
            for (c, cell) in rowArray.enumerated() {
                if cell {
                    let actualRow = row + r
                    let actualCol = col + c
                    if actualRow < grid.count && actualCol < grid[0].count {
                        grid[actualRow][actualCol] = true
                    }
                }
            }
        }
        
        // Trigger effects
        HapticManager.triggerPlacementFeedback()
        
        // Clear selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.selectedBlock = nil
            // Force UI update
            NotificationCenter.default.post(name: .init("BlockPlaced"), object: nil)
        }
    }
    
    private func snapToGrid(_ position: CGPoint) -> CGPoint {
        let cellSize = UIScreen.main.bounds.width / CGFloat(grid[0].count)
        return CGPoint(
            x: round(position.x / cellSize) * cellSize,
            y: round(position.y / cellSize) * cellSize
        )
    }
    
    private func returnToInventory() {
        guard let initialPos = GridTouchCoordinator.shared.touchLocation else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            position = initialPos
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.position = nil
            self.selectedBlock = nil
        }
    }
    
    // MARK: - Position Calculations
    private func calculateNewPosition(from value: DragGesture.Value) -> CGPoint {
        if initialPosition == .zero {
            initialPosition = GridTouchCoordinator.shared.touchLocation ?? value.location
        }
        
        return CGPoint(
            x: initialPosition.x + value.translation.width,
            y: initialPosition.y + value.translation.height
        )
    }
    
    private func calculateFinalPosition(from value: DragGesture.Value) -> CGPoint {
        CGPoint(
            x: initialPosition.x + value.translation.width,
            y: initialPosition.y + value.translation.height
        )
    }
    
    // MARK: - Placement Logic
    private var isValidPlacement: Bool {
        guard let position = position else { return false }
        let (column, row) = convertToGridCoordinates(position)
        return canPlaceBlock(at: row, column: column)
    }
    
    private func commitPosition(_ position: CGPoint) {
        GridTouchCoordinator.shared.currentPosition = position
    }
    
    // MARK: - Grid Calculations
    private func convertToGridCoordinates(_ position: CGPoint) -> (Int, Int) {
        let cellSize = UIScreen.main.bounds.width / CGFloat(grid[0].count)
        return (
            Int((position.x / cellSize).rounded(.down)),
            Int((position.y / cellSize).rounded(.down))
        )
    }
    
    private func canPlaceBlock(at row: Int, column: Int) -> Bool {
        // Implement your grid validation logic here
        return true // Placeholder
    }
    
    // MARK: - View Body
    var body: some View {
        ZStack {
            if let position = position {
                BlockPreview(block: block, isSelected: false)
                    .frame(width: Constants.blockSize, height: Constants.blockSize)
                    .position(position)
                    .highPriorityGesture(dragGesture)
                    .transaction { $0.animation = Constants.returnAnimation }
                    .onChange(of: position) { _, newValue in
                        GridTouchCoordinator.shared.currentPosition = newValue
                    }
            }
        }
        .onAppear(perform: initializePosition)
        .onDisappear(perform: resetPosition)
    }
    
    private func initializePosition() {
        initialPosition = GridTouchCoordinator.shared.touchLocation ?? .zero
        position = initialPosition
    }
    
    private func resetPosition() {
        position = nil
        initialPosition = .zero
    }
    
    // Add validation to position binding
    private var validatedPosition: CGPoint {
        guard let pos = position, pos.x.isFinite, pos.y.isFinite else {
            return initialPosition
        }
        return pos
    }
}

// MARK: - Preview
struct DraggableBlock_Previews: PreviewProvider {
    static var previews: some View {
        DraggableBlock(
            selectedBlock: .constant(nil),
            position: .constant(CGPoint(x: 100, y: 100)),
            isDragging: .constant(false),
            grid: .constant(Array(repeating: Array(repeating: false, count: 10), count: 10)),
            block: Block(
                shape: [[true]],
                color: .softCoral,
                symbol: "square"
            )
        )
    }
}

// Add clamping extension for safety
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
