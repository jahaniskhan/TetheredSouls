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
    @State private var eyePosition: CGPoint = .zero
    
    
  
    @State private var plantPhase: Double = 0
    let plantTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @State private var autoStreak = true
    @State private var streakTimer: Timer? = nil
    
    private func startAutoStreak() {
        streakTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if currentStreak < 3000 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStreak += 1
                    score += 500
                }
            }
        }
    }
    
    private var backgroundDoodles: some View {
        GeometryReader { geometry in
            ZStack {
                if currentStreak > 0 {
                    ForEach(0..<min(currentStreak * 3, 36), id: \.self) { i in
                        let types: [DoodleType] = {
                            if currentStreak > 15 {
                                return [.star, .heart, .semicolon, .moon, .swirl, .xSmile]
                            } else if currentStreak > 8 {
                                return [.star, .heart, .moon, .swirl]
                            } else {
                                return [.star, .heart]
                            }
                        }()
                        
                        DoodleElement(
                            type: types.randomElement() ?? .star,
                            rotation: Double.random(in: -25...25),
                            streak: currentStreak
                        )
                            .opacity(0.15)
                            .scaleEffect(0.5)
                            .offset(y: -20 * sin(plantPhase + Double(i)))
                            .position(
                                x: CGFloat.random(in: 50...geometry.size.width-50),
                                y: CGFloat.random(in: 100...geometry.size.height-100)
                            )
                    }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever()) {
                    plantPhase += .pi * 2
                }
            }
        }
    }
    
    var decorativeElements: some View {
        ZStack {
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
            
            // Add background doodles behind main content
            backgroundDoodles
            
            // Main game content
            ZStack {
                // Background doodles tied to streak
                GeometryReader { geometry in
                    if currentStreak > 0 {
                        ForEach(0..<min(currentStreak * 3, 36), id: \.self) { i in
                            let types: [DoodleType] = {
                                if currentStreak > 15 {
                                    return [.star, .heart, .semicolon, .moon, .swirl, .xSmile]
                                } else if currentStreak > 8 {
                                    return [.star, .heart, .moon, .swirl, .xSmile]
                                } else {
                                    return [.star, .heart, .xSmile]
                                }
                            }()
                            
                            DoodleElement(
                                type: types[i % types.count],
                                rotation: Double.random(in: -25...25),
                                streak: currentStreak
                            )
                            .frame(width: CGFloat.random(in: 25...45))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: geometry.size.height * 0.15...geometry.size.height * 0.95)
                            )
                            .opacity(Double.random(in: 0.6...1.0))
                            .animation(.easeInOut(duration: 0.5), value: currentStreak)
                        }
                    }
                }
                
                decorativeElements
                
                VStack(spacing: 24) {
                    GamePanel(
                        score: score,
                        currentStreak: currentStreak,
                        selectedBlock: selectedBlock
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    
                    GridView(grid: $grid, selectedBlock: $selectedBlock, blockPosition: $blockPosition, isDragging: $isDragging)
                        .padding(.horizontal, 20)
                    
                    BlockSelectionView(selectedBlock: $selectedBlock, blockPosition: $blockPosition, isDragging: $isDragging)
                        .frame(height: 140)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
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
        .onAppear {
            if autoStreak {
                startAutoStreak()
            }
        }
        .onDisappear {
            streakTimer?.invalidate()
        }
    }
}

#Preview {
    ContentView()
}
