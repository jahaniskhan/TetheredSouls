import SwiftUI

struct ContentView: View {
    private let columns: Int = 10
    private let rows: Int = 10
    
    @State private var grid: [[Bool]] = Array(repeating: Array(repeating: false, count: 10), count: 10)
    @State private var score: Int = 0
    @State private var currentStreak: Int = 0
    @State private var isLoading = true
    @State private var selectedBlock: Block?
    @State private var isDragging = false
    @State private var blockPosition: CGPoint?
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05)
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Layout.spacing) {
                // Top bar with game panel
                HStack(spacing: Theme.Layout.spacing) {
                    GamePanel(score: score, currentStreak: currentStreak)
                        .frame(width: UIScreen.main.bounds.width * 0.7)
                    
                    Spacer()
                    
                    // FX indicators
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.tertiary)
                            .frame(width: 6, height: 6)
                        Text("FX")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, Theme.Layout.padding)
                
                Spacer()
                
                GridView(grid: $grid, selectedBlock: $selectedBlock, blockPosition: $blockPosition, isDragging: $isDragging)
                    .padding(.horizontal, Theme.Layout.padding)
                
                Spacer()
                
                BlockSelectionView(selectedBlock: $selectedBlock, blockPosition: $blockPosition, isDragging: $isDragging)
                    .frame(height: 120)
                    .padding(.horizontal, Theme.Layout.padding)
                    .padding(.bottom, 20)
            }
            
            if let block = selectedBlock, isDragging {
                DraggableBlock(
                    block: block,
                    position: $blockPosition,
                    isDragging: $isDragging,
                    grid: $grid
                )
            }
            
            if isLoading {
                LoadingView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isLoading = false
                            }
                        }
                    }
            }
        }
        .coordinateSpace(name: "gameArea")
    }
}

#Preview {
    ContentView()
}
