import SwiftUI

struct BlockSelectionView: View {
    @Binding var selectedBlock: Block?
    @Binding var blockPosition: CGPoint?
    @Binding var isDragging: Bool
    let availableBlocks: [Block] = Block.blocks
    
    var body: some View {
        VStack(spacing: 0) {
            // Unified tab design
            VStack(spacing: 0) {
                Text("AVAILABLE BLOCKS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Theme.secondary)
                
                // Block selection with stamp effect
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(availableBlocks) { block in
                            BlockPreview(block: block, isSelected: selectedBlock?.id == block.id)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                                .rotationEffect(.degrees(Double(block.id.hashValue % 5) - 2))
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            if selectedBlock == nil {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedBlock = block
                                                    isDragging = true
                                                    blockPosition = value.location
                                                }
                                            }
                                        }
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Theme.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
    }
}

// Move Preview provider outside the main view struct
struct BlockSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        BlockSelectionView(
            selectedBlock: .constant(nil),
            blockPosition: .constant(nil),
            isDragging: .constant(false)
        )
        .padding()
        .background(Color.black)
    }
}