import SwiftUI
import CoreGraphics
import Dispatch

// Keep the old controller for backward compatibility
class CatEyeController {
    static let shared = CatEyeController()
    
    // This value will be directly read by CatFeatures
    var currentEyeFrame: Int = 13
    var isDragging: Bool = false
}

extension CoordinateSpace {
    static let gameArea = CoordinateSpace.named("gameArea")
}

struct DraggableBlock: View {
    // MARK: - Configuration
    private enum Constants {
        static let throttleInterval: DispatchTimeInterval = .milliseconds(16)
        static let returnAnimation = Animation.interactiveSpring(
            response: 0.3, 
            dampingFraction: 0.86
        )
        static let blockSize: CGFloat = 60.0
    }
    
    // MARK: - Properties
    @Binding var selectedBlock: Block?
    @Binding var isDragging: Bool
    @Binding var blockPosition: CGPoint?
    @Binding var grid: [[Bool]]
    @Binding var projectedCells: [(row: Int, column: Int)]
    let block: Block
    let gridGeometry: GridGeometry
    
    @State private var dragOffset: CGSize = .zero
    @State private var dragStart: CGPoint?
    @State private var lastUpdateTime: Date = Date()
    @State private var didCancelDrag: Bool = false
    @State private var currentGestureMode: GestureMode = .blockDragging
    @StateObject private var gameStateManager = GameStateManager.shared
    @State private var isPreviewing: Bool = false
    
    // Initialize projectionCoordinator as a StateObject
    @StateObject private var projectionCoordinator = ProjectionCoordinator()
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            if let block = selectedBlock {
                ZStack {
                    ForEach(0..<block.shape.count, id: \.self) { rowIndex in
                        ForEach(0..<block.shape[rowIndex].count, id: \.self) { colIndex in
                            if block.shape[rowIndex][colIndex] {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(block.color.color)
                                    .frame(
                                        width: gridGeometry.cellSize - 2,
                                        height: gridGeometry.cellSize - 2
                                    )
                                    .offset(
                                        x: CGFloat(colIndex) * gridGeometry.cellSize,
                                        y: CGFloat(rowIndex) * gridGeometry.cellSize
                                    )
                            }
                        }
                    }
                }
                .opacity(0.8)
                .offset(dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            // Update drag state
                            if dragStart == nil {
                                dragStart = value.startLocation
                                isDragging = true
                                isPreviewing = true
                                
                                // Tell the state manager we're dragging
                                gameStateManager.isDragging = true
                            }
                            
                            // Calculate the offset
                            dragOffset = CGSize(
                                width: value.translation.width,
                                height: value.translation.height
                            )
                            
                            // Calculate current position
                            let currentPosition = CGPoint(
                                x: value.location.x,
                                y: value.location.y
                            )
                            
                            // Update block position 
                            blockPosition = currentPosition
                            
                            // Directly update the projection for simple grid placement
                            updateProjection(
                                at: currentPosition,
                                gridWidth: geometry.size.width,
                                gridHeight: geometry.size.height
                            )
                        }
                        .onEnded { value in
                            // Only process drag end if in correct mode
                            if currentGestureMode == .blockDragging {
                                // Reset eye position when drag ends
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    GridTouchCoordinator.shared.touchLocation = nil
                                }
                                
                                // Update the shared game state manager's dragging state
                                self.gameStateManager.isDragging = false
                                
                                // Reset cat's eye frame to default position
                                NotificationCenter.default.post(
                                    name: .init("ForceCatEyeFrame"),
                                    object: nil,
                                    userInfo: ["frame": 13, "isDragging": false]
                                )
                                
                                // Get final position for accurate placement
                                let finalPosition = value.location
                                
                                // Attempt to place the block
                                handleDragEnded(gridWidth: geometry.size.width, gridHeight: geometry.size.height)
                            }
                        }
                )
                .position(
                    x: blockPosition?.x ?? geometry.size.width / 2,
                    y: blockPosition?.y ?? geometry.size.height / 2
                )
                .zIndex(3)
                // Add listener for the GestureMode changes
                .onReceive(NotificationCenter.default.publisher(for: .init("GestureModeChanged"))) { notification in
                    if let mode = notification.object as? GestureMode {
                        currentGestureMode = mode
                        
                        // If switching to cat mode, cancel any ongoing drag
                        if mode == .catInteraction {
                            handleDragCancelled()
                        }
                    }
                }
                // Check for updated mode on a timer
                .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                    // Continuously check for updates to the global mode
                    if currentGestureMode != GestureMode.current {
                        currentGestureMode = GestureMode.current
                        
                        // If mode changed to cat interaction, cancel any drag
                        if currentGestureMode == .catInteraction && isDragging {
                            handleDragCancelled()
                        }
                    }
                }
                .onAppear {
                    // Set initial mode
                    currentGestureMode = GestureMode.current
                }
                .onReceive(NotificationCenter.default.publisher(for: .init("ForceDragReset"))) { _ in
                    handleDragCancelled()
                }
                .onReceive(NotificationCenter.default.publisher(for: .init("DragStateReset"))) { _ in
                    // Force reset dragOffset and local state to prevent UI artifacts
                    self.dragOffset = .zero
                    self.dragStart = nil
                    self.didCancelDrag = true
                }
                .onReceive(NotificationCenter.default.publisher(for: .init("FinalDragReset"))) { _ in
                    // Final cleanup pass
                    self.dragOffset = .zero
                    self.dragStart = nil
                    self.didCancelDrag = true
                }
            }
        }
        .id("draggableBlock-\(selectedBlock?.id.uuidString ?? "none")")
    }
    
    // MARK: - Methods
    private func calculateGridProjection(at position: CGPoint) {
        guard let block = selectedBlock else { 
            projectedCells = []
            return 
        }
        
        // Get the grid cell directly from the GridProjectionCoordinator
        guard let (baseRow, baseCol) = GridProjectionCoordinator.shared.calculateGridCell(at: position) else {
            projectedCells = []
            return
        }
        
        // Create array of affected cells based on block shape
        var newProjectedCells: [(row: Int, column: Int)] = []
        
        for (r, blockRow) in block.shape.enumerated() {
            for (c, isSet) in blockRow.enumerated() {
                if isSet {
                    let gridRow = baseRow + r
                    let gridCol = baseCol + c
                    
                    // Only add cells that are within grid bounds
                    if gridRow >= 0 && gridRow < GridView.rows && gridCol >= 0 && gridCol < GridView.columns {
                        newProjectedCells.append((row: gridRow, column: gridCol))
                    }
                }
            }
        }
        
        // Update the projected cells
        projectedCells = newProjectedCells
    }
    
    private func handleDragCancelled() {
        #if DEBUG
        print("DraggableBlock - Drag cancelled")
        #endif
        
        // Mark as cancelled so we know it wasn't a normal drag end
        didCancelDrag = true
        
        // Clear the projection
        projectedCells = []
        
        // Ensure game state is updated
        gameStateManager.isDragging = false
        
        // Reset cat's eye frame to default position
        NotificationCenter.default.post(
            name: .init("ForceCatEyeFrame"),
            object: nil,
            userInfo: ["frame": 13, "isDragging": false]
        )
        
        // Post notification that block dragging ended
        NotificationCenter.default.post(
            name: .init("BlockDraggingEnded"),
            object: nil
        )
        
        // Immediate cleanup with no animations to avoid conflicts
        dragOffset = .zero
        dragStart = nil
        blockPosition = nil
        
        // No need to set isDragging here as ContentView is handling it
    }
    
    private func handleDragEnded(gridWidth: CGFloat, gridHeight: CGFloat) {
        // Only attempt to place block if we have projected cells
        if let block = selectedBlock {
            // Get the grid position at the current location
            guard let blockPosition = blockPosition else {
                return
            }

            // Try to get the grid cell
            guard let (baseRow, baseCol) = GridProjectionCoordinator.shared.calculateGridCell(at: blockPosition) else {
                // Reset state and return if position is outside grid
                resetAfterPlacement()
                return
            }
            
            // Directly attempt placement
            NotificationCenter.default.post(
                name: Notification.Name.didAttemptBlockPlacement,
                object: nil,
                userInfo: [
                    "row": baseRow,
                    "column": baseCol,
                    "block": block
                ]
            )
        }
        
        // Always reset state
        resetAfterPlacement()
    }
    
    // Add a simple method to reset state after placement
    private func resetAfterPlacement() {
        // Reset all state immediately
        DispatchQueue.main.async {
            isDragging = false
            dragOffset = .zero
            dragStart = nil
            isPreviewing = false
            projectedCells = []
            
            // Force clear the projection state
            GridProjectionCoordinator.shared.projectedCells = []
        }
    }
    
    // Helper method to check if a block can be placed
    private func canPlaceBlockAt(row: Int, column: Int) -> Bool {
        guard let block = selectedBlock else { return false }
        
        // Only check the actual grid state and don't modify it
        let gridState = GameStateManager.shared.grid // Use GameStateManager's grid
        
        // Check if all cells required by the block can be placed
        for blockRow in 0..<block.shape.count {
            for blockCol in 0..<block.shape[blockRow].count {
                if block.shape[blockRow][blockCol] {
                    let gridRow = row + blockRow
                    let gridCol = column + blockCol
                    
                    // Check bounds
                    if gridRow < 0 || gridRow >= gridState.count || gridCol < 0 || gridCol >= gridState[0].count {
                        return false
                    }
                    
                    // Check if cell is already occupied - this is critical
                    if gridState[gridRow][gridCol] {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    // Add updateProjection method to properly update the projection with CGPoint
    private func updateProjection(at position: CGPoint, gridWidth: CGFloat, gridHeight: CGFloat) {
        // Calculate the projected cells based on the drag position
        calculateGridProjection(at: position)
        
        // Update block position for UI purposes
        blockPosition = position
        
        // Update touch location for cat eye tracking
        GridTouchCoordinator.shared.touchLocation = position
    }
}

// MARK: - Preview
struct DraggableBlock_Previews: PreviewProvider {
    static var previews: some View {
        DraggableBlock(
            selectedBlock: .constant(nil),
            isDragging: .constant(false),
            blockPosition: .constant(CGPoint(x: 100, y: 100)),
            grid: .constant(Array(repeating: Array(repeating: false, count: 10), count: 10)),
            projectedCells: .constant([]),
            block: Block(shape: [[true]], color: .softCoral, symbol: "square"),
            gridGeometry: GridGeometry(frame: .zero, cellSize: 30)
        )
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

class ProjectionCoordinator: ObservableObject {
    @Published var projectedCells: CGPoint? = nil
}
