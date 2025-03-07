import SwiftUI

struct BlockSelectionView: View {
    @Binding var availableBlocks: [Block]
    @Binding var selectedBlock: Block?
    @Binding var blockPosition: CGPoint?
    @Binding var isDragging: Bool
    
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
                        ForEach(availableBlocks.indices, id: \.self) { index in
                            let block = availableBlocks[index]
                            GeometryReader { geo in
                                blockPreview(for: block, index: index, geometry: geo)
                            }
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
    
    private func dragGesture(for block: Block, geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named("gameArea"))
            .onChanged { value in
                let startPosition = geometry.frame(in: .named("gameArea")).origin
                let translation = value.translation
                
                blockPosition = CGPoint(
                    x: startPosition.x + translation.width,
                    y: startPosition.y + translation.height
                )
                selectedBlock = block
                isDragging = true
                
                // Store initial touch location
                GridTouchCoordinator.shared.touchLocation = blockPosition
            }
            .onEnded { value in
                if GridTouchCoordinator.shared.isBlockActive {
                    // Remove from inventory on successful placement
                    availableBlocks.removeAll { $0.id == block.id }
                } else {
                    withAnimation(.spring()) {
                        blockPosition = nil
                    }
                    // Add subtle return animation if needed
                }
                isDragging = false
            }
    }
    
    private func blockPreview(for block: Block, index: Int, geometry: GeometryProxy) -> some View {
        BlockPreview(block: block, isSelected: false)
            .frame(width: 80, height: 80)
            .position(blockPosition(for: index, block: block, geometry: geometry))
            .highPriorityGesture(dragGesture(for: block, geometry: geometry))
    }
    
    // Add proper block positioning in scroll view
    private func blockPosition(for index: Int, block: Block, geometry: GeometryProxy) -> CGPoint {
        let itemSize: CGFloat = 80
        let spacing: CGFloat = 15
        let xPosition = (itemSize + spacing) * CGFloat(index) + itemSize/2
        return CGPoint(x: xPosition, y: geometry.size.height/2)
    }
}

// Move Preview provider outside the main view struct
struct BlockSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        BlockSelectionView(
            availableBlocks: .constant(Block.blocks),
            selectedBlock: .constant(nil),
            blockPosition: .constant(nil),
            isDragging: .constant(false)
        )
        .padding()
        .background(Color.black)
    }
}