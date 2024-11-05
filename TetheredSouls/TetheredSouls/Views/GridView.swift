import SwiftUI
import CoreGraphics

struct GridView: View {
    @Binding var grid: [[Bool]]
    @Binding var selectedBlock: Block?
    @Binding var blockPosition: CGPoint?
    @Binding var isDragging: Bool
    
    // Calculate cell size based on screen width
    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - (2 * Theme.Layout.padding)
        let totalSpacing = Theme.Layout.gridSpacing * 9
        return (availableWidth - totalSpacing) / 10
    }
    
    func canPlaceBlock(at row: Int, column: Int) -> Bool {
        guard let block = selectedBlock else { return false }
        
        for (r, rows) in block.shape.enumerated() {
            for (c, cell) in rows.enumerated() {
                if cell {
                    let newRow = row + r
                    let newCol = column + c
                    if newRow >= 10 || newCol >= 10 || grid[newRow][newCol] {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    private func isDraggingOver(row: Int, column: Int) -> Bool {
        guard let _ = selectedBlock,
              let position = blockPosition,
              isDragging else { return false }
        
        let cellFrame = CGRect(
            x: CGFloat(column) * cellSize,
            y: CGFloat(row) * cellSize,
            width: cellSize,
            height: cellSize
        )
        
        let adjustedPosition = CGPoint(
            x: position.x - cellSize / 2,
            y: position.y - cellSize / 2
        )
        
        return cellFrame.contains(adjustedPosition)
    }
    
    func placeBlock(at row: Int, column: Int) {
        guard let block = selectedBlock else { return }
        
        var newGrid = grid
        for (r, rows) in block.shape.enumerated() {
            for (c, cell) in rows.enumerated() {
                if cell {
                    newGrid[row + r][column + c] = true
                }
            }
        }
        
        grid = newGrid
        checkForCompletedRows()
        selectedBlock = nil
        isDragging = false
    }
    
    func checkForCompletedRows() {
        var newGrid = grid
        var row = grid.count - 1
        
        while row >= 0 {
            if grid[row].allSatisfy({ $0 }) {
                // Remove completed row
                newGrid.remove(at: row)
                // Add new empty row at top
                newGrid.insert(Array(repeating: false, count: grid[0].count), at: 0)
            } else {
                row -= 1
            }
        }
        
        if newGrid != grid {
            withAnimation(.easeOut(duration: 0.2)) {
                grid = newGrid
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: Theme.Layout.gridSpacing) {
                ForEach(0..<10, id: \.self) { row in
                    HStack(spacing: Theme.Layout.gridSpacing) {
                        ForEach(0..<10, id: \.self) { column in
                            CellView(
                                isOccupied: grid[row][column],
                                row: row,
                                column: column,
                                selectedBlock: selectedBlock,
                                isPreview: isDraggingOver(row: row, column: column)
                            )
                            .frame(width: cellSize, height: cellSize)
                            .animation(.easeOut(duration: 0.2), value: grid[row][column])
                            .onTapGesture {
                                if canPlaceBlock(at: row, column: column) {
                                    placeBlock(at: row, column: column)
                                }
                            }
                        }
                    }
                }
            }
            .frame(
                width: cellSize * 10 + Theme.Layout.gridSpacing * 9,
                height: cellSize * 10 + Theme.Layout.gridSpacing * 9
            )
            .background(Theme.background)
            .cornerRadius(Theme.Layout.cornerRadius)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: cellSize * 10 + Theme.Layout.gridSpacing * 9)
    }
}