import SwiftUI

struct ContentView: View {
    @StateObject private var gridState = GridState(size: 10)
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05)
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Layout.spacing) {
                HStack(spacing: Theme.Layout.spacing) {
                    GamePanel(score: gridState.score, currentStreak: gridState.currentStreak)
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
                
                GridView(state: gridState)
                    .padding(.horizontal, Theme.Layout.padding)
                
                Spacer()
                
                BlockSelectionView(state: gridState)
                    .frame(height: 120)
                    .padding(.horizontal, Theme.Layout.padding)
                    .padding(.bottom, 20)
            }
            
            if let block = gridState.selectedBlock, gridState.isDragging {
                DraggableBlock(block: block, state: gridState)
            }
            
            // Add Debug Panel in DEBUG mode only
            #if DEBUG
            VStack {
                DebugPanel(state: gridState)
                    .frame(width: 200)
                    .padding()
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            #endif
        }
        .coordinateSpace(name: "gameArea")
    }
}

#Preview {
    ContentView()
}
