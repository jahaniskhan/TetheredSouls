import SwiftUI
import CoreGraphics

struct GridView: View {
    @ObservedObject var state: GridState
    
    private var cellSize: CGFloat {
        state.cellSize
    }
    
    private func isDraggingOver(row: Int, column: Int) -> Bool {
        guard let selectedBlock = state.selectedBlock,
              let position = state.blockPosition,
              state.isDragging,
              let (gridY, gridX) = state.calculateGridPosition(at: position, for: selectedBlock) else { return false }
        
        let blockRow = row - gridY
        let blockCol = column - gridX
        
        return blockRow >= 0 && 
               blockRow < selectedBlock.shape.count &&
               blockCol >= 0 && 
               blockCol < selectedBlock.shape[0].count &&
               selectedBlock.shape[blockRow][blockCol]
    }
    
    private func cellView(row: Int, column: Int) -> some View {
        CellView(
            isOccupied: state.grid[row][column],
            row: row,
            column: column,
            selectedBlock: state.selectedBlock,
            isPreview: state.isDragging && isDraggingOver(row: row, column: column),
            placedBlockColor: state.placedColors[row][column]
        )
        .frame(width: cellSize, height: cellSize)
        .animation(.easeOut(duration: 0.2), value: state.grid[row][column])
        .onTapGesture {
            if state.canPlaceBlock(at: row, column: column) {
                state.placeBlock(at: row, column: column)
            }
        }
    }
    
    private func rowView(_ row: Int) -> some View {
        HStack(spacing: Theme.Layout.gridSpacing) {
            ForEach(0..<state.grid[row].count, id: \.self) { column in
                cellView(row: row, column: column)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. Grid
                VStack(spacing: Theme.Layout.gridSpacing) {
                    ForEach(0..<state.grid.count, id: \.self) { row in
                        rowView(row)
                    }
                }
                .frame(width: state.gridDimensions, height: state.gridDimensions)
                .background(Theme.background)
                .cornerRadius(Theme.Layout.cornerRadius)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // 2. Heart Particles
                ForEach(state.heartParticles, id: \.id) { particle in
                    HeartParticle(color: particle.color)
                        .position(particle.position)
                }
                
                // 3. Tap Detection (on top)
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onTapGesture(coordinateSpace: .global) { location in
                        if !state.isInteracting {
                            let colors = [
                                Theme.primary,
                                Theme.secondary, 
                                Theme.tertiary,
                                Theme.quaternary
                            ]
                            
                            state.heartParticles.append((
                                id: UUID(),
                                position: CGPoint(
                                    x: location.x,
                                    y: location.y - 100 // Reduce offset from 200 to 100
                                ),
                                color: colors.randomElement() ?? Theme.primary
                            ))
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak state] in
                                state?.heartParticles.removeFirst()
                            }
                        }
                    }
            }
        }
        .frame(height: state.gridDimensions)
    }
}