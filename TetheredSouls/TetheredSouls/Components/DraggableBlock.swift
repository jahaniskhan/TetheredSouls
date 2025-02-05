import SwiftUI
import CoreGraphics

struct DraggableBlock: View {
    let block: Block
    @Binding var position: CGPoint?
    @Binding var isDragging: Bool
    @Binding var grid: [[Bool]]
    @State private var dragOffset: CGSize = .zero
    @State private var isValidPlacement = true
    @State private var gridPosition: CGPoint = .zero
    @State private var scale: CGFloat = 1.0
    
    private let gridColumns: Int = 10
    private let gridRows: Int = 10
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(
                geometry.size.width / CGFloat(gridColumns),
                geometry.size.height / CGFloat(gridRows)
            )
            
            ZStack {
                // Persistent ghost preview
                BlockPreview(block: block, isSelected: false)
                    .opacity(isValidPlacement ? 0.4 : 0.2)
                    .frame(
                        width: cellSize * CGFloat(block.shape[0].count),
                        height: cellSize * CGFloat(block.shape.count)
                    )
                    .position(gridPosition)
                    .animation(.spring(), value: gridPosition)
                
                // Draggable element
                BlockPreview(block: block, isSelected: false)
                    .frame(
                        width: cellSize * CGFloat(block.shape[0].count),
                        height: cellSize * CGFloat(block.shape.count)
                    )
                    .offset(dragOffset)
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .shadow(color: .black.opacity(isDragging ? 0.2 : 0), radius: 8, y: 4)
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                dragOffset = value.translation
                                isDragging = true
                                
                                let rawPosition = value.location
                                let cellX = (rawPosition.x / cellSize).rounded(.down)
                                let cellY = (rawPosition.y / cellSize).rounded(.down)
                                gridPosition = CGPoint(
                                    x: cellX * cellSize + (CGFloat(block.shape[0].count)/2 * cellSize),
                                    y: cellY * cellSize + (CGFloat(block.shape.count)/2 * cellSize)
                                )
                                
                                isValidPlacement = canPlaceBlock(at: Int(cellY), column: Int(cellX))
                            }
                            .onEnded { _ in
                                if isValidPlacement {
                                    placeBlock(at: Int(gridPosition.y / cellSize), 
                                             column: Int(gridPosition.x / cellSize))
                                }
                                
                                withAnimation {
                                    dragOffset = .zero
                                    isDragging = false
                                }
                                
                                NotificationCenter.default.post(name: .resetIdleTimer, object: nil)
                            }
                    )
            }
            .frame(width: cellSize * CGFloat(gridColumns), 
                   height: cellSize * CGFloat(gridRows))
        }
    }
    
    private func canPlaceBlock(at row: Int, column: Int) -> Bool {
        // Check if block would fit within grid bounds and not overlap
        for (rowIndex, gridRow) in block.shape.enumerated() {
            for (colIndex, cell) in gridRow.enumerated() {
                if cell {
                    let newRow = row + rowIndex
                    let newCol = column + colIndex
                    
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
    
    private func placeBlock(at row: Int, column: Int) {
        var newGrid = grid
        for (rowIndex, gridRow) in block.shape.enumerated() {
            for (colIndex, cell) in gridRow.enumerated() {
                if cell {
                    let newRow = row + rowIndex
                    let newCol = column + colIndex
                    newGrid[newRow][newCol] = true
                }
            }
        }
        grid = newGrid
    }
}