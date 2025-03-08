import SwiftUI

struct BlockSelectionView: View {
    @Binding var availableBlocks: [Block]
    @Binding var selectedBlock: Block?
    @Binding var blockPosition: CGPoint?
    @Binding var isDragging: Bool
    
    // Track which block is being dragged
    @State private var draggedBlockId: UUID? = nil
    @State private var hoveredBlockId: UUID? = nil
    @State private var isExpanded = false
    @State private var heartBeat = false
    @State private var headerHover = false
    
    // Updated colors as requested
    private let headerBackground = Color(hex: "ACD1AF")  // Sage green banner
    private let panelBackground = Color.white            // White panel
    private let textColor = Color.white                  // White text for contrast
    private let borderColor = Color(hex: "ACD1AF")       // Sage green border
    
    var body: some View {
        VStack(spacing: 0) {
            // Thinner header with love message in true cursive font
            HStack(alignment: .center) {
                Text("i love you")
                    .font(.custom("Snell Roundhand", size: 22))  // True cursive font
                    .foregroundColor(textColor)
                    .padding(.leading, 16)
                
                Spacer()
                
                // Heart icon with breathing animation
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))  // Smaller heart to match thinner header
                    .foregroundColor(textColor)
                    .scaleEffect(heartBeat ? 1.15 : 1.0)
                    .opacity(heartBeat ? 1.0 : 0.85)
                    .animation(
                        Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true), 
                        value: heartBeat
                    )
                    .onAppear { heartBeat = true }
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 8)  // Reduced vertical padding for thinner header
            .background(headerBackground)
            
            // Blocks container with subtle animations
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(availableBlocks) { block in
                        BlockItemView(
                            block: block,
                            isSelected: selectedBlock?.id == block.id,
                            isDragged: draggedBlockId == block.id,
                            isHovered: hoveredBlockId == block.id,
                            onHoverChanged: { hovering in
                                withAnimation(.spring(response: 0.3)) {
                                    hoveredBlockId = hovering ? block.id : nil
                                }
                            },
                            onDragChanged: { value in
                                handleDragChange(value: value, block: block)
                            },
                            onDragEnded: { value in
                                handleDragEnd(value: value, block: block)
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.7)),
                            removal: .scale(scale: 0.6).combined(with: .opacity).animation(.easeOut(duration: 0.2))
                        ))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .frame(height: 100)
            .background(panelBackground)
        }
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(borderColor, lineWidth: 2)
                .opacity(0.9)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 8)
        .scaleEffect(isExpanded ? 1.0 : 0.95)
        .opacity(isExpanded ? 1.0 : 0.8)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isExpanded = true
            }
        }
    }
    
    private func handleDragChange(value: DragGesture.Value, block: Block) {
        blockPosition = value.location
        selectedBlock = block
        isDragging = true
        withAnimation(.spring(response: 0.3)) {
            draggedBlockId = block.id
        }
    }
    
    private func handleDragEnd(value: DragGesture.Value, block: Block) {
        if GridView.validatePlacement(at: value.location) {
            withAnimation(.easeOut(duration: 0.2)) {
                availableBlocks.removeAll { $0.id == block.id }
                draggedBlockId = nil
            }
            playHapticFeedback()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                draggedBlockId = nil
            }
        }
        isDragging = false
        selectedBlock = nil
    }
    
    private func playHapticFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct BlockItemView: View {
    let block: Block
    let isSelected: Bool
    let isDragged: Bool
    let isHovered: Bool
    let onHoverChanged: (Bool) -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    
    @State private var placeholderPhase = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Placeholder animation with colored dotted lines
            if isDragged {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: [6, 4],
                            dashPhase: CGFloat(placeholderPhase)
                        )
                    )
                    .foregroundColor(Color(hex: "ACD1AF"))  // Sage green
                    .frame(width: 60, height: 60)
                    .onAppear {
                        withAnimation(.linear.repeatForever(autoreverses: false)) {
                            placeholderPhase += 24
                        }
                    }
            }
            
            // Main block with subtle float animation
            if !isDragged {
                BlockPreview(block: block, isSelected: isSelected)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .shadow(
                        color: Color(hex: "ACD1AF").opacity(isHovered ? 0.3 : 0.1),
                        radius: isHovered ? 3 : 1,
                        x: 0,
                        y: isHovered ? 2 : 1
                    )
                    .offset(y: isAnimating ? -1 : 0)
                    .animation(
                        Animation.easeInOut(duration: 1.5 + Double.random(in: 0...1))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...1.5)),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onHover { hovering in
            onHoverChanged(hovering)
        }
        .gesture(
            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
    }
}

struct BlockFrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct InventoryFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct BlockSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        BlockSelectionView(
            availableBlocks: .constant(Block.blocks),
            selectedBlock: .constant(nil),
            blockPosition: .constant(nil),
            isDragging: .constant(false)
        )
        .padding()
        .background(Color.black.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
