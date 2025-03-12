import SwiftUI

struct BlockPreview: View {
    let block: Block
    let gridGeometry: GridGeometry
    var isSelected: Bool = false
    var scale: CGFloat = 1.0
    var cellSize: CGFloat? = nil // Allow overriding cell size from outside
    let namespace: Namespace.ID
    
    // Compute the dimensions of the block
    private var blockDimensions: (rows: Int, cols: Int) {
        let rows = block.shape.count
        let cols = block.shape.isEmpty ? 0 : block.shape[0].count
        return (rows, cols)
    }
    
    var body: some View {
        let (rows, cols) = blockDimensions
        
        GeometryReader { geometry in
            ZStack {
                // Background for hit testing
                Color.clear
                
                // Block cells
                VStack(spacing: 0) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<cols, id: \.self) { col in
                                if row < block.shape.count && col < block.shape[row].count && block.shape[row][col] {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(block.color.color)
                                        .frame(width: getCellSize(geometry, rows: rows, cols: cols), 
                                               height: getCellSize(geometry, rows: rows, cols: cols))
                                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                                } else {
                                    Color.clear
                                        .frame(width: getCellSize(geometry, rows: rows, cols: cols),
                                               height: getCellSize(geometry, rows: rows, cols: cols))
                                }
                            }
                        }
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .scaleEffect(scale)
                .opacity(isSelected ? 0.8 : 1.0)
            }
        }
        .frame(
            width: (cellSize ?? gridGeometry.cellSize) * CGFloat(block.shape[0].count),
            height: (cellSize ?? gridGeometry.cellSize) * CGFloat(block.shape.count)
        )
        .rotationEffect(.degrees(block.randomRotation))
        .matchedGeometryEffect(id: "block-preview-\(block.id)", in: namespace)
    }
    
    private func getCellSize(_ geometry: GeometryProxy, rows: Int, cols: Int) -> CGFloat {
        if let size = cellSize {
            return size
        } else {
            let availableSize = min(geometry.size.width, geometry.size.height)
            let maxDimension = max(rows, cols)
            return availableSize / CGFloat(maxDimension)
        }
    }
}

struct BlockPreview_Previews: PreviewProvider {
    // Create a Namespace wrapper for previews
    private struct NamespaceWrapper: View {
        @Namespace var namespace
        
        var body: some View {
            BlockPreview(
                block: Block(shape: [[true]], color: .softCoral, symbol: "square"),
                gridGeometry: GridGeometry(
                    frame: .zero,
                    cellSize: 30
                ),
                namespace: namespace
            )
        }
    }
    
    static var previews: some View {
        NamespaceWrapper()
            .frame(width: 150, height: 150)
            .background(Color.white)
            .cornerRadius(8)
            .padding()
            .background(Color.gray.opacity(0.1))
            .previewLayout(.sizeThatFits)
    }
}
