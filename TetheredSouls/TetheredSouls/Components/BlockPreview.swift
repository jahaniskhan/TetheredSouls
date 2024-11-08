import SwiftUI

struct BlockPreview: View {
    let block: Block
    let isSelected: Bool
    @State private var isHovered = false
    @State private var wobblePhase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(block.shape.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 2) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                        if cell {
                            DrawingTheme.Shapes.handDrawnRect(
                                CGRect(x: 0, y: 0, width: 100, height: 100)
                            )
                            .fill(block.color.color)
                            .overlay(
                                DrawingTheme.Shapes.handDrawnRect(
                                    CGRect(x: 0, y: 0, width: 100, height: 100)
                                )
                                .stroke(
                                    isHovered ? block.color.color.opacity(0.3) : Color.clear,
                                    lineWidth: DrawingTheme.LineStyle.thin
                                )
                            )
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            DrawingTheme.Shapes.handDrawnRect(
                CGRect(x: 0, y: 0, width: 100, height: 100)
            )
            .stroke(
                isSelected ? DrawingTheme.Colors.sunflower : DrawingTheme.Colors.charcoal,
                lineWidth: DrawingTheme.LineStyle.medium
            )
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
