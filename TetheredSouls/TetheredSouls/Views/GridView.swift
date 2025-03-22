import SwiftUI
import CoreGraphics

// Create a shared coordinator to handle projection
class GridProjectionCoordinator: ObservableObject {
    static let shared = GridProjectionCoordinator()
    @Published var projectedCells: [(row: Int, column: Int)] = []
    
    // Add these properties to store grid geometry
    var gridFrame: CGRect = .zero
    var cellSize: CGFloat = 30
    
    private init() {}
    
    // Method to convert global coordinates to grid-relative
    func convertToGridPosition(globalPosition: CGPoint) -> CGPoint {
        return CGPoint(
            x: globalPosition.x - gridFrame.origin.x,
            y: globalPosition.y - gridFrame.origin.y
        )
    }
    
    // Method to calculate row and column from position
    func calculateGridCell(at position: CGPoint) -> (row: Int, column: Int)? {
        let relativePosition = convertToGridPosition(globalPosition: position)
        
        let row = Int(relativePosition.y / cellSize)
        let column = Int(relativePosition.x / cellSize)
        
        // Check if within grid bounds
        if row >= 0 && row < 10 && column >= 0 && column < 10 {
            return (row, column)
        }
        return nil
    }
}

struct GridView: View {
    @Binding var grid: [[Bool]]
    @Binding var selectedBlock: Block?
    @Binding var blockPosition: CGPoint?
    @Binding var isDragging: Bool
    @StateObject private var touchCoordinator = GridTouchCoordinator.shared
    @ObservedObject private var projectionCoordinator = GridProjectionCoordinator.shared
    
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
        
        // Check if all cells required by the block can be placed
        for blockRow in 0..<block.shape.count {
            for blockCol in 0..<block.shape[blockRow].count {
                if block.shape[blockRow][blockCol] {
                    let gridRow = row + blockRow
                    let gridCol = column + blockCol
                    
                    // Check bounds
                    if gridRow < 0 || gridRow >= grid.count || gridCol < 0 || gridCol >= grid[0].count {
                        return false
                    }
                    
                    // Check if cell is already occupied
                    if grid[gridRow][gridCol] {
                        return false
                    }
                }
            }
        }
        
        return true
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
        guard let block = selectedBlock else { return }
        
        // Place the block in the grid
        for (r, blockRow) in block.shape.enumerated() {
            for (c, isSet) in blockRow.enumerated() {
                if isSet {
                    let gridRow = row + r
                    let gridCol = column + c
                    if gridRow < grid.count && gridCol < grid[0].count {
                        grid[gridRow][gridCol] = true
                    }
                }
            }
        }
        
        // After placing block, trigger animation - use withAnimation to make it smoother
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            // Update the streak directly - this triggers the doodle animations
            GameStateManager.shared.currentStreak += 1
            
            // Add haptic feedback for placement
            HapticManager.triggerPlacementFeedback()
            
            // Notify about block placement for doodle animations
            NotificationCenter.default.post(
                name: Notification.Name.blockPlaced, 
                object: nil, 
                userInfo: [
                    "position": CGPoint(x: column, y: row),
                    "blockType": block.symbol
                ]
            )
        }
        
        // Check for completed rows
        checkForCompletedRows()
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
        let isInProjection = projectionCoordinator.projectedCells.contains { $0.row == row && $0.column == column }
        let isValidPlacement = isInProjection && canPlaceBlock(at: row, column: column)
        
        return CellView(
            isOccupied: isFilled,
            row: row,
            column: column,
            selectedBlock: self.selectedBlock,
            isPreview: self.isDragging && isInProjection
        )
        .frame(width: self.cellSize, height: self.cellSize)
        .background(
            ZStack {
                if isDragging && isInProjection {
                    Rectangle()
                        .fill(isValidPlacement ? 
                              Color.green.opacity(0.3) : 
                              Color.red.opacity(0.3))
                        .animation(.easeOut(duration: 0.2), value: isValidPlacement)
                }
            }
        )
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    let location = value.location
                    self.blockPosition = location
                    self.isDragging = true
                    
                    // Update touch location for cat eye tracking
                    self.touchCoordinator.touchLocation = location
                    
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
                    
                    // Keep touch visible for a moment before resetting
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.touchCoordinator.touchLocation = nil
                    }
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
                // Don't process tap if we're in the middle of a drag operation
                if !self.isDragging {
                    self.handleGridTap(location: location, geometry: geometry)
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: GridGeometryKey.self,
                            value: GridGeometry(
                                frame: geo.frame(in: .global),
                                cellSize: self.cellSize
                            )
                        )
                }
            )
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
        
        // Use underscore for unused variable to avoid warning
        _ = CGPoint(
            x: location.x - gridFrame.minX,
            y: location.y - gridFrame.minY
        )
        
        // Convert to global coordinates for cat eye tracking
        if let globalPosition = getGlobalPosition(for: location, in: geometry) {
            self.touchCoordinator.touchLocation = globalPosition
            
            // Store current gesture mode
            let currentMode = GestureMode.current
            
            // Temporarily switch to cat interaction mode
            GestureMode.current = .catInteraction
            
            // Notify everyone about the mode change
            NotificationCenter.default.post(
                name: .init("GestureModeChanged"),
                object: GestureMode.catInteraction
            )
            
            // Reset the mode after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Only reset if no drag started
                if !self.isDragging {
                    GestureMode.current = currentMode
                    
                    // Reset touch location if it hasn't been updated
                    self.touchCoordinator.touchLocation = nil
                    
                    // Notify everyone about the mode change back
                    NotificationCenter.default.post(
                        name: .init("GestureModeChanged"),
                        object: currentMode
                    )
                }
            }
        }
    }
    
    // Helper to convert to global coordinates
    private func getGlobalPosition(for point: CGPoint, in geometry: GeometryProxy) -> CGPoint? {
        // Get the grid's global frame
        let globalFrame = geometry.frame(in: .global)
        
        // Convert the local point to global coordinates
        return CGPoint(
            x: globalFrame.minX + point.x,
            y: globalFrame.minY + point.y
        )
    }
    
    static func validatePlacement(at position: CGPoint) -> Bool {
        #if DEBUG
        print("Validating placement at position: \(position)")
        print("Grid frame in coordinator: \(GridProjectionCoordinator.shared.gridFrame)")
        #endif
        
        // Use coordinator to calculate grid cell
        guard let (row, column) = GridProjectionCoordinator.shared.calculateGridCell(at: position) else {
            return false
        }
        
        #if DEBUG
        print("Calculated grid cell: (\(row), \(column))")
        #endif
        
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

struct GridGeometryKey: PreferenceKey {
    static var defaultValue = GridGeometry(frame: .zero, cellSize: 30)
    static func reduce(value: inout GridGeometry, nextValue: () -> GridGeometry) {
        value = nextValue()
    }
}

struct GridGeometry: Equatable {
    let frame: CGRect
    let cellSize: CGFloat
}