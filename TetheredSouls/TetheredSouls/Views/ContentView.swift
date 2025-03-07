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
    @State private var showedFirstCat = false
    
    @State private var availableBlocks: [Block] = Block.blocks
    
    @StateObject private var streakManager = StreakManager()
    
    private var backgroundDoodles: some View {
        GeometryReader { geometry in
            ZStack {
                // Static doodles
                ForEach(0..<6) { i in
                    DoodleElement(
                        type: [.star, .heart, .semicolon].randomElement()!,
                        rotation: Double.random(in: -25...25),
                        streak: 0
                    )
                    .opacity(0.15)
                    .scaleEffect(0.5)
                    .position(
                        x: CGFloat.random(in: 50...geometry.size.width-50),
                        y: CGFloat.random(in: 100...geometry.size.height-100)
                    )
                }
            }
        }
    }
    
    var decorativeElements: some View {
        ZStack {
            // Static elements only
            ForEach(0..<12) { i in
                let items = ["✧", "⋆", "❀"]
                Text(items[i % items.count])
                    .font(.system(size: CGFloat.random(in: 12...20)))
                    .foregroundColor(Theme.block1.opacity(0.3))
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .position(
                        x: CGFloat.random(in: 50...UIScreen.main.bounds.width-50),
                        y: CGFloat.random(in: 100...UIScreen.main.bounds.height-100)
                    )
            }
        }
    }
    
    private var blockSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - (2 * Theme.Layout.padding)) / 4 // Adjust divisor based on your layout needs
    }
    
    var body: some View {
        GeometryReader { geometry in
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
                            selectedBlock: selectedBlock
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        
                        GridView(grid: $grid, selectedBlock: $selectedBlock, blockPosition: $blockPosition, isDragging: $isDragging)
                            .padding(.horizontal, 20)
                        
                        BlockSelectionView(
                            availableBlocks: $availableBlocks,
                            selectedBlock: $selectedBlock,
                            blockPosition: $blockPosition,
                            isDragging: $isDragging
                        )
                            .frame(height: 140)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                }
                
                if let block = selectedBlock {
                    DraggableBlock(
                        selectedBlock: $selectedBlock,
                        position: $blockPosition,
                        isDragging: $isDragging,
                        grid: $grid,
                        block: block
                    )
                    .frame(width: blockSize, height: blockSize)
                    .position(
                        x: blockPosition?.x ?? geometry.size.width/2,
                        y: blockPosition?.y ?? geometry.size.height/2
                    )
                    .transition(.asymmetric(
                        insertion: .offset(x: 0, y: 20).combined(with: .opacity),
                        removal: .offset(x: 0, y: -50).combined(with: .opacity)
                    ))
                    .zIndex(2)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
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
                
                // Inside the ZStack, after GamePanel but before DraggableBlock
                ForEach(BackgroundEffectCoordinator.shared.activeEffects) { effect in
                    Group {
                        switch effect.type {
                        case .symbol(let name):
                            Image(systemName: name)
                                .font(.system(size: 24))
                                .foregroundColor(Theme.textSecondary.opacity(0.3))
                        case .image(let name):
                            Image(name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40)
                        }
                    }
                    .position(effect.position)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.1)),
                        removal: .opacity.combined(with: .scale(scale: 3.0))
                    ))
                    .animation(.easeOut(duration: 0.8), value: effect.position)
                }
                
                if score >= 100 && !showedFirstCat {
                    CatAchievementCard()
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            withAnimation {
                                showedFirstCat = true
                            }
                        }
                }
            }
            .coordinateSpace(name: "gameArea")
            .onChange(of: blockPosition) { oldValue, newValue in
                if newValue == nil {
                    withAnimation(.spring()) {
                        eyePosition = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("BlockPlaced"))) { notification in
                if let points = notification.userInfo?["points"] as? Int {
                    score += points
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

/// Handles core game loop mechanics:
/// 1. Drag gestures create temporary DraggableBlock instances
/// 2. Grid position calculated using gameArea coordinate space
/// 3. Placement validated against grid state
/// 4. Successful placement updates grid and clears transient state
/// 5. Eye tracking integrates with gesture system for hybrid input

class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    private var streakTimer: Timer?
    
    func addPoints(_ points: Int) {
        currentStreak += points
        resetTimer()
    }
    
    private func resetTimer() {
        streakTimer?.invalidate()
        streakTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.currentStreak = 0
        }
    }
}
