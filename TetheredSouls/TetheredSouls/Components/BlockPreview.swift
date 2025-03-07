import SwiftUI

struct BlockPreview: View {
    let block: Block
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Pure geometric form as originally designed
            RoundedRectangle(cornerRadius: 12)
                .fill(block.color.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        // Temporary dashed placeholder until Theme is fixed
                        .strokeBorder(Color.black.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [4]))
                )
                .frame(width: 60, height: 60)
        }
        .scaleEffect(isSelected ? 1.1 : 1)
        .shadow(color: .black.opacity(0.3), radius: isSelected ? 8 : 4, x: 0, y: 2)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
