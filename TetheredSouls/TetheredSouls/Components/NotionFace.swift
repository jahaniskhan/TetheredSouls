//
//  NotionFace.swift
//  TetheredSouls
//
//  Created by Jahan Khan on 11/9/24
//  BRAND NEW
//

import SwiftUI

struct NotionFace: View {
    // Move the environment property inside the view struct
    @Environment(\.isDraggingBlock) private var isDraggingBlock
    
    // MARK: - State
    @State private var phase = 0.0
    @State private var isWatching = false
    @State private var mood: CatMood = .normal
    @State private var touchLocation: CGPoint? = nil
    @State private var orbitAngle: Double = -.pi/2
    @State private var showHeart = false
    @State private var breathingScale: CGFloat = 1.0
    @State private var isBlinking = false
    @StateObject private var touchCoordinator = GridTouchCoordinator.shared
    
    // Idle tracking
    @State private var lastInteractionTime: Date
    @State private var isIdle = false
    @State private var isSleeping = false
    
    // Timer for blinking
    let blinkTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    let idleCheckTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Add new properties for blinking intervals
    @State private var lastBlinkTime = Date()
    private let blinkIdleThreshold: TimeInterval = 5.0  // Blink after 5 seconds of no interaction
    
    // Add blink counter
    @State private var blinkCount: Int = 0
    
    // Add these new state properties
    @State private var isWakingUp = false
    @State private var wakeUpPhase = 0
    @State private var sleepyMouthOffset: CGFloat = 0
    @State private var sleepyWhiskerRotation: Double = 0
    
    // MARK: - Configuration
    struct Config {
        static let idleThreshold: TimeInterval = 60 // Changed to 60 seconds
        static let sleepThreshold: TimeInterval = 20 // Reduced for testing
        static let breathingDuration: TimeInterval = 3
        static let orbitSpeed: Double = 0.15
        static let sleepChance: Double = 1.0  // Always sleep when idle
        static let breathingScale: CGFloat = 1.05
        static let blinkDuration: Double = 0.15
        static let idleBlinkChance: Double = 1.0
        static let wakeUpDuration: Double = 2.0 // Total wake up animation duration
    }
    
    init() {
        _lastInteractionTime = State(initialValue: Date()) // Reset timer on app launch
        // ... keep other initializations
    }
    
    var body: some View {
        GeometryReader { geometry in
            let _ = geometry.size // Explicitly ignore unused value
            let _ = min(geometry.size.width, geometry.size.height) // Remove unused 'size' variable
            
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "9a958f"),
                                Color(hex: "9a958f")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 65, height: 65)
                    .overlay(
                        ZStack {
                            // Left side ears (>)
                            Group {
                                // Large left ear
                                Image("InnerEar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12)
                                    .position(x: 15, y: 25)
                                
                                // Medium left ear
                                Image("InnerEar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 9)
                                    .position(x: 12, y: 35)
                                
                                // Small left ear
                                Image("InnerEar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 7)
                                    .position(x: 10, y: 45)
                            }
                            
                            // Right side ears (<) - flipped
                            Group {
                                // Large right ear
                                Image("InnerEar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12)
                                    .scaleEffect(x: -1, y: 1) // Flip horizontally
                                    .position(x: 50, y: 25)
                                
                                // Medium right ear
                                Image("InnerEar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 9)
                                    .scaleEffect(x: -1, y: 1) // Flip horizontally
                                    .position(x: 53, y: 35)
                                
                                // Small right ear
                                Image("InnerEar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 7)
                                    .scaleEffect(x: -1, y: 1) // Flip horizontally
                                    .position(x: 55, y: 45)
                            }
                        }
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    .offset(x: -12, y: 25)

                CatFeatures(
                    orbitAngle: $orbitAngle,
                    mood: mood,
                    touchLocation: touchCoordinator.touchLocation.map { point in
                        // Convert from global to local coordinates
                        let localPoint = CGPoint(
                            x: point.x - geometry.frame(in: .global).minX,
                            y: point.y - geometry.frame(in: .global).minY
                        )
                        return localPoint
                    },
                    parentSize: geometry.size,
                    isSleeping: isSleeping,
                    isBlinking: isBlinking
                )
                .frame(width: 90, height: 90)
                .offset(x: -12, y: 25)

                if showHeart {
                    HeartParticle(color: .pink)
                        .position(touchCoordinator.touchLocation ?? .zero)
                }
            }
            .onChange(of: touchCoordinator.touchLocation) { _, _ in
                if touchCoordinator.touchLocation != nil {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mood = .watching
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mood = .normal
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !isDraggingBlock else { return }
                        handleHeartGesture(at: value.location)
                    }
            )
        }
        .onAppear {
            // Check idle state every second
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                checkIdleState()
            }
        }
        .onReceive(blinkTimer) { _ in
            if !isSleeping {
                blink()
            }
        }
        .onReceive(idleCheckTimer) { _ in
            checkIdleState()
        }
        .onChange(of: touchCoordinator.touchLocation) { oldValue, newValue in
            if newValue != nil {
                lastInteractionTime = Date()
                lastBlinkTime = Date()  // Reset blink timer on interaction
                isIdle = false
                isSleeping = false
                isBlinking = false // Reset blink state on interaction
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetIdleTimer)) { _ in
            updateInteraction()
        }
    }
    
    // MARK: - Helpers
    private func resetMood() {
        withAnimation(.easeOut(duration: 0.3)) {
            mood = .normal
            isWatching = false
        }
    }

    private func maybeSleep() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isSleeping = true
            mood = .sleepy // Now matches the unified CatMood
        }
    }

    private func wakeUp() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isSleeping = false
            isWakingUp = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.wakeUpDuration) {
            isWakingUp = false
        }
        
        // Force refresh eye tracking
        touchLocation = touchCoordinator.touchLocation
    }

    private func blink() {
        guard !isBlinking else { return }
        
        withAnimation(.easeInOut(duration: Config.blinkDuration)) {
            isBlinking = true
        }
        
        // The eyes might be opening too quickly after closing
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.blinkDuration * 2) {
            withAnimation(.easeInOut(duration: Config.blinkDuration)) {
                isBlinking = false
            }
        }
        
        // Print blink debug info
        #if DEBUG
        print("🐱 Blink #\(blinkCount)")
        print("  Time since last blink: \(Date().timeIntervalSince(lastBlinkTime))s")
        print("  Time since last interaction: \(Date().timeIntervalSince(lastInteractionTime))s")
        #endif
        
        lastBlinkTime = Date()
    }

    private func checkIdleState() {
        let timeSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
        
        // More sensitive idle detection
        if !touchCoordinator.isBlockActive && 
           timeSinceLastInteraction >= Config.idleThreshold && 
           !isSleeping {
            maybeSleep()
        }
    }
    
    // Reset last interaction time when touch occurs
    private func updateInteraction() {
        // Only wake if actually sleeping
        if isSleeping {
            wakeUp()
        }
        lastInteractionTime = Date()
        lastBlinkTime = Date()
    }
    
    private func handleHeartGesture(at location: CGPoint) {
        // Existing heart gesture logic
    }
}

// Add this extension for mood reactions
extension CatMood {
    var eyeScale: CGFloat {
        switch self {
        case .excited: return 0.85
        case .loving: return 0.9
        case .curious: return 1.1
        default: return 1.0
        }
    }
}
