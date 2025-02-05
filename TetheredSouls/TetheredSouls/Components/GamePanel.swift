import SwiftUI
import UIKit
import Foundation
// Add this if Block is defined in another module
// import TetheredSoulsKit  

// Add this at the top with other types
class NotionFaceProxy: ObservableObject {
    @Published var isWatching: Bool = false
    @Published var mood: CatMood = .normal
    @Published var eyePosition: CGPoint = .zero
    
    func updateMood(_ newMood: CatMood) {
        withAnimation(.easeInOut(duration: 0.3)) {
            mood = newMood
            isWatching = true
        }
    }
    
    func resetMood() {
        withAnimation(.easeOut(duration: 0.3)) {
            mood = .normal
            isWatching = false
        }
    }
}

struct GamePanel: View {
    let score: Int
    let currentStreak: Int
    let selectedBlock: Block?
    
    @State private var achievements: [Achievement] = []
    @State private var isPlacingSticker = false
    @State private var lastPlacementTime: Date?
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    @StateObject private var notionFaceRef = NotionFaceProxy()
    
    // Add new visual states
    @State private var isScoreAnimating = false
    @State private var lastScore = 0
    @State private var streakGlowOpacity = 0.0
    
    // Stamp Collection System
    @State private var filledFrames: [Int: Achievement] = [:]  // Position (0-4) -> Achievement
    @State private var rowsCompleted: Int = 0
    @State private var isRowClearing: Bool = false
    
    private let maxStamps = 16
    private let minStampSpacing: CGFloat = 40
    private let hapticCooldown: TimeInterval = 0.5
    
    private let glowColors: [Color] = [
        .pink.opacity(0.3),
        .yellow.opacity(0.2),
        .blue.opacity(0.2)
    ]
    
    // Enhanced stamp collection
    private let stampSizes: [StickerType: CGFloat] = [
        .amore: 85,      // Love letter stamp
        .cherry: 75,     // Sweet cherry
        .safetypin: 80,  // Safety pin
        .cannibal: 78,   // Cannibal flower
        .flowerstamp: 76, // Classic flower
        .lily: 82,       // Lily stamp
        .dagger: 83,     // Dagger stamp
        .felinestamp: 80, // Feline stamp
        .lighthouse: 78,  // Lighthouse stamp
        .dinner: 80,     // Dinner stamp
        .bunny: 75,      // Bunny stamp
        .matchbox: 72,   // Matchbox stamp
        .poptart: 76,    // Pop tart stamp
        .oneflower: 74   // Single flower stamp
    ]    
    
    // Frame Layout Constants
    private let frameSpacing: CGFloat = 8
    private let frameSize: CGFloat = 60
    
    @State private var progressWidth: CGFloat = 0
    private let maxScore: Int = 1000 // Adjust this based on your game's max score
    
    @State private var usedStampTypes: Set<StickerType> = []
    
    @State private var backgroundStamps: [BackgroundStamp] = []
    
    @State private var lastUsedStampType: StickerType?
    
    @State private var flippedIndices: [Int] = []
    
    // Add new state properties
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    struct BackgroundStamp: Identifiable {
        let id = UUID()
        let type: StickerType
        let position: CGPoint
        let rotation: Double
        let size: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Warm paper wall
                Theme.background
                
                // Achievement tattoo collection
                ForEach(Array(filledFrames), id: \.key) { index, achievement in
                    Image(achievement.type.rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: stampSizes[achievement.type] ?? 60)
                        .rotationEffect(.degrees(achievement.rotation))
                        .scaleEffect(isPlacingSticker ? 1.1 : 1.0)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        .position(achievement.position)
                        .transition(
                            .asymmetric(
                                insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.6)),
                                removal: .opacity.animation(.easeOut(duration: 0.2))
                            )
                        )
                }
                
                // Core displays as part of collection
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        // Cat frame
                        ZStack {
                            Image("frame")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 85)
                                .colorMultiply(Color(red: 99/255, green: 32/255, blue: 27/255))
                                .opacity(0.95)
                            
                            NotionFace()
                                .frame(width: 65)
                                .offset(y: 8)
                                .environmentObject(notionFaceRef)
                        }
                        .modifier(WobbleAnimation(isEnabled: true))
                        .padding(.top, -12)
                        
                        // Only one set of streak frames
                        HStack(spacing: frameSpacing) {
                            ForEach(0..<5) { index in
                                ZStack {
                                    // Dotted frame that disappears during flip
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(style: StrokeStyle(
                                            lineWidth: 2,
                                            dash: [5, 5]
                                        ))
                                        .frame(width: 35, height: 35)
                                        .foregroundColor(Color(red: 99/255, green: 32/255, blue: 27/255))
                                        .scaleEffect(flippedIndices.contains(index) ? 0.8 : 1)
                                        .opacity(flippedIndices.contains(index) ? 0 : 1)
                                        .animation(
                                            .interpolatingSpring(stiffness: 200, damping: 15)
                                            .delay(Double(index) * 0.15),
                                            value: flippedIndices
                                        )
                                    
                                    // Feline stamp with enhanced flip animation
                                    if flippedIndices.contains(index) {
                                        Image("felinestamp")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30)
                                            .rotation3DEffect(
                                                .degrees(flippedIndices.contains(index) ? 0 : 180),
                                                axis: (x: 0, y: 1, z: 0),
                                                anchor: .leading,
                                                perspective: 0.4
                                            )
                                            .scaleEffect(flippedIndices.contains(index) ? 1 : 0.5)
                                            .animation(
                                                .interpolatingSpring(stiffness: 250, damping: 12)
                                                .delay(Double(index) * 0.15 + 0.05),
                                                value: flippedIndices
                                            )
                                            .transition(.asymmetric(
                                                insertion: .identity,
                                                removal: .opacity
                                            ))
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.top, 45)
                        
                        Spacer()
                        
                        // Score display
                        ZStack {
                            Text("\(score)")
                                .font(.custom("Georgia-Bold", size: 12))
                                .foregroundColor(Color(red: 99/255, green: 32/255, blue: 27/255))
                                .opacity(0.85)
                                .rotationEffect(.degrees(isScoreAnimating ? 5 : 0))
                                .animation(.spring(response: 0.3), value: isScoreAnimating)
                            
                            Image("scoreframe")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 95, height: 95)
                                .colorMultiply(Color(red: 99/255, green: 32/255, blue: 27/255))
                                .opacity(0.95)
                        }
                        .padding(.top, 5)
                        .offset(x: -15)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                // Comment out background stamps collection
                /*
                // Add after Theme.background
                ForEach(backgroundStamps) { stamp in
                    Image(stamp.type.rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: stamp.size)
                        .colorMultiply(Color(red: 99/255, green: 32/255, blue: 27/255))
                        .rotationEffect(.degrees(stamp.rotation))
                        .position(stamp.position)
                        .opacity(0.85)
                }
                */
                
                // In the ZStack where selectedBlock is handled
                // Remove or comment out the BlockView:
                /*
                if let selectedBlock = selectedBlock {
                    BlockView(block: selectedBlock)
                        .frame(width: 30, height: 30)
                        .position(x: 20, y: 20)
                        .transition(.scale)
                        .zIndex(999)
                }
                */
            }
            .onChange(of: score) { oldValue, newValue in
                // Handle feline stamp flips
                let requiredScores = [1000, 2000, 3000, 4000, 5000]
                for (index, threshold) in requiredScores.enumerated() {
                    if newValue >= threshold && !flippedIndices.contains(index) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.18) {
                            withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.9)) {
                                flippedIndices.append(index)
                                feedbackGenerator.impactOccurred(intensity: 0.7)
                            }
                        }
                    }
                }
                
                // Keep background stamps for every 2500 points
                /*
                if newValue % 2500 == 0 && newValue > 0 {
                    addBackgroundStamp(in: geometry)
                }
                */
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func addAchievement(in geometry: GeometryProxy) {
        // Prevent achievement spam
        if let lastTime = lastPlacementTime,
           Date().timeIntervalSince(lastTime) <= hapticCooldown {
            return
        }
        
        // Find first empty frame
        for index in 0..<5 {
            if filledFrames[index] == nil {
                let position = framePosition(for: index, in: geometry)
                
                // Get available stamps excluding used ones
                let availableTypes = Set(StickerType.allCases).subtracting(usedStampTypes)
                let selectedType = availableTypes.randomElement() ?? .flowerstamp
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    let achievement = Achievement(
                        type: selectedType,
                        position: position,
                        rotation: Double.random(in: -15...15)
                    )
                    filledFrames[index] = achievement
                    usedStampTypes.insert(selectedType)
                    feedbackGenerator.impactOccurred(intensity: 0.7)
                }
                
                // Check if row is complete
                if filledFrames.count == 5 {
                    clearRow()
                }
                
                break
            }
        }
        
        lastPlacementTime = Date()
    }
    
    private func clearRow() {
        withAnimation(.easeOut(duration: 0.3)) {
            isRowClearing = true
            rowsCompleted += 1
            filledFrames.removeAll()
            
            #if DEBUG
            print("Row cleared! Total rows completed: \(rowsCompleted)")
            #endif
        }
    }
    
    private func isOverlapping(at newPosition: CGPoint) -> Bool {
        achievements.contains { achievement in
            let distance = sqrt(
                pow(achievement.position.x - newPosition.x, 2) +
                pow(achievement.position.y - newPosition.y, 2)
            )
            return distance < minStampSpacing
        }
    }
    
    // Debug function to verify stamp placement
    private func verifyStampPlacement(_ achievement: Achievement) -> Bool {
        guard let lastPlacement = achievements.last else { return true }
        
        let distance = sqrt(
            pow(achievement.position.x - lastPlacement.position.x, 2) +
            pow(achievement.position.y - lastPlacement.position.y, 2)
        )
        
        #if DEBUG
        print("Stamp Placement Debug:")
        print("- Distance from last stamp: \(distance)")
        print("- Minimum spacing required: \(minStampSpacing)")
        print("- Position: \(achievement.position)")
        print("- Total stamps: \(achievements.count)/\(maxStamps)")
        #endif
        
        return distance >= minStampSpacing
    }
    
    // Debug function to verify streak-based stamps
    private func debugStreakStamps() {
        #if DEBUG
        print("Streak Stamps Debug:")
        print("- Current streak: \(currentStreak)")
        print("- Available stamp types: \(StickerType.allCases)")
        print("- Total achievements: \(achievements.count)")
        print("- Stamp spacing: \(minStampSpacing)")
        #endif
    }
    
    private func framePosition(for index: Int, in geometry: GeometryProxy) -> CGPoint {
        let y = geometry.size.height * 0.75  // Lower position
        let spacing: CGFloat = 60  // Fixed spacing
        let startX = (geometry.size.width - (spacing * 4)) / 2  // Center the row
        
        return CGPoint(
            x: startX + spacing * CGFloat(index),
            y: y
        )
    }
    
    private func addBackgroundStamp(in geometry: GeometryProxy) {
        let stampSize: CGFloat = 42
        let minSpacing: CGFloat = 25  // Slightly reduced for better packing
        let padding: CGFloat = 10
        
        // Add delay between stamp placements
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var attempts = 0
            var position: CGPoint
            var isValidPosition = false
            let maxAttempts = 100
            
            repeat {
                attempts += 1
                position = CGPoint(
                    x: CGFloat.random(in: padding...(geometry.size.width - padding)),
                    y: CGFloat.random(in: padding...(geometry.size.height - padding))
                )
                
                isValidPosition = !isNearUIElements(position: position, in: geometry) &&
                    !isNearOtherStamps(position: position, minSpacing: minSpacing)
                
                if attempts >= maxAttempts { break }
                
            } while !isValidPosition
            
            if isValidPosition {
                let availableTypes = StickerType.allCases.filter { $0 != .felinestamp }
                let selectedType = availableTypes
                    .filter { $0 != lastUsedStampType }
                    .randomElement() ?? availableTypes.randomElement() ?? .flowerstamp
                
                let stamp = BackgroundStamp(
                    type: selectedType,
                    position: position,
                    rotation: Double.random(in: -35...35),
                    size: stampSize
                )
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    backgroundStamps.append(stamp)
                    feedbackGenerator.impactOccurred(intensity: 0.5)
                    lastUsedStampType = selectedType
                }
            }
        }
    }
    
    private func isNearUIElements(position: CGPoint, in geometry: GeometryProxy) -> Bool {
        let padding: CGFloat = 15 // Reduced padding
        
        let catZone = CGRect(
            x: 20,
            y: 10,
            width: 85,
            height: 85
        )
        
        let scoreZone = CGRect(
            x: geometry.size.width - 110,
            y: 20,
            width: 90,
            height: 90
        )
        
        let frameRowZone = CGRect(
            x: geometry.size.width * 0.2,
            y: 130,
            width: geometry.size.width * 0.6,
            height: 60
        )
        
        return catZone.insetBy(dx: -padding, dy: -padding).contains(position) ||
               scoreZone.insetBy(dx: -padding, dy: -padding).contains(position) ||
               frameRowZone.insetBy(dx: -padding, dy: -padding).contains(position)
    }
    
    // Add helper function to check stamp spacing
    private func isNearOtherStamps(position: CGPoint, minSpacing: CGFloat) -> Bool {
        backgroundStamps.contains { stamp in
            let distance = sqrt(
                pow(stamp.position.x - position.x, 2) +
                pow(stamp.position.y - position.y, 2)
            )
            return distance < minSpacing
        }
    }
    
    // Add new helper function to check for similar stamps nearby
    private func isNearSimilarStamps(position: CGPoint, in geometry: GeometryProxy) -> Bool {
        let similarityRadius: CGFloat = 70 // Larger radius for checking similar types
        
        let nearbyTypes = backgroundStamps.filter { stamp in
            let distance = sqrt(
                pow(stamp.position.x - position.x, 2) +
                pow(stamp.position.y - position.y, 2)
            )
            return distance < similarityRadius
        }.map { $0.type }
        
        return nearbyTypes.count >= 2 // Prevent more than 2 similar stamps in proximity
    }
    
    // Add helper to get nearby stamp types
    private func getNearbyStampTypes(at position: CGPoint) -> Set<StickerType> {
        let proximityRadius: CGFloat = 80
        
        return Set(backgroundStamps.filter { stamp in
            let distance = sqrt(
                pow(stamp.position.x - position.x, 2) +
                pow(stamp.position.y - position.y, 2)
            )
            return distance < proximityRadius
        }.map { $0.type })
    }
}

// MARK: - Supporting Types
struct Achievement: Identifiable {
    let id = UUID()
    let type: StickerType
    let position: CGPoint
    let rotation: Double
}

enum StickerType: String, CaseIterable {
    case flowerstamp, cherry, cannibal, safetypin, amore, lily, dagger, felinestamp,
         lighthouse, dinner, bunny, matchbox, poptart, oneflower
}

struct WobbleAnimation: ViewModifier {
    let isEnabled: Bool
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isEnabled && !reduceMotion ? 2 : 0))
            .animation(
                isEnabled && !reduceMotion ? 
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true) : 
                    .default,
                value: isEnabled
            )
    }
}

struct DigitalSegmentDisplay: View {
    let progress: Double
    let segments: Int = 5
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { index in
                Rectangle()
                    .fill(progress >= Double(index + 1) / Double(segments) ? 
                          Color(red: 99/255, green: 32/255, blue: 27/255) : 
                          Color(red: 99/255, green: 32/255, blue: 27/255).opacity(0.2))
                    .frame(width: 4, height: 15)
                    .overlay(
                        Rectangle()
                            .stroke(Color(red: 99/255, green: 32/255, blue: 27/255), lineWidth: 0.5)
                    )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(red: 99/255, green: 32/255, blue: 27/255), lineWidth: 1)
        )
    }
}

// MARK: - Preview Provider
struct GamePanel_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Test streak = 5
            GamePanel(
                score: 100,
                currentStreak: 5,
                selectedBlock: nil                
            )
            
            // Test streak = 10
            GamePanel(
                score: 200,
                currentStreak: 10,
                selectedBlock: nil                
            )
        }
        .padding()
        .previewDisplayName("Streak Tests")
    }
}
