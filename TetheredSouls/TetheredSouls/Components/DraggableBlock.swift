import SwiftUI
import CoreGraphics

struct DraggableBlock: View {
    let block: Block
    @Binding var position: CGPoint?
    @Binding var isDragging: Bool
    @Binding var grid: [[Bool]]
    @GestureState private var dragOffset: CGSize = .zero
    @State private var isValidPlacement = true
    @State private var gridPosition: CGPoint = .zero
    @State private var scale: CGFloat = 1.0
    
    private let gridSize: CGFloat = 30
    private let gridColumns: Int = 10
    private let gridRows: Int = 10
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Ghost preview at grid position
                if isValidPlacement {
                    BlockPreview(block: block, isSelected: true)
                        .opacity(0.4)
                        .frame(width: 80, height: 80)
                        .foregroundColor(block.color.color)
                        .position(gridPosition)
                        .animation(.interactiveSpring(), value: gridPosition)
                }
                
                // Draggable sticker
                BlockPreview(block: block, isSelected: true)
                    .frame(width: 80, height: 80)
                    .position(position ?? .zero)
                    .offset(dragOffset)
                    .scaleEffect(scale)
                    .rotation3DEffect(.degrees(isDragging ? 4 : 0), axis: (x: 1, y: 0, z: 0))
                    .shadow(color: block.color.color.opacity(0.3), radius: isDragging ? 15 : 5)
                    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: isDragging)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            scale = 1.1
                        }
                    }
                    .onChanged { value in
                        let newPos = CGPoint(
                            x: (position?.x ?? 0) + value.translation.width,
                            y: (position?.y ?? 0) + value.translation.height
                        )
                        withAnimation(.interactiveSpring()) {
                            position = newPos
                            gridPosition = snapToGrid(newPos)
                            isValidPlacement = checkValidPlacement(at: gridPosition, in: geometry)
                        }
                    }
                    .onEnded { _ in
                        let finalPosition = snapToGrid(position ?? .zero)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            scale = 1.0
                            position = finalPosition
                            gridPosition = finalPosition
                        }
                        position = finalPosition
                        if isValidPlacement {
                            placeBlockInGrid(at: gridPosition)
                            isDragging = false
                        }
                    }
            )
        }
    }
    
    private func snapToGrid(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: round(point.x / gridSize) * gridSize,
            y: round(point.y / gridSize) * gridSize
        )
    }
    
    private func checkValidPlacement(at point: CGPoint, in geometry: GeometryProxy) -> Bool {
        let bounds = geometry.frame(in: .local)
        guard bounds.contains(point) else { return false }
        
        // Convert position to grid coordinates
        let gridX = Int((point.x / gridSize).rounded())
        let gridY = Int((point.y / gridSize).rounded())
        
        // Check if block would fit within grid bounds and not overlap
        for (rowIndex, row) in block.shape.enumerated() {
            for (colIndex, cell) in row.enumerated() {
                if cell {
                    let newRow = gridY + rowIndex
                    let newCol = gridX + colIndex
                    
                    // Check grid boundaries
                    if newRow < 0 || newRow >= gridRows || 
                       newCol < 0 || newCol >= gridColumns {
                        return false
                    }
                    
                    // Check for overlap with existing blocks
                    if grid[newRow][newCol] {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    private func placeBlockInGrid(at point: CGPoint) {
        let gridX = Int((point.x / gridSize).rounded())
        let gridY = Int((point.y / gridSize).rounded())
        
        var newGrid = grid
        for (rowIndex, row) in block.shape.enumerated() {
            for (colIndex, cell) in row.enumerated() {
                if cell {
                    let newRow = gridY + rowIndex
                    let newCol = gridX + colIndex
                    newGrid[newRow][newCol] = true
                }
            }
        }
        grid = newGrid
    }
}