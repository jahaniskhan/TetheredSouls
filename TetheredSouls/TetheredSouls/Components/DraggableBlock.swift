import SwiftUI
import CoreGraphics
import Dispatch

extension CoordinateSpace {
    static let gameArea = CoordinateSpace.named("gameArea")
}

struct DraggableBlock: View {
    // MARK: - Configuration
    private enum Constants {
        static let blockSize: CGFloat = 60
        static let throttleInterval: DispatchTimeInterval = .milliseconds(16)
        static let returnAnimation = Animation.interactiveSpring(
            response: 0.3, 
            dampingFraction: 0.86
        )
    }
    
    // MARK: - Properties
    @Binding var selectedBlock: Block?
    @Binding var position: CGPoint?
    @Binding var isDragging: Bool
    @Binding var grid: [[Bool]]
    
    let block: Block
    @State private var initialPosition: CGPoint = .zero
    @State private var lastUpdateTime: DispatchTime?
    
    // MARK: - Gesture Handling
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                position = value.location
            }
            .onEnded { value in
                let cellSize = (UIScreen.main.bounds.width - (2 * Theme.Layout.padding)) / CGFloat(grid[0].count)
                let snappedPosition = CGPoint(
                    x: round(value.location.x / cellSize) * cellSize,
                    y: round(value.location.y / cellSize) * cellSize
                )
                
                let column = Int((snappedPosition.x / cellSize).rounded())
                let row = Int((snappedPosition.y / cellSize).rounded())
                
                if row >= 0 && row < grid.count && column >= 0 && column < grid[0].count,
                   canPlaceBlock(at: row, column: column) {
                    position = snappedPosition
                    grid[row][column] = true
                    isDragging = false
                    selectedBlock = nil
                } else {
                    returnToInventory()
                }
            }
    }
    
    private func returnToInventory() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            position = initialPosition
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.position = nil
            self.selectedBlock = nil
        }
    }
    
    // MARK: - Position Calculations
    private func calculateFinalPosition(from value: DragGesture.Value) -> CGPoint {
        // Using game area coordinates directly
        return value.location
    }
    
    // MARK: - Placement Logic
    private var isValidPlacement: Bool {
        guard let position = position else { return false }
        let (column, row) = convertToGridCoordinates(position)
        return canPlaceBlock(at: row, column: column)
    }
    
    private func commitPosition(_ position: CGPoint) {
        GridTouchCoordinator.shared.currentPosition = position
    }
    
    // MARK: - Grid Calculations
    private func convertToGridCoordinates(_ position: CGPoint) -> (column: Int, row: Int) {
        let cellSize = (UIScreen.main.bounds.width - (2 * Theme.Layout.padding)) / CGFloat(grid[0].count)
        return (
            column: Int((position.x / cellSize).rounded()),
            row: Int((position.y / cellSize).rounded())
        )
    }
    
    private func convertGridToPosition(column: Int, row: Int) -> CGPoint {
        let cellSize = (UIScreen.main.bounds.width - (2 * Theme.Layout.padding)) / CGFloat(grid[0].count)
        return CGPoint(
            x: CGFloat(column) * cellSize + cellSize/2,
            y: CGFloat(row) * cellSize + cellSize/2
        )
    }
    
    private func canPlaceBlock(at row: Int, column: Int) -> Bool {
        return !grid[row][column]
    }
    
    // MARK: - View Body
    var body: some View {
        ZStack {
            if let position = position {
                BlockPreview(block: block, isSelected: false)
                    .frame(width: Constants.blockSize, height: Constants.blockSize)
                    .position(position)
                    .gesture(dragGesture)
                    .transaction { $0.animation = Constants.returnAnimation }
                    .onChange(of: position) { _, newValue in
                        GridTouchCoordinator.shared.currentPosition = newValue
                    }
            }
        }
        .onAppear {
            initialPosition = position ?? .zero
        }
        .onDisappear(perform: resetPosition)
    }
    
    private func resetPosition() {
        position = nil
        initialPosition = .zero
    }
    
    private var validatedPosition: CGPoint {
        guard let pos = position, pos.x.isFinite, pos.y.isFinite else {
            return initialPosition
        }
        return pos
    }
}

// MARK: - Preview
struct DraggableBlock_Previews: PreviewProvider {
    static var previews: some View {
        DraggableBlock(
            selectedBlock: .constant(nil),
            position: .constant(CGPoint(x: 100, y: 100)),
            isDragging: .constant(false),
            grid: .constant(Array(repeating: Array(repeating: false, count: 10), count: 10)),
            block: Block(
                shape: [[true]],
                color: .softCoral,
                symbol: "square"
            )
        )
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
