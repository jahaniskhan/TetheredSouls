let position = GridProjectionCoordinator.shared.lastAdjustedPosition ?? value.location
let didPlaceBlock = GridView.validatePlacement(at: position)

if didPlaceBlock {
    // Get grid coordinates from position
    if let (row, column) = GridProjectionCoordinator.shared.calculateGridCell(at: position) {
        // Update the grid with this block
        updateGridWithBlock(block, at: row, column: column)
        
        playHapticFeedback()
        // ...rest of your existing code for block removal/replacement ...
    }
} 

private func handleDragEnd(value: DragGesture.Value, block: Block) {
    // ... existing code ...
    
    let position = GridProjectionCoordinator.shared.lastAdjustedPosition ?? value.location
    let didPlaceBlock = GridView.validatePlacement(at: position)
    
    if didPlaceBlock {
        // Get grid coordinates from position
        if let (row, column) = GridProjectionCoordinator.shared.calculateGridCell(at: position) {
            // Update the grid with this block
            updateGridWithBlock(block, at: row, column: column)
            
            playHapticFeedback()
            // ...rest of your existing code for block removal/replacement ...
        }
    }
    
    // ... rest of the method ...
}

// Add this new method to update the grid
private func updateGridWithBlock(_ block: Block, at row: Int, column: Int) {
    // Get reference to shared grid
    var grid = GameStateManager.shared.grid
    
    // Place the block in the grid
    for (r, blockRow) in block.shape.enumerated() {
        for (c, isSet) in blockRow.enumerated() {
            if isSet {
                let gridRow = row + r
                let gridCol = column + c
                if gridRow >= 0 && gridRow < grid.count && gridCol >= 0 && gridCol < grid[0].count {
                    grid[gridRow][gridCol] = true
                }
            }
        }
    }
    
    // Update the grid in GameStateManager
    GameStateManager.shared.grid = grid
    
    // Check for completed rows
    checkForCompletedRows()
}

// Move the row-checking logic here if it's not already accessible
private func checkForCompletedRows() {
    var grid = GameStateManager.shared.grid
    var row = grid.count - 1
    
    while row >= 0 {
        if grid[row].allSatisfy({ $0 }) {
            // Remove completed row
            grid.remove(at: row)
            // Add new empty row at top
            grid.insert(Array(repeating: false, count: grid[0].count), at: 0)
        } else {
            row -= 1
        }
    }
    
    // Update the grid with changes
    GameStateManager.shared.grid = grid
} 