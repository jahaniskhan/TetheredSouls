import SwiftUI
import Foundation

// Handles dragging and placement of blocks on the grid
struct DraggableBlock: View {
    let block: Block
    @ObservedObject var state: GridState
    
    var body: some View {
        BlockPreview(block: block, isSelected: false)
            .frame(width: state.cellSize * CGFloat(block.shape[0].count),
                  height: state.cellSize * CGFloat(block.shape.count))
            .opacity(0.8)
            .position(state.blockPosition ?? .zero)
            .offset(x: -state.cellSize * CGFloat(block.shape[0].count) / 2,
                   y: -state.cellSize * CGFloat(block.shape.count) / 2)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        state.updateBlockPosition(value.location)
                        if let gridPos = state.calculateGridPosition(at: value.location, for: block) {
                            state.updateDebugInfo(
                                touchPosition: value.location,
                                gridPosition: gridPos
                            )
                        }
                    }
                    .onEnded { value in
                        if let gridPos = state.calculateGridPosition(at: value.location, for: block),
                           state.canPlaceBlock(at: gridPos.row, column: gridPos.column) {
                            state.placeBlock(at: gridPos.row, column: gridPos.column)
                        } else {
                            // Return block to inventory
                            state.inventory[block.id] = 1
                            withAnimation(.easeOut(duration: 0.2)) {
                                state.isDragging = false
                                state.blockPosition = nil
                                state.selectedBlock = nil
                            }
                        }
                    }
            )
    }
}