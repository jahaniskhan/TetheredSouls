import SwiftUI

struct BlockSelectionView: View {
    @Binding var availableBlocks: [Block]
    @Binding var selectedBlock: Block?
    @Binding var blockPosition: CGPoint?
    @Binding var isDragging: Bool
    @Binding var gridGeometry: GridGeometry
    
    // Track which block is being dragged
    @State private var draggedBlockId: UUID? = nil
    @State private var hoveredBlockId: UUID? = nil
    @State private var isExpanded = false
    @State private var heartBeat = false
    @State private var headerHover = false
    
    // Updated colors as requested
    private let headerBackground = Color(hex: "ACD1AF")  // Sage green banner
    private let panelBackground = Color.white            // White panel
    private let textColor = Color.white                  // White text for contrast
    private let borderColor = Color(hex: "ACD1AF")       // Sage green border
    
    // Add these new properties to the view
    @State private var replacementQueue: [Block] = []
    private let visibleBlockCount = 3 // Number of blocks shown at once
    @State private var usedBlocks: Set<UUID> = []
    
    // Add this property
    @Namespace private var namespace
    
    // Add state to track the current gesture mode
    @State private var currentGestureMode: GestureMode = .blockDragging
    
    // Add these new properties to track held blocks
    @State private var heldBlock: Block? = nil
    @State private var isHoldAreaActive: Bool = false
    
    init(
        availableBlocks: Binding<[Block]>,
        selectedBlock: Binding<Block?>,
        blockPosition: Binding<CGPoint?>,
        isDragging: Binding<Bool>,
        gridGeometry: Binding<GridGeometry>
    ) {
        _availableBlocks = availableBlocks
        _selectedBlock = selectedBlock
        _blockPosition = blockPosition
        _isDragging = isDragging
        _gridGeometry = gridGeometry
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Main content
            mainContentView
        }
        .background(
            // Make the white background expand to fill the entire available area
            // This ensures it grows with the panel when bigger blocks appear
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.97))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    // Add matchedGeometryEffect if you're using it elsewhere
                    // .matchedGeometryEffect(id: "background", in: namespace)
            }
            .padding(2) // Small padding to keep the white background inside the border
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(borderColor, lineWidth: 2)
                .opacity(0.9)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 8)
        .padding(.bottom, 60)
        .scaleEffect(isExpanded ? 1.0 : 0.95)
        .opacity(isExpanded ? 1.0 : 0.8)
        .coordinateSpace(name: "gameArea")
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            // Continuously check for updates to the global mode
            if currentGestureMode != GestureMode.current {
                currentGestureMode = GestureMode.current
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("GestureModeChanged"))) { notification in
            if let mode = notification.object as? GestureMode {
                currentGestureMode = mode
                
                // If switching to cat mode, clear any selections
                if mode == .catInteraction {
                    draggedBlockId = nil
                    hoveredBlockId = nil
                }
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if isDragging && selectedBlock != nil && blockPosition != nil {
                // Simply delegate to the controller - don't duplicate logic
                if let position = blockPosition {
                    DirectCatEyeControl.shared.updateForDragging(at: position)
                }
            }
        }
        .onAppear {
            // Set initial mode
            currentGestureMode = GestureMode.current
            
            if availableBlocks.isEmpty {
                generateInitialBlocks()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ForceDragReset"))) { _ in
            // Ensure we clear our internal drag state too
            withAnimation(.easeOut(duration: 0.1)) {
                draggedBlockId = nil
                hoveredBlockId = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("DragStateReset"))) { _ in
            // Secondary reset
            draggedBlockId = nil
            hoveredBlockId = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("FinalDragReset"))) { _ in
            // Final cleanup
            draggedBlockId = nil
            hoveredBlockId = nil
        }
    }
    
    private var mainContentView: some View {
        // Main container with overlay design
        ZStack(alignment: .topTrailing) {
            // Background panel - REMOVE the fixed height
            Rectangle()
                .fill(panelBackground)
                // Remove this fixed height constraint
                // .frame(height: 120)
            
            // Available blocks
            availableBlocksScrollView
            
            // Pin area
            pinAreaView
        }
    }
    
    private var availableBlocksScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(availableBlocks) { block in
                    blockItemWithLongPress(block)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    private func blockItemWithLongPress(_ block: Block) -> some View {
        BlockItemView(
            block: block,
            isSelected: selectedBlock?.id == block.id,
            isDragged: draggedBlockId == block.id,
            isHovered: hoveredBlockId == block.id,
            cellSize: gridGeometry.cellSize,
            gridGeometry: gridGeometry,
            gestureMode: currentGestureMode,
            onHoverChanged: { hovering in
                withAnimation(.spring(response: 0.3)) {
                    hoveredBlockId = hovering ? block.id : nil
                }
            },
            onDragChanged: { value in
                if currentGestureMode == .blockDragging {
                    handleDragChange(value: value, block: block)
                }
            },
            onDragEnded: { value in
                if currentGestureMode == .blockDragging {
                    handleDragEnd(value: value, block: block)
                }
            },
            namespace: namespace
        )
        .onLongPressGesture(minimumDuration: 0.5) {
            if heldBlock == nil {
                feedbackGenerator()
                withAnimation(.spring()) {
                    heldBlock = block
                    availableBlocks.removeAll { $0.id == block.id }
                    
                    // Add a replacement block
                    if let newBlock = Block.blocks.filter({ b in
                        !availableBlocks.contains(where: { $0.id == b.id })
                    }).randomElement() {
                        availableBlocks.append(newBlock)
                    }
                }
            }
        }
        .zIndex(draggedBlockId == block.id ? 3 : 0)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var pinAreaView: some View {
        VStack {
            if let block = heldBlock {
                // Show pinned block with reduced size
                ZStack {
                    // Add a subtle background for the pinned block
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    // Reduce the size of the block itself
                    BlockItemView(
                        block: block,
                        isSelected: selectedBlock?.id == block.id,
                        isDragged: draggedBlockId == block.id,
                        isHovered: hoveredBlockId == block.id,
                        cellSize: gridGeometry.cellSize * 0.7, // Scale down the cell size
                        gridGeometry: gridGeometry,
                        gestureMode: currentGestureMode,
                        onHoverChanged: { hovering in
                            withAnimation(.spring(response: 0.3)) {
                                hoveredBlockId = hovering ? block.id : nil
                            }
                        },
                        onDragChanged: { value in
                            if currentGestureMode == .blockDragging {
                                handleDragChange(value: value, block: block)
                            }
                        },
                        onDragEnded: { value in
                            if currentGestureMode == .blockDragging {
                                handleDragEnd(value: value, block: block)
                            }
                        },
                        namespace: namespace
                    )
                    .scaleEffect(0.8) // Further reduce size
                    .frame(width: 45, height: 45) // Constrain frame size
                    
                    // Position the pin icon so it doesn't overlap too much
                    Image(systemName: "pin.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color(hex: "8B2635")).frame(width: 22, height: 22))
                        .offset(x: -22, y: -22) // Move further to not overlap
                        .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                }
            } else {
                // Show empty pin area
                Circle()
                    .strokeBorder(style: StrokeStyle(
                        lineWidth: 1.5,
                        dash: [3, 3]
                    ))
                    .foregroundColor(Color(hex: "8B2635").opacity(0.6))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "pin")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8B2635").opacity(0.6))
                    )
                    .opacity(isHoldAreaActive ? 0.9 : 0.5)
            }
        }
        .frame(width: 60, height: 60)
        .padding(.trailing, 12)
        .padding(.top, 6)
        .onDrop(of: ["public.block"], isTargeted: nil) { providers, _ in
            if isDragging && heldBlock == nil {
                isHoldAreaActive = true
                
                // Handle the drag completion after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if selectedBlock != nil {
                        feedbackGenerator()
                        withAnimation(.spring()) {
                            heldBlock = selectedBlock
                            
                            // Remove from available blocks
                            if let block = selectedBlock {
                                availableBlocks.removeAll { $0.id == block.id }
                                
                                // Add a replacement block
                                if let newBlock = Block.blocks.filter({ b in
                                    !availableBlocks.contains(where: { $0.id == b.id })
                                }).randomElement() {
                                    availableBlocks.append(newBlock)
                                }
                            }
                        }
                    }
                    isHoldAreaActive = false
                }
                return true
            }
            return false
        }
    }
    
    private func handleDragChange(value: DragGesture.Value, block: Block) {
        DispatchQueue.main.async {
            #if DEBUG
            print("BlockSelectionView - Drag location: \(value.location)")
            print("BlockSelectionView - Grid frame in coordinator: \(GridProjectionCoordinator.shared.gridFrame)")
            #endif
            
            // Set which block is being dragged
            self.draggedBlockId = block.id
            
            // Set position and update selection
            self.blockPosition = value.location 
            self.selectedBlock = block
            self.isDragging = true
            
            // CRITICAL DIRECT APPROACH: Force cat to look DOWN at blocks during dragging
            DirectCatEyeControl.shared.isDragging = true
            
            // CRITICAL: Set exact frames for clear down positions based on horizontal position
            let screenWidth = UIScreen.main.bounds.width
            let leftZone = screenWidth * 0.4  // More sensitive split
            let rightZone = screenWidth * 0.6  // More sensitive split
            
            let catEyeFrame: Int
            if value.location.x < leftZone {
                catEyeFrame = 20 // Look RIGHT when dragging on LEFT side
            } else if value.location.x > rightZone {
                catEyeFrame = 5 // Look LEFT when dragging on RIGHT side
            } else {
                catEyeFrame = 2 // Keep center-down the same
            }
            
            // CRITICAL: Force eye frame update
            DirectCatEyeControl.shared.currentEyeFrame = catEyeFrame
            
            // DIRECT NOTIFICATION: Send with position for reference
            NotificationCenter.default.post(
                name: .init("ForceCatEyeFrame"),
                object: nil,
                userInfo: ["frame": catEyeFrame, "isDragging": true, "position": value.location]
            )
            
            // Calculate and update grid projection
            if let droppedBlock = self.selectedBlock {
                updateGridProjection(position: value.location, block: droppedBlock)
            }
        }
    }
    
    private func updateGridProjection(position: CGPoint, block: Block) {
        guard let (row, col) = GridProjectionCoordinator.shared.calculateGridCell(at: position) else {
            GridProjectionCoordinator.shared.projectedCells = []
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
            print("BlockSelectionView projected cells: \(projectedCells)")
        }
        #endif
        
        // Update the shared projection coordinator
        GridProjectionCoordinator.shared.projectedCells = projectedCells
    }
    
    private func clearGridProjection() {
        // Clear the projected grid cells in the coordinator
        GridProjectionCoordinator.shared.projectedCells = []
        
        #if DEBUG
        print("🧩 Grid projection cleared")
        #endif
    }
    
    private func handleDragEnd(value: DragGesture.Value, block: Block) {
        // Clear the projected grid position when the drag ends
        clearGridProjection()
        
        // CRITICAL FIX: Reset all eye state completely to prevent sticking
        // Force a complete state reset through all possible channels
        DirectCatEyeControl.shared.isDragging = false
        DirectCatEyeControl.shared.currentEyeFrame = 13 // CENTER position
        
        // DIRECT NOTIFICATION: Force reset to center frame through both channels
        NotificationCenter.default.post(
            name: .init("ForceCatEyeFrame"),
            object: nil, 
            userInfo: ["frame": 13, "isDragging": false]
        )
        
        // Also send the BlockDraggingEnded notification to ensure all listeners are notified
        NotificationCenter.default.post(
            name: .init("BlockDraggingEnded"),
            object: nil,
            userInfo: nil
        )
        
        // ULTRA CRITICAL: Send an additional state reset notification after slight delay
        // This ensures that any competing state changes get overridden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            DirectCatEyeControl.shared.isDragging = false
            DirectCatEyeControl.shared.currentEyeFrame = 13
            
            // Forced state reset notification
            NotificationCenter.default.post(
                name: .init("FinalDragReset"),
                object: nil,
                userInfo: nil
            )
            
            print("🔴 FINAL RESET: Ensuring cat eye returns to center (13)")
        }
        
        // Flag to track if we placed successfully
        let didPlaceBlock = GridView.validatePlacement(at: value.location)
        
        if didPlaceBlock {
            playHapticFeedback()
            
            // Check if this is the held block
            if heldBlock?.id == block.id {
                withAnimation(.spring()) {
                    heldBlock = nil
                }
            } else {
                // Existing block replacement code
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.2)) {
                    availableBlocks.removeAll { $0.id == block.id }
                    
                    // Get new random block that's not currently shown
                    let remainingBlocks = Block.blocks.filter { b in
                                !availableBlocks.contains(where: { $0.id == b.id }) &&
                                (heldBlock == nil || b.id != heldBlock!.id)
                    }
                    
                    if let newBlock = remainingBlocks.randomElement() {
                        availableBlocks.append(newBlock)
                        }
                    }
                }
            }
        }
        
        // Reset drag state in a controlled sequence
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            draggedBlockId = nil
        }
        
        // Slightly delay these changes to avoid animation conflicts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hoveredBlockId = nil
            }
            
            // Important: we don't reset isDragging here - DraggableBlock handles that
            // This prevents state conflicts when multiple components try to reset it
            selectedBlock = nil
        }
    }
    
    private func playHapticFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    // Add this new method for block generation
    private func generateInitialBlocks() {
        var newBlocks = Set<Block>()
        let allBlocks = Block.blocks.filter { !usedBlocks.contains($0.id) }
        
        while newBlocks.count < visibleBlockCount && !allBlocks.isEmpty {
            if let randomBlock = allBlocks.randomElement() {
                newBlocks.insert(randomBlock)
                usedBlocks.insert(randomBlock.id)
            }
        }
        availableBlocks = Array(newBlocks)
        replacementQueue = Block.blocks.filter { !newBlocks.contains($0) }
    }
    
    // Add a haptic feedback function
    private func feedbackGenerator() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Add inside the struct, before the closing brace
    private var headerView: some View {
        HStack(alignment: .center) {
            Text("i love you")
                .font(.custom("Snell Roundhand", size: 22))
                .foregroundColor(textColor)
                .padding(.leading, 16)
            
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 18))
                .foregroundColor(isDragging ? Color(hex: "8B2635") : textColor)
                .scaleEffect(heartBeat ? 1.15 : 1.0)
                .opacity(heartBeat ? 1.0 : 0.85)
                .animation(
                    Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true), 
                    value: heartBeat
                )
                .onAppear { heartBeat = true }
                .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
        .background(headerBackground)
    }
}

struct BlockItemView: View {
    let block: Block
    let isSelected: Bool
    let isDragged: Bool
    let isHovered: Bool
    let cellSize: CGFloat
    let gridGeometry: GridGeometry
    let gestureMode: GestureMode // Add gesture mode parameter
    let onHoverChanged: (Bool) -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let namespace: Namespace.ID
    
    @State private var placeholderPhase = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if isDragged {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(
                            lineWidth: 3,
                            dash: [8, 6],
                            dashPhase: CGFloat(placeholderPhase)
                        )
                    )
                    .foregroundColor(block.color.color)
                    .frame(
                        width: cellSize * CGFloat(block.shape[0].count),
                        height: cellSize * CGFloat(block.shape.count)
                    )
                    .transition(.identity)
                    .zIndex(2)
                    .onAppear {
                        let baseAnimation = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
                        withAnimation(baseAnimation) {
                            placeholderPhase = 24
                        }
                    }
            }
            
            BlockPreview(
                block: block,
                gridGeometry: gridGeometry,
                isSelected: isSelected,
                cellSize: cellSize,
                namespace: namespace
            )
            .opacity(isDragged ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: isDragged)
            .matchedGeometryEffect(id: "block-\(block.id)", in: namespace)
            
            // Add this invisible overlay that appears only when hovering
            if isHovered && !isDragged {
                Image(systemName: "hand.tap")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "704341").opacity(0.7))
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 22, height: 22)
                    )
                    .position(x: cellSize * CGFloat(block.shape[0].count) - 10, 
                              y: cellSize * CGFloat(block.shape.count) - 10)
                    .opacity(0.8)
            }
        }
        .gesture(
            // Only enable the gesture in block dragging mode
            gestureMode == .blockDragging ?
            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged { value in
                    onDragChanged(value)
                }
                .onEnded { value in
                    onDragEnded(value)
                } : nil
        )
    }
}

struct BlockFrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct InventoryFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct BlockSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        BlockSelectionView(
            availableBlocks: .constant(Block.blocks),
            selectedBlock: .constant(nil),
            blockPosition: .constant(nil),
            isDragging: .constant(false),
            gridGeometry: .constant(GridGeometry(frame: CGRect(x: 0, y: 0, width: 100, height: 100), cellSize: 30))
        )
        .padding()
        .background(Color.black.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}

// First, let's extract the holding area into a separate view
struct HoldingAreaView: View {
    let borderColor: Color
    let isHoldAreaActive: Bool
    let heldBlock: Block?
    let selectedBlock: Block?
    let draggedBlockId: UUID?
    let hoveredBlockId: UUID?
    let gridGeometry: GridGeometry
    let currentGestureMode: GestureMode
    let namespace: Namespace.ID
    let isDragging: Bool
    
    let onHoverChanged: (Block, Bool) -> Void
    let onDragChanged: (DragGesture.Value, Block) -> Void
    let onDragEnded: (DragGesture.Value, Block) -> Void
    let onReleaseBlock: () -> Void
    let onAreaActivated: () -> Void
    let onAreaDropped: () -> Void
    
    var body: some View {
        HStack {
            // Left side: "Hold" label
            Text("Hold")
                .font(.custom("Snell Roundhand", size: 16))
                .foregroundColor(Color(hex: "704341"))
                .padding(.leading, 20)
            
            Spacer()
            
            // Right side: Block holding area
            ZStack {
                // Empty slot indicator with dashed outline
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(
                        lineWidth: 2,
                        dash: [4, 4]
                    ))
                    .foregroundColor(borderColor.opacity(isHoldAreaActive ? 0.8 : 0.6))
                    .frame(width: 70, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(isHoldAreaActive ? 0.2 : 0.0))
                    )
                    .overlay(
                        Group {
                            if heldBlock == nil {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(borderColor.opacity(0.6))
                            }
                        }
                    )
                
                // Held block display
                if let block = heldBlock {
                    BlockItemView(
                        block: block,
                        isSelected: selectedBlock?.id == block.id,
                        isDragged: draggedBlockId == block.id,
                        isHovered: hoveredBlockId == block.id,
                        cellSize: gridGeometry.cellSize,
                        gridGeometry: gridGeometry,
                        gestureMode: currentGestureMode,
                        onHoverChanged: { hovering in
                            onHoverChanged(block, hovering)
                        },
                        onDragChanged: { value in
                            onDragChanged(value, block)
                        },
                        onDragEnded: { value in
                            onDragEnded(value, block)
                        },
                        namespace: namespace
                    )
                    .overlay(
                        Button(action: onReleaseBlock) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.white.opacity(0.9))
                                .background(Circle().fill(Color(hex: "8B2635")))
                                .shadow(radius: 1)
                        }
                        .offset(x: 25, y: -25)
                    )
                }
            }
            .frame(width: 80, height: 80)
            .padding(.trailing, 20)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if isDragging && heldBlock == nil {
                            onAreaActivated()
                        }
                    }
                    .onEnded { _ in
                        if isDragging && heldBlock == nil {
                            onAreaDropped()
                        }
                    }
            )
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.3))
    }
}

