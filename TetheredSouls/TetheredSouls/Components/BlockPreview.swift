import SwiftUI

struct BlockPreview: View {
    let block: Block
    let isSelected: Bool
    let isValidPlacement: Bool = true
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(block.shape.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 2) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                        Rectangle()
                            .fill(cell ? (isValidPlacement ? block.color.color : Color.red.opacity(0.3)) : Color.clear)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Rectangle()
                                    .stroke(isHovered && cell ? block.color.color.opacity(0.6) : Color.clear, lineWidth: 2)
                                    .padding(1)
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(4)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Theme.primary : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
