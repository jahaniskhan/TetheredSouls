import SwiftUI
import CoreGraphics

struct GridView: View {
    @Binding var grid: [[Bool]]
    @Binding var selectedBlock: Block?
    @Binding var blockPosition: CGPoint?
    @Binding var isDragging: Bool
    @StateObject private var touchCoordinator = GridTouchCoordinator.shared
    
    // Calculate cell size based on screen width
    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - (2 * Theme.Layout.padding)
        let totalSpacing = Theme.Layout.gridSpacing * 9
        let calculatedSize = (availableWidth - totalSpacing) / 10
        return max(calculatedSize, 30) // Ensure minimum size for touch targets
    }
    
    func canPlaceBlock(at row: Int, column: Int) -> Bool {
        guard let block = selectedBlock,
              GameStateManager.shared.availableBlocks.contains(where: { $0.id == block.id })
        else { return false }
        
        return block.shape.enumerated().allSatisfy { (r, rows) in
            rows.enumerated().allSatisfy { (c, cell) in
                guard cell else { return true }
                let newRow = row + r
                let newCol = column + c
                return self.grid.indices.contains(newRow) && 
                       self.grid[newRow].indices.contains(newCol) &&
                       !self.grid[newRow][newCol]
            }
        }
    }
    
    private func isDraggingOver(row: Int, column: Int) -> Bool {
        guard let position = self.blockPosition else { return false }
        
        let cellFrame = CGRect(
            x: CGFloat(column) * self.cellSize + self.cellSize/2,
            y: CGFloat(row) * self.cellSize + self.cellSize/2,
            width: self.cellSize,
            height: self.cellSize
        )
        
        return cellFrame.contains(position)
    }
    
    private func placeBlock(at row: Int, column: Int) {
        guard let block = self.selectedBlock else { return }
        
        var newGrid = self.grid
        for (r, rows) in block.shape.enumerated() {
            for (c, cell) in rows.enumerated() {
                if cell {
                    let newRow = (row + r).clamped(to: 0..<self.grid.count)
                    let newCol = (column + c).clamped(to: 0..<self.grid[0].count)
                    newGrid[newRow][newCol] = true
                }
            }
        }
        
        self.grid = newGrid
        self.checkForCompletedRows()
        
        // Wake the cat
        NotificationCenter.default.post(name: .resetIdleTimer, object: nil)
        
        DispatchQueue.main.async {
            self.selectedBlock = nil
            self.isDragging = false
            self.blockPosition = nil
        }
    }
    
    func checkForCompletedRows() {
        var newGrid = self.grid
        var row = self.grid.count - 1
        
        while row >= 0 {
            if self.grid[row].allSatisfy({ $0 }) {
                // Remove completed row
                newGrid.remove(at: row)
                // Add new empty row at top
                newGrid.insert(Array(repeating: false, count: self.grid[0].count), at: 0)
            } else {
                row -= 1
            }
        }
        
        if newGrid != self.grid {
            withAnimation(.easeOut(duration: 0.2)) {
                self.grid = newGrid
            }
        }
    }
    
    // Update cell visual style to match image
    private func makeCell(row: Int, column: Int) -> some View {
        let isFilled = self.grid[row][column]
        let isValidPlacement = self.canPlaceBlock(at: row, column: column)
        
        return CellView(
            isOccupied: isFilled,
            row: row,
            column: column,
            selectedBlock: self.selectedBlock,
            isPreview: self.isDragging && self.selectedBlock != nil
        )
        .frame(width: self.cellSize, height: self.cellSize)
        .background(
            ZStack {
                if !isValidPlacement && isDragging {
                    Color.red.opacity(0.05)  // Very subtle red for invalid placement
                }
                if self.isDraggingOver(row: row, column: column) {
                    Color.gray.opacity(0.1)  // Very subtle highlight
                }
            }
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let location = value.location
                    self.blockPosition = location
                    self.isDragging = true
                    
                    let column = Int((location.x / self.cellSize).rounded(.down))
                    let row = Int((location.y / self.cellSize).rounded(.down))
                    
                    if self.canPlaceBlock(at: row, column: column) {
                        self.touchCoordinator.currentPosition = CGPoint(x: CGFloat(column), y: CGFloat(row))
                    }
                }
                .onEnded { value in
                    let location = value.location
                    let column = Int((location.x / self.cellSize).rounded(.down))
                    let row = Int((location.y / self.cellSize).rounded(.down))
                    
                    if self.canPlaceBlock(at: row, column: column) {
                        self.placeBlock(at: row, column: column)
                    }
                    
                    self.isDragging = false
                    self.blockPosition = nil
                    self.selectedBlock = nil
                }
        )
    }
    
    // Then simplify the GridRowView
    struct GridRowView: View {
        let row: Int
        let grid: [[Bool]]
        let cellSize: CGFloat
        let makeCell: (Int) -> AnyView // Cell builder closure
        
        init(row: Int, grid: [[Bool]], cellSize: CGFloat, makeCell: @escaping (Int) -> AnyView) {
            self.row = row
            self.grid = grid
            self.cellSize = cellSize
            self.makeCell = makeCell
        }
        
        var body: some View {
            HStack(spacing: Theme.Layout.gridSpacing) {
                ForEach(0..<self.grid[row].count, id: \.self) { column in
                    self.makeCell(column)
                }
            }
        }
    }
    
    // Then simplify the main body
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: Theme.Layout.gridSpacing) {
                ForEach(0..<self.grid.count, id: \.self) { row in
                    HStack(spacing: Theme.Layout.gridSpacing) {
                        ForEach(0..<self.grid[row].count, id: \.self) { column in
                            self.makeCell(row: row, column: column)
                        }
                    }
                }
            }
            .frame(
                width: self.cellSize * 10 + Theme.Layout.gridSpacing * 9,
                height: self.cellSize * 10 + Theme.Layout.gridSpacing * 9
            )
            .modifier(GridStyleModifier())
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .contentShape(Rectangle())
            .onTapGesture { location in
                self.handleGridTap(location: location, geometry: geometry)
            }
        }
    }
    
    // Extract tap handler logic
    private func handleGridTap(location: CGPoint, geometry: GeometryProxy) {
        let gridFrame = CGRect(
            x: (geometry.size.width - (self.cellSize * 10 + Theme.Layout.gridSpacing * 9)) / 2,
            y: (geometry.size.height - (self.cellSize * 10 + Theme.Layout.gridSpacing * 9)) / 2,
            width: self.cellSize * 10 + Theme.Layout.gridSpacing * 9,
            height: self.cellSize * 10 + Theme.Layout.gridSpacing * 9
        )
        
        #if DEBUG
        print("=== Grid Touch Debug ===")
        print("Raw tap location: \(location)")
        print("Grid frame: \(gridFrame)")
        #endif
        
        let gridLocation = CGPoint(
            x: location.x - gridFrame.minX,
            y: location.y - gridFrame.minY
        )
        
        self.touchCoordinator.touchLocation = gridLocation
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.touchCoordinator.touchLocation = nil
        }
    }
    
    static func validatePlacement(at position: CGPoint) -> Bool {
        // Calculate cellSize directly since we can't access the instance property
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - (2 * Theme.Layout.padding)
        let totalSpacing = Theme.Layout.gridSpacing * 9
        let cellSize = max((availableWidth - totalSpacing) / 10, 30)
        
        let column = Int((position.x / cellSize).rounded())
        let row = Int((position.y / cellSize).rounded())
        
        // Access grid through GameStateManager since we can't access the instance property
        let grid = GameStateManager.shared.grid
        return row >= 0 && row < grid.count && column >= 0 && column < grid[0].count
    }
}

// Updated to match the simple grid in the image
struct GridStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Rectangle()
                    .fill(Color.white)
            )
            .overlay(
                GridLines()
                    .stroke(Color.black, lineWidth: 1)
            )
    }
}

struct GridLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gridSize = 10
        let cellSize = rect.width / CGFloat(gridSize)
        
        // Draw simple grid lines
        for i in 0...gridSize {
            let x = cellSize * CGFloat(i)
            let y = cellSize * CGFloat(i)
            
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        return path
    }
}