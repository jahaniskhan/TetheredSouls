import SwiftUI
import CoreGraphics
import Dispatch

extension CoordinateSpace {
    static let gameArea = CoordinateSpace.named("gameArea")
}

struct DraggableBlock: View {
    // MARK: - Configuration
    private enum Constants {
        static let throttleInterval: DispatchTimeInterval = .milliseconds(16)
        static let returnAnimation = Animation.interactiveSpring(
            response: 0.3, 
            dampingFraction: 0.86
        )
        static let blockSize: CGFloat = 60.0
    }
    
    // MARK: - Properties
    @Binding var selectedBlock: Block?
    @Binding var isDragging: Bool
    @Binding var blockPosition: CGPoint?
    @Binding var grid: [[Bool]]
    @Binding var projectedCells: [(row: Int, column: Int)]
    let block: Block
    let gridGeometry: GridGeometry
    
    @State private var dragOffset: CGSize = .zero
    @State private var dragStart: CGPoint?
    @State private var lastUpdateTime: Date = Date()
    
    private let projectionCoordinator = GridProjectionCoordinator.shared
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            if let block = selectedBlock {
                ZStack {
                    ForEach(0..<block.shape.count, id: \.self) { rowIndex in
                        ForEach(0..<block.shape[rowIndex].count, id: \.self) { colIndex in
                            if block.shape[rowIndex][colIndex] {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(block.color.color)
                                    .frame(
                                        width: gridGeometry.cellSize - 2,
                                        height: gridGeometry.cellSize - 2
                                    )
                                    .offset(
                                        x: CGFloat(colIndex) * gridGeometry.cellSize,
                                        y: CGFloat(rowIndex) * gridGeometry.cellSize
                                    )
                            }
                        }
                    }
                }
                .opacity(0.8)
                .offset(dragOffset)
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            self.isDragging = true
                            
                            // Throttle updates for performance
                            let now = Date()
                            if now.timeIntervalSince(lastUpdateTime) >= 0.016 {
                                self.lastUpdateTime = now
                                
                                if dragStart == nil {
                                    dragStart = value.startLocation
                                }
                                
                                self.dragOffset = value.translation
                                
                                // Use the location from global space
                                self.blockPosition = value.location
                                
                                // Calculate grid projection coordinates
                                calculateGridProjection(at: value.location)
                            }
                        }
                        .onEnded { value in
                            // Attempt to place the block
                            handleDragEnded(at: value.location)
                        }
                )
                .position(
                    x: blockPosition?.x ?? geometry.size.width / 2,
                    y: blockPosition?.y ?? geometry.size.height / 2
                )
                .zIndex(3)
            }
        }
    }
    
    // MARK: - Methods
    private func calculateGridProjection(at position: CGPoint) {
        guard let block = selectedBlock else { return }
        
        #if DEBUG
        print("DraggableBlock - Position: \(position)")
        print("DraggableBlock - Grid frame in coordinator: \(projectionCoordinator.gridFrame)")
        #endif
        
        // Use coordinator to get grid cell 
        guard let (row, col) = projectionCoordinator.calculateGridCell(at: position) else {
            // Position is outside the grid
            projectionCoordinator.projectedCells = []
            return
        }
        
        // Create array of affected cells based on block shape
        var projectedCells: [(row: Int, column: Int)] = []
        
        for blockRow in 0..<block.shape.count {
            for blockCol in 0..<block.shape[blockRow].count {
                if block.shape[blockRow][blockCol] {
                    let gridRow = row + blockRow
                    let gridCol = col + blockCol
                    
                    // Only add cells that are within grid bounds
                    if gridRow >= 0 && gridRow < 10 && gridCol >= 0 && gridCol < 10 {
                        projectedCells.append((row: gridRow, column: gridCol))
                    }
                }
            }
        }
        
        #if DEBUG
        if !projectedCells.isEmpty {
            print("Projected cells: \(projectedCells)")
        }
        #endif
        
        // Update the shared projection coordinator
        projectionCoordinator.projectedCells = projectedCells
    }
    
    private func handleDragEnded(at position: CGPoint) {
        self.isDragging = false
        self.dragOffset = .zero
        self.dragStart = nil
        self.blockPosition = nil
        
        // Clear projection
        projectionCoordinator.projectedCells = []
        
        // Logic to finalize block placement would go here
        // This could call into your game state manager
    }
}

// MARK: - Preview
struct DraggableBlock_Previews: PreviewProvider {
    static var previews: some View {
        DraggableBlock(
            selectedBlock: .constant(nil),
            isDragging: .constant(false),
            blockPosition: .constant(CGPoint(x: 100, y: 100)),
            grid: .constant(Array(repeating: Array(repeating: false, count: 10), count: 10)),
            projectedCells: .constant([]),
            block: Block(shape: [[true]], color: .softCoral, symbol: "square"),
            gridGeometry: GridGeometry(frame: .zero, cellSize: 30)
        )
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
