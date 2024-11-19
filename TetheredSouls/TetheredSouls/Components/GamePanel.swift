import SwiftUI
import UIKit
import Foundation

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
        .amore: 70,      // Love letter stamp
        .cherry: 55,     // Sweet cherry
        .safetypin: 65,  // Safety pin
        .cannibal: 60,   // Cannibal flower
        .flowerstamp: 58 // Classic flower
    ]    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Paper texture overlay
                Image("paper-texture")
                    .resizable()
                    .opacity(0.1)
                    .allowsHitTesting(false)
                
                // Warm paper wall
                Theme.background
                
                // Achievement tattoo collection
                ForEach(achievements) { achievement in
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
                        // NotionFace containment - tighter framing
                        ZStack {
                            Image("frame")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 85)
                                .colorMultiply(Color(red: 99/255, green: 32/255, blue: 27/255))
                                .opacity(0.95)
                            
                            NotionFace()
                                .frame(width: 65)  // Keep existing frame
                                .offset(y: -1)
                                .environmentObject(notionFaceRef)
                        }
                        .modifier(WobbleAnimation(isEnabled: true))
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // Score as tattoo piece
                        ZStack {
                            // Score number behind the frame
                            Text("\(score)")
                                .font(.custom("Georgia-Bold", size: 52))
                                .foregroundColor(Color(red: 99/255, green: 32/255, blue: 27/255))
                                .opacity(0.85)
                                .rotationEffect(.degrees(isScoreAnimating ? 5 : 0))
                                .animation(.spring(response: 0.3), value: isScoreAnimating)
                            
                            Image("scoreframe")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 110)
                                .colorMultiply(Color(red: 99/255, green: 32/255, blue: 27/255))
                                .opacity(0.95)
                            
                            // Streak on top
                            if currentStreak > 0 {
                                Text("×\(currentStreak)")
                                    .font(Theme.Typography.small)
                                    .foregroundColor(Theme.textPrimary)
                                    .offset(y: -35)
                            }
                        }
                        .padding(.top, 5)  // Keep it high
                        .padding(.trailing, -15)  // Keep it to the right
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .onChange(of: currentStreak) { oldStreak, newStreak in
                if newStreak > 0 && newStreak.isMultiple(of: 5) {
                    addAchievement(in: geometry)
                }
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func addAchievement(in geometry: GeometryProxy) {
        // Prevent achievement spam
        if lastPlacementTime == nil {
            lastPlacementTime = Date()
        } else if let lastTime = lastPlacementTime,
                  Date().timeIntervalSince(lastTime) <= hapticCooldown {
            return
        }
        
        // Hard cap on stamps - now with proper return
        if achievements.count >= maxStamps {
            achievements.removeFirst()  // FIFO for stamps
        }
        
        // Improved safe zones for more organic placement
        let safeX = Double(geometry.size.width * 0.15)...Double(geometry.size.width * 0.85)
        let safeY = Double(geometry.size.height * 0.1)...Double(geometry.size.height * 0.9)
        
        // Try to find non-overlapping position
        var attempts = 0
        var newPosition: CGPoint
        repeat {
            newPosition = CGPoint(
                x: CGFloat(Double.random(in: safeX)),
                y: CGFloat(Double.random(in: safeY))
            )
            attempts += 1
        } while isOverlapping(at: newPosition) && attempts < 5
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            achievements.append(Achievement(
                type: StickerType.allCases.randomElement() ?? .flowerstamp,
                position: newPosition,
                rotation: Double.random(in: -15...15)
            ))
            
            feedbackGenerator.impactOccurred(intensity: 0.7)
        }
        
        lastPlacementTime = Date()
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
}

// MARK: - Supporting Types
struct Achievement: Identifiable {
    let id = UUID()
    let type: StickerType
    let position: CGPoint
    let rotation: Double
}

enum StickerType: String, CaseIterable {
    case flowerstamp, cherry, cannibal, safetypin, amore
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
