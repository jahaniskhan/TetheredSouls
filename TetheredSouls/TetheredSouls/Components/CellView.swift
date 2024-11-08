import SwiftUI
import Foundation

struct CellView: View {
    let isOccupied: Bool
    let row: Int
    let column: Int
    let selectedBlock: Block?
    let isPreview: Bool
    let placedBlockColor: BlockColor?
    var onPlace: ((Int, Int) -> Void)?
    
    var body: some View {
        ZStack {
            // Base cell
            DrawingTheme.Shapes.handDrawnRect(
                CGRect(x: 0, y: 0, width: 100, height: 100)
            )
            .fill(backgroundColor)
            
            // Cell border
            DrawingTheme.Shapes.handDrawnRect(
                CGRect(x: 0, y: 0, width: 100, height: 100)
            )
            .stroke(DrawingTheme.Colors.charcoal, lineWidth: DrawingTheme.LineStyle.thin)
            
            // Preview overlay
            if isPreview {
                DrawingTheme.Shapes.handDrawnRect(
                    CGRect(x: 2, y: 2, width: 96, height: 96)
                )
                .stroke(
                    selectedBlock?.color.color ?? DrawingTheme.Colors.charcoal,
                    lineWidth: DrawingTheme.LineStyle.medium
                )
            }
        }
        .onTapGesture {
            onPlace?(row, column)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    onPlace?(row, column)
                }
        )
    }
    
    private var backgroundColor: Color {
        if isPreview {
            return selectedBlock?.color.color.opacity(0.15) ?? DrawingTheme.Colors.cream
        }
        if isOccupied {
            return placedBlockColor?.color ?? DrawingTheme.Colors.sage
        }
        return DrawingTheme.Colors.cream.opacity(0.05)
    }
}
