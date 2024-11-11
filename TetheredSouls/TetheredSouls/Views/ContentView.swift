import SwiftUI
import Foundation
import Combine
import CoreGraphics
import CoreFoundation


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
    
    @State private var plantPhase = 0.0
    let plantTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var decorativeElements: some View {
        ZStack {
            // Static trees
            ForEach(0..<3) { i in
                Plant(height: CGFloat.random(in: 120...200), phase: 0)
                    .foregroundColor(Color(hex: "BFD8B8").opacity(0.6))
                    .frame(width: 60)
                    .position(
                        x: UIScreen.main.bounds.width * CGFloat(i + 1) / 4,
                        y: UIScreen.main.bounds.height * 0.7
                    )
            }
            
            // Animated decorative elements
            ForEach(0..<12) { i in
                let items = ["✧", "⋆", "❀"]
                Text(items[i % items.count])
                    .font(.system(size: CGFloat.random(in: 12...20)))
                    .foregroundColor(Theme.block1.opacity(0.3))
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .offset(y: -20 * sin(plantPhase + Double(i)))
                    .position(
                        x: CGFloat.random(in: 50...UIScreen.main.bounds.width-50),
                        y: CGFloat.random(in: 100...UIScreen.main.bounds.height-100)
                    )
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "FFF9F2")
                .ignoresSafeArea()
            
            // Background doodles tied to streak, now using the color property
            if currentStreak > 0 {
                ForEach(0..<min(currentStreak, 12), id: \.self) { i in
                    DoodleElement(
                        type: [.star, .heart, .spiral, .scribble][i % 4],
                        rotation: Double.random(in: -15...15),
                        streak: currentStreak
                    )
                    .frame(width: 80, height: 80)  // Made even larger
                    .position(
                        x: CGFloat.random(in: 50...UIScreen.main.bounds.width-50),
                        y: CGFloat.random(in: UIScreen.main.bounds.height * 0.3...UIScreen.main.bounds.height * 0.7)
                    )
                }
            }
            
            decorativeElements
            
            VStack(spacing: 24) {
                GamePanel(score: score, currentStreak: currentStreak, selectedBlock: selectedBlock)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                
                #if DEBUG
                GamePanelDebugger(score: $score, currentStreak: $currentStreak)
                    .padding(.horizontal, 20)
                #endif
                
                GridView(grid: $grid, selectedBlock: $selectedBlock, blockPosition: $blockPosition, isDragging: $isDragging)
                    .padding(.horizontal, 20)
                
                BlockSelectionView(selectedBlock: $selectedBlock, blockPosition: $blockPosition, isDragging: $isDragging)
                    .frame(height: 140)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            
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

struct Plant: View {
    let height: CGFloat
    let phase: Double
    
    private func wobble(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x + sin(phase * 2) * 5,
            y: point.y + cos(phase * 1.5) * 3
        )
    }
    
    var body: some View {
        Path { path in
            // Stem
            path.move(to: wobble(CGPoint(x: 30, y: height)))
            path.addQuadCurve(
                to: wobble(CGPoint(x: 30, y: 0)),
                control: wobble(CGPoint(x: 35, y: height/2))
            )
            
            // Leaves
            for i in stride(from: 10, through: height-20, by: 30) {
                let side = i.truncatingRemainder(dividingBy: 60) == 10
                let leafTip = wobble(CGPoint(x: side ? 10 : 50, y: i-10))
                path.move(to: wobble(CGPoint(x: 30, y: i)))
                path.addQuadCurve(
                    to: leafTip,
                    control: wobble(CGPoint(x: side ? 15 : 45, y: i-5))
                )
            }
        }
        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}

#Preview {
    ContentView()
}
