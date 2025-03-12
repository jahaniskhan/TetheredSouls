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
        if availableBlocks.wrappedValue.isEmpty {
            generateInitialBlocks()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Thinner header with love message in true cursive font
            HStack(alignment: .center) {
                Text("i love you")
                    .font(.custom("Snell Roundhand", size: 22))  // True cursive font
                    .foregroundColor(textColor)
                    .padding(.leading, 16)
                
                Spacer()
                
                // Heart icon with breathing animation
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
            .padding(.vertical, 8)  // Reduced vertical padding for thinner header
            .background(headerBackground)
            
            // Blocks container with subtle animations
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(availableBlocks) { block in
                        BlockItemView(
                            block: block,
                            isSelected: selectedBlock?.id == block.id,
                            isDragged: draggedBlockId == block.id,
                            isHovered: hoveredBlockId == block.id,
                            cellSize: gridGeometry.cellSize,
                            gridGeometry: gridGeometry,
                            onHoverChanged: { hovering in
                                withAnimation(.spring(response: 0.3)) {
                                    hoveredBlockId = hovering ? block.id : nil
                                }
                            },
                            onDragChanged: { value in
                                handleDragChange(value: value, block: block)
                            },
                            onDragEnded: { value in
                                handleDragEnd(value: value, block: block)
                            },
                            namespace: namespace
                        )
                        .zIndex(draggedBlockId == block.id ? 3 : 0)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(height: 100)
            .background(panelBackground)
        }
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(borderColor, lineWidth: 2)
                .opacity(0.9)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 8)
        .scaleEffect(isExpanded ? 1.0 : 0.95)
        .opacity(isExpanded ? 1.0 : 0.8)
        .coordinateSpace(name: "gameArea")
        .onAppear {
            if availableBlocks.isEmpty {
                availableBlocks = Array(Block.blocks.shuffled().prefix(3))
            }
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
    
    private func handleDragEnd(value: DragGesture.Value, block: Block) {
        // First clear the projection
        GridProjectionCoordinator.shared.projectedCells = []
        
        if GridView.validatePlacement(at: value.location) {
            withAnimation(.easeOut(duration: 0.2)) {
                availableBlocks.removeAll { $0.id == block.id }
                
                // Get new random block that's not currently shown
                let remainingBlocks = Block.blocks.filter { b in
                    !availableBlocks.contains(where: { $0.id == b.id })
                }
                
                if let newBlock = remainingBlocks.randomElement() {
                    availableBlocks.append(newBlock)
                }
            }
            playHapticFeedback()
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            draggedBlockId = nil
            hoveredBlockId = nil
        }
        isDragging = false
        selectedBlock = nil
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
}

struct BlockItemView: View {
    let block: Block
    let isSelected: Bool
    let isDragged: Bool
    let isHovered: Bool
    let cellSize: CGFloat
    let gridGeometry: GridGeometry
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
        }
        .gesture(
            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged { value in
                    onDragChanged(value)
                }
                .onEnded { value in
                    onDragEnded(value)
                }
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
