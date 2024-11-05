import SwiftUI

struct BlockSelectionView: View {
    @Binding var selectedBlock: Block?
    @Binding var blockPosition: CGPoint?
    @Binding var isDragging: Bool
    let availableBlocks: [Block] = Block.blocks
    
    var body: some View {
        VStack(spacing: 8) {
            Text("AVAILABLE BLOCKS")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableBlocks) { block in
                        BlockPreview(block: block, isSelected: selectedBlock?.id == block.id)
                            .frame(width: 60, height: 60)
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
                .padding(Theme.Layout.padding)
                .background(Theme.surface)
                .cornerRadius(Theme.Layout.cornerRadius)
            }
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