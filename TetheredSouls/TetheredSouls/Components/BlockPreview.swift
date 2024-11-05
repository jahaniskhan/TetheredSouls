import SwiftUI

struct BlockPreview: View {
    let block: Block
    let isSelected: Bool
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(block.shape.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 2) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                        Rectangle()
                            .fill(cell ? block.color.color : Color.clear)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Rectangle()
                                    .stroke(isHovered && cell ? block.color.color.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(Theme.surface)
        .overlay(
            Rectangle()
                .stroke(isSelected ? Theme.primary : Theme.stroke, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
