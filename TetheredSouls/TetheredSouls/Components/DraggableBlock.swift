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
    
    private let projectionCoordinator = GridProjectionCoordinator.shared
    
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
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            // First check if we're in the correct gesture mode
                            if currentGestureMode == .blockDragging {
                                self.isDragging = true
                                self.didCancelDrag = false
                                
                                // Update the shared game state manager's dragging state
                                GameStateManager.shared.isDragging = true
                                
                                // CRITICAL - Also update DirectCatEyeControl dragging state
                                DirectCatEyeControl.shared.isDragging = true
                                
                                // CRITICAL - Remove throttling for position updates to cat eyes
                                // Ensure immediate response by updating every frame
                                self.lastUpdateTime = Date()
                                
                                if dragStart == nil {
                                    dragStart = value.startLocation
                                }
                                
                                self.dragOffset = value.translation
                                
                                // Use the location from global space
                                self.blockPosition = value.location
                                
                                // DIRECT CAT EYE CONTROL: Directly force the cat to look down
                                // This bypasses all the notification system and state management complexity
                                let screenWidth = UIScreen.main.bounds.width
                                let leftZone = screenWidth * 0.4
                                let rightZone = screenWidth * 0.6
                                
                                // Update frame numbers to create more dramatic movement
                                let catEyeFrame: Int
                                if value.location.x < leftZone {
                                    catEyeFrame = 20 // Look RIGHT when dragging on LEFT side
                                } else if value.location.x > rightZone {
                                    catEyeFrame = 5 // Look LEFT when dragging on RIGHT side
                                } else {
                                    catEyeFrame = 2 // Keep center-down the same
                                }
                                
                                // MOST CRITICAL CHANGE: Directly set eye frame via static controller
                                DirectCatEyeControl.shared.currentEyeFrame = catEyeFrame
                                
                                #if DEBUG
                                print("🔴 DIRECT CAT EYE CONTROL: \(catEyeFrame)")
                                print("🧩 SETTING DIRECT CAT EYE CONTROL")
                                print("  - isDragging = \(DirectCatEyeControl.shared.isDragging)")
                                print("  - currentEyeFrame = \(DirectCatEyeControl.shared.currentEyeFrame)")
                                #endif
                                
                                // Directly set the cat's eye frame in all CatFeatures instances
                                NotificationCenter.default.post(
                                    name: .init("ForceCatEyeFrame"),
                                    object: nil,
                                    userInfo: ["frame": catEyeFrame, "isDragging": true]
                                )
                                
                                // Update cat eye position during drag without triggering hearts
                                // Make sure to use the GLOBAL coordinates since we're passing them directly
                                GridTouchCoordinator.shared.touchLocation = value.location
                                
                                // CRITICAL: Force update the global game state again for redundancy
                                GameStateManager.shared.isDragging = true
                                
                                // CRITICAL: Trigger notification for cat to spectate the block
                                // Include the exact position in the notification - ALWAYS use global coordinates
                                NotificationCenter.default.post(
                                    name: .init("BlockDragging"),
                                    object: nil,
                                    userInfo: ["position": value.location]
                                )
                                
                                // Ensure we wake the cat but don't change gesture mode
                                NotificationCenter.default.post(name: .resetIdleTimer, object: nil)
                                
                                // Debug every frame to track dragging
                                #if DEBUG
                                print("🧩 BLOCK DRAGGING ACTIVE at: \(Int(value.location.x)), \(Int(value.location.y))")
                                print("🧩 GameStateManager.isDragging = \(GameStateManager.shared.isDragging)")
                                #endif
                                
                                // Calculate grid projection coordinates
                                calculateGridProjection(at: value.location)
                            }
                        }
                        .onEnded { value in
                            // Only process drag end if in correct mode
                            if currentGestureMode == .blockDragging {
                                // Reset eye position when drag ends
                                // Delay resetting touchLocation to give the cat time to follow placement
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    GridTouchCoordinator.shared.touchLocation = nil
                                }
                                
                                // Update the shared game state manager's dragging state
                                self.gameStateManager.isDragging = false
                                
                                // CRITICAL - Also update DirectCatEyeControl dragging state
                                DirectCatEyeControl.shared.isDragging = false
                                
                                // Reset cat's eye frame to default position
                                NotificationCenter.default.post(
                                    name: .init("ForceCatEyeFrame"),
                                    object: nil,
                                    userInfo: ["frame": 13, "isDragging": false]
                                )
                                
                                // Post notification that block dragging ended for cat to reset
                                NotificationCenter.default.post(
                                    name: .init("BlockDraggingEnded"),
                                    object: nil
                                )
                                
                                // Attempt to place the block
                                handleDragEnded(at: value.location)
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
        guard let block = selectedBlock else { return }
        
        #if DEBUG
        print("DraggableBlock - Position: \(position)")
        print("DraggableBlock - Grid frame in coordinator: \(projectionCoordinator.gridFrame)")
        #endif
        
        // Use coordinator to get grid cell 
        guard let (row, col) = projectionCoordinator.calculateGridCell(at: position) else {
            // Position is outside the grid
            projectionCoordinator.projectedCells = []
            return
        }
        
        // Create array of affected cells based on block shape
        var projectedCells: [(row: Int, column: Int)] = []
        
        for blockRow in 0..<block.shape.count {
            for blockCol in 0..<block.shape[blockRow].count {
                if block.shape[blockRow][blockCol] {
                    let gridRow = row + blockRow
                    let gridCol = col + blockCol
                    
                    // Only add cells that are within grid bounds
                    if gridRow >= 0 && gridRow < 10 && gridCol >= 0 && gridCol < 10 {
                        projectedCells.append((row: gridRow, column: gridCol))
                    }
                }
            }
        }
        
        #if DEBUG
        if !projectedCells.isEmpty {
            print("Projected cells: \(projectedCells)")
        }
        #endif
        
        // Update the shared projection coordinator
        projectionCoordinator.projectedCells = projectedCells
    }
    
    private func handleDragCancelled() {
        #if DEBUG
        print("DraggableBlock - Drag cancelled")
        #endif
        
        // Mark as cancelled so we know it wasn't a normal drag end
        didCancelDrag = true
        
        // Clear the projection
        projectionCoordinator.projectedCells = []
        
        // Ensure game state is updated
        gameStateManager.isDragging = false
        
        // CRITICAL - Also update DirectCatEyeControl dragging state
        DirectCatEyeControl.shared.isDragging = false
        
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
    
    private func handleDragEnded(at position: CGPoint) {
        #if DEBUG
        print("DraggableBlock - Drag ended, resetting isDragging state")
        #endif
        
        // Don't do anything if we've already cancelled
        if didCancelDrag {
            return
        }
        
        // First clear the projection to avoid state conflict
        projectionCoordinator.projectedCells = []
        
        // Keep the final touch location active for a moment for eye tracking
        // This ensures the cat looks where the block was placed
        let finalLocation = position
        
        // Tell the cat to end dragging with the final position
        if let blockPos = blockPosition {
            // First reset to looking straight down to ensure smoother transition
            NotificationCenter.default.post(
                name: .init("BlockDraggingEnded"),
                object: nil,
                userInfo: ["finalPosition": blockPos]
            )
        }
        
        // Use controlled main thread updates to avoid animation conflicts
        DispatchQueue.main.async {
            // Reset in a specific order to avoid animation timing issues
            self.dragOffset = .zero
            self.dragStart = nil
            
            // Animate position to nil with a controlled animation
            withAnimation(.easeOut(duration: 0.1)) {
                self.blockPosition = nil
            }
            
            // Delay the isDragging state change slightly to ensure animations complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.isDragging = false
            }
            
            // Keep the touch location for a short while after drag ends
            // This ensures the cat eyes continue to track where the block was placed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Only reset if this was the last touch at this location
                if GridTouchCoordinator.shared.touchLocation == finalLocation {
                    GridTouchCoordinator.shared.touchLocation = nil
                }
            }
        }
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
