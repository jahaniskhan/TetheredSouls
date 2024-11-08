import SwiftUI
import Combine

class GridState: ObservableObject {
    // MARK: - Published Properties
    @Published var grid: [[Bool]]
    @Published var placedColors: [[BlockColor?]]
    @Published var selectedBlock: Block?
    @Published var blockPosition: CGPoint?
    @Published var isDragging: Bool
    @Published var score: Int = 0
    @Published var currentStreak: Int = 0
    @Published var heartParticles: [(id: UUID, position: CGPoint, color: Color)] = []
    @Published var isInteracting: Bool = false
    
    // MARK: - Block Selection State
    @Published var inventory: [UUID: Int] = [:]
    @Published var availableBlocks: [Block] = []
    @Published var nextBlocks: [Block] = []
    @Published var isPaused: Bool = false {
        didSet {
            if isPaused {
                stopTimer()
            } else {
                startTimer()
            }
        }
    }
    @Published var timeRemaining: TimeInterval = 30
    
    // MARK: - Debug Properties
    @Published var debugInfo: DebugInfo = DebugInfo()
    
    // MARK: - Constants
    private let size: Int
    private let maxBlocksShown = 5
    private let blockRefreshInterval: TimeInterval = 30
    private let basePoints = 100
    
    var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - (2 * Theme.Layout.padding)
        let totalSpacing = Theme.Layout.gridSpacing * 9
        return (availableWidth - totalSpacing) / 10
    }
    
    var gridDimensions: CGFloat {
        cellSize * 10 + Theme.Layout.gridSpacing * 9
    }
    
    func calculateGridOrigin() -> CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        let xOffset = (screenWidth - gridDimensions) / 2
        return CGPoint(x: xOffset, y: 0)
    }
    
    func calculateGridPosition(at position: CGPoint, for block: Block) -> (row: Int, column: Int)? {
        let gridOrigin = calculateGridOrigin()
        let cellSize = self.cellSize + Theme.Layout.gridSpacing
        
        // Adjust for block center
        let blockWidth = CGFloat(block.shape[0].count) * cellSize
        let blockHeight = CGFloat(block.shape.count) * cellSize
        
        let relativeX = position.x - gridOrigin.x - (blockWidth/2)
        let relativeY = position.y - gridOrigin.y - (blockHeight/2)
        
        return (Int(relativeY / cellSize), Int(relativeX / cellSize))
    }
    
    // MARK: - Timer Management
    private var timer: Timer?
    
    // MARK: - Initialization
    init(size: Int = 10) {
        self.size = size
        self.grid = Array(repeating: Array(repeating: false, count: size), count: size)
        self.placedColors = Array(repeating: Array(repeating: nil, count: size), count: size)
        self.selectedBlock = nil
        self.blockPosition = nil
        self.isDragging = false
        generateNewBlocks()
        startTimer()
    }
    
    // MARK: - Block Management
    func generateNewBlocks() {
        availableBlocks = Array(Block.blocks.shuffled().prefix(maxBlocksShown))
        nextBlocks = Array(Block.blocks.shuffled().prefix(3))
        
        availableBlocks.forEach { block in
            inventory[block.id] = 1
        }
    }
    
    func selectBlock(_ block: Block, at position: CGPoint) {
        guard inventory[block.id, default: 0] > 0 else { return }
        isInteracting = true  // Set when starting interaction
        selectedBlock = block
        isDragging = true
        blockPosition = position
        inventory[block.id] = 0
    }
    
    // MARK: - Grid Operations
    func canPlaceBlock(at row: Int, column: Int) -> Bool {
        guard let block = selectedBlock else { return false }
        
        // Check if any part of the block would be out of bounds
        if row < 0 || column < 0 || 
           row + block.shape.count > size || 
           column + block.shape[0].count > size {
            return false
        }
        
        // Now check for collisions
        for (r, rows) in block.shape.enumerated() {
            for (c, cell) in rows.enumerated() {
                if cell {
                    let newRow = row + r
                    let newCol = column + c
                    if grid[newRow][newCol] {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    func placeBlock(at row: Int, column: Int) {
        guard let block = selectedBlock,
              canPlaceBlock(at: row, column: column) else { 
            // Return block to inventory if placement fails
            if let block = selectedBlock {
                inventory[block.id] = 1
            }
            resetBlockState()
            return 
        }
        
        var newGrid = grid
        var newColors = placedColors
        
        // Place block and its color
        for (r, rows) in block.shape.enumerated() {
            for (c, cell) in rows.enumerated() {
                if cell {
                    let newRow = row + r
                    let newCol = column + c
                    newGrid[newRow][newCol] = true
                    newColors[newRow][newCol] = block.color  // Fixed: Properly assign block color
                }
            }
        }
        
        // Add heart particle
        let location = calculateParticlePosition(row: row, column: column, block: block)
        heartParticles.append((
            id: UUID(),
            position: location,
            color: Theme.primary  // Add color parameter
        ))
        
        // Remove particle after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.heartParticles.removeFirst()
        }
        
        withAnimation(.easeOut(duration: 0.2)) {
            grid = newGrid
            placedColors = newColors
            checkForCompletedRows()
            resetBlockState()
        }
    }
    
    func updateBlockPosition(_ position: CGPoint) {
        blockPosition = position
    }
    
    func updateDebugInfo(touchPosition: CGPoint, gridPosition: (row: Int, column: Int)) {
        debugInfo.touchPosition = touchPosition
        debugInfo.gridPosition = gridPosition
        debugInfo.blockShape = selectedBlock?.shape ?? []
        debugInfo.blockOffset = blockPosition ?? .zero
        
        if let block = selectedBlock {
            debugInfo.isValidPlacement = canPlaceBlock(at: gridPosition.row, column: gridPosition.column)
            debugInfo.blockShape = block.shape
            debugInfo.blockColor = block.color
            
            if !debugInfo.isValidPlacement {
                debugInfo.placementError = String(format: "Block %dx%d failed: Out of bounds or collision",
                                                block.shape.count,
                                                block.shape[0].count)
            }
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining <= 0 {
                self.generateNewBlocks()
                self.timeRemaining = blockRefreshInterval
            } else {
                self.timeRemaining -= 1
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func togglePause() {
        isPaused.toggle()
    }
    
    // MARK: - Private Helpers
    private func resetBlockState() {
        selectedBlock = nil
        isDragging = false
        blockPosition = nil
        isInteracting = false  // Reset when done interacting
    }
    
    private func calculateParticlePosition(row: Int, column: Int, block: Block) -> CGPoint {
        let gridOrigin = calculateGridOrigin()
        let cellSize = self.cellSize + Theme.Layout.gridSpacing
        
        // Calculate center of block
        let blockCenterX = CGFloat(column + block.shape[0].count / 2) * cellSize
        let blockCenterY = CGFloat(row + block.shape.count / 2) * cellSize
        
        return CGPoint(
            x: gridOrigin.x + blockCenterX,
            y: gridOrigin.y + blockCenterY + 50  // Reduce offset from 100 to 50
        )
    }
    
    private func checkForCompletedRows() {
        var newGrid = grid
        var newColors = placedColors
        var completedRows = 0
        var row = grid.count - 1
        
        while row >= 0 {
            if grid[row].allSatisfy({ $0 }) {
                completedRows += 1
                newGrid.remove(at: row)
                newColors.remove(at: row)
                newGrid.insert(Array(repeating: false, count: size), at: 0)
                newColors.insert(Array(repeating: nil, count: size), at: 0)
            } else {
                row -= 1
            }
        }
        
        if completedRows > 0 {
            updateScore(completedRows)
            withAnimation(.easeOut(duration: 0.2)) {
                grid = newGrid
                placedColors = newColors
            }
        }
    }
    
    private func updateScore(_ completedRows: Int) {
        let streakMultiplier = max(1, currentStreak)
        score += basePoints * completedRows * streakMultiplier
        currentStreak = completedRows > 1 ? currentStreak + 1 : 0
    }
    
    deinit {
        stopTimer()
    }
}

struct DebugInfo {
    var touchPosition: CGPoint = .zero
    var gridPosition: (row: Int, column: Int) = (0, 0)
    var blockOffset: CGPoint = .zero
    var isValidPlacement: Bool = false
    var placementError: String = ""
    var blockShape: [[Bool]] = []
    var blockColor: BlockColor?  // Add color tracking
}