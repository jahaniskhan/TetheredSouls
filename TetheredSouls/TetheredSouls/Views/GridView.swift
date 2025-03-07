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
        guard let block = selectedBlock else { return false }
        
        return block.shape.enumerated().allSatisfy { (r, rows) in
            rows.enumerated().allSatisfy { (c, cell) in
                guard cell else { return true }
                let newRow = row + r
                let newCol = column + c
                return (0..<grid.count).contains(newRow) && 
                       (0..<grid[newRow].count).contains(newCol)
            }
        }
    }
    
    private func isDraggingOver(row: Int, column: Int) -> Bool {
        guard let position = blockPosition else { return false }
        
        let cellFrame = CGRect(
            x: CGFloat(column) * cellSize + cellSize/2, // Center-based detection
            y: CGFloat(row) * cellSize + cellSize/2,
            width: cellSize,
            height: cellSize
        )
        
        return cellFrame.contains(position)
    }
    
    private func placeBlock(at row: Int, column: Int) {
        guard let block = selectedBlock else { return }
        
        var newGrid = grid
        for (r, rows) in block.shape.enumerated() {
            for (c, cell) in rows.enumerated() {
                if cell {
                    let newRow = (row + r).clamped(to: 0..<grid.count)
                    let newCol = (column + c).clamped(to: 0..<grid[0].count)
                    newGrid[newRow][newCol] = true
                }
            }
        }
        
        grid = newGrid
        checkForCompletedRows()
        
        // Wake the cat
        NotificationCenter.default.post(name: .resetIdleTimer, object: nil)
        
        DispatchQueue.main.async {
            selectedBlock = nil
            isDragging = false
            blockPosition = nil
        }
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
    
    // First extract the cell creation logic into a separate function
    private func makeCell(row: Int, column: Int) -> some View {
        let isFilled = grid[row][column]
        _ = isDraggingOver(row: row, column: column) // Silence warning
        let isValidPlacement = canPlaceBlock(at: row, column: column)
        
        return CellView(
            isOccupied: isFilled,
            row: row,
            column: column,
            selectedBlock: selectedBlock,
            isPreview: isDragging && selectedBlock != nil
        )
        .frame(width: cellSize, height: cellSize)
        .background(
            ZStack {
                if isValidPlacement {
                    Color.clear
                } else {
                    Color.red.opacity(0.15)
                }
                if isDraggingOver(row: row, column: column) {
                    Theme.primary.opacity(0.1)
                }
            }
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let location = value.location
                    blockPosition = location
                    isDragging = true
                    
                    // Convert touch location to grid coordinates
                    let column = Int((location.x / cellSize).rounded(.down))
                    let row = Int((location.y / cellSize).rounded(.down))
                    
                    if canPlaceBlock(at: row, column: column) {
                        touchCoordinator.currentPosition = CGPoint(x: column, y: row)
                    }
                }
                .onEnded { value in
                    let location = value.location
                    let column = Int((location.x / cellSize).rounded(.down))
                    let row = Int((location.y / cellSize).rounded(.down))
                    
                    if canPlaceBlock(at: row, column: column) {
                        placeBlock(at: row, column: column)
                    }
                    
                    isDragging = false
                    blockPosition = nil
                    selectedBlock = nil
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
                ForEach(0..<grid[row].count, id: \.self) { column in
                    makeCell(column)
                }
            }
        }
    }
    
    // Then simplify the main body
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: Theme.Layout.gridSpacing) {
                ForEach(0..<grid.count, id: \.self) { row in
                    GridRowView(
                        row: row,
                        grid: grid,
                        cellSize: cellSize,
                        makeCell: { column in
                            AnyView(self.makeCell(row: row, column: column))
                        }
                    )
                }
            }
            .frame(
                width: cellSize * 10 + Theme.Layout.gridSpacing * 9,
                height: cellSize * 10 + Theme.Layout.gridSpacing * 9
            )
            .modifier(GridStyleModifier())
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .contentShape(Rectangle())
            .onTapGesture { location in
                handleGridTap(location: location, geometry: geometry)
            }
        }
    }
    
    // Extract tap handler logic
    private func handleGridTap(location: CGPoint, geometry: GeometryProxy) {
        let gridFrame = CGRect(
            x: (geometry.size.width - (cellSize * 10 + Theme.Layout.gridSpacing * 9)) / 2,
            y: (geometry.size.height - (cellSize * 10 + Theme.Layout.gridSpacing * 9)) / 2,
            width: cellSize * 10 + Theme.Layout.gridSpacing * 9,
            height: cellSize * 10 + Theme.Layout.gridSpacing * 9
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
        
        touchCoordinator.touchLocation = gridLocation
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            touchCoordinator.touchLocation = nil
        }
    }
}

struct GridStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .fill(Color(hex: "F5E6D3")) // Warm paper color
                    .shadow(
                        color: Color(hex: "8B4513").opacity(0.2),
                        radius: 12,
                        x: 0,
                        y: 8
                    )
            )
            .overlay(
                GridLines()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.gridLine.opacity(0.2), Theme.gridLine.opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .rotation3DEffect(
                .degrees(8),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.2
            )
    }
}

struct GridLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gridSize = 10
        let cellSize = rect.width / CGFloat(gridSize)
        
        // Draw minimal grid lines
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