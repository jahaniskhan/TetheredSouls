import SwiftUI
import Foundation

struct BlockSelectionView: View {
    @ObservedObject var state: GridState
    
    var body: some View {
        VStack(spacing: 0) {
            // Timer and controls bar
            HStack {
                Text("NEXT")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                
                Button(action: { state.togglePause() }) {
                    Image(systemName: state.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Text(String(format: "%02d", Int(state.timeRemaining)))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.background.opacity(0.3))
            
            // Next blocks preview
            HStack(spacing: 8) {
                ForEach(state.nextBlocks) { block in
                    BlockPreview(block: block, isSelected: false)
                        .frame(width: 40, height: 40)
                        .opacity(0.5)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 65, maximum: 65), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(state.availableBlocks) { block in
                        BlockCard(
                            block: block,
                            isSelected: state.selectedBlock?.id == block.id,
                            count: state.inventory[block.id] ?? 0,
                            onDragStarted: { location in
                                state.selectBlock(block, at: location)
                            }
                        )
                    }
                }
                .padding(12)
            }
            .frame(height: 180)
        }
        .background(Theme.surface)
        .cornerRadius(8)
    }
}

struct BlockCard: View {
    let block: Block
    let isSelected: Bool
    let count: Int
    let onDragStarted: (CGPoint) -> Void
    
    var body: some View {
        BlockPreview(block: block, isSelected: isSelected)
            .frame(width: 65, height: 65)
            .background(Theme.background)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        count > 0 ? Theme.primary : Theme.stroke,
                        lineWidth: 1
                    )
                    .opacity(count > 0 ? 0.3 : 0.1)
            )
            .overlay(
                Circle()
                    .fill(count > 0 ? Theme.primary : Theme.stroke)
                    .frame(width: 4, height: 4)
                    .offset(x: -26, y: -26),
                alignment: .topTrailing
            )
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if count > 0 {
                            onDragStarted(value.location)
                        }
                    }
            )
            .contentShape(Rectangle())
    }
}

// Move Preview provider outside the main view struct
struct BlockSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        BlockSelectionView(state: GridState(size: 10))
            .padding()
            .background(Color.black)
    }
}
