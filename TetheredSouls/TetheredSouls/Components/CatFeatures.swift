//
//  CatFeatures.swift
//  TetheredSouls
//
//  Created by Jahan Khan on 11/9/24
//  BRAND NEW
//

import SwiftUI
import Foundation

// MARK: - Supporting Types
struct LineShape: Shape {
    let angle: Double
    let length: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dx = cos(angle) * length / 2
        let dy = sin(angle) * length / 2
        path.move(to: CGPoint(x: rect.midX - dx, y: rect.midY - dy))
        path.addLine(to: CGPoint(x: rect.midX + dx, y: rect.midY + dy))
        return path
    }
}

enum CatMood: String, CaseIterable {
    case normal
    case happy
    case sad
    case sleepy
    case watching
    case loving
    case excited
    case curious
    case playful
}

struct CatFeatures: View {
    // MARK: - Properties
    @Binding var orbitAngle: Double
    let mood: CatMood
    let touchLocation: CGPoint?
    let parentSize: CGSize
    let isSleeping: Bool
    let isBlinking: Bool
    private let totalFrames = 25
    
    // Add static mode to completely disable animations when needed
    var staticMode: Bool = false
    
    // Add properties to support direct gesture tracking
    @State private var localTouchLocation: CGPoint? = nil
    @State private var isDragging: Bool = false
    @State private var lastUpdatedLocation: Date = Date()
    @State private var tapCount: Int = 0 // Add tap counter
    @StateObject private var touchCoordinator = GridTouchCoordinator.shared
    @StateObject private var gameState = GameStateManager.shared
    
    // Add state to track block spectating
    @State private var isSpectatingBlock: Bool = false
    @State private var spectatedBlockPosition: CGPoint? = nil
    
    // Animation states
    @State private var currentFrame: Int = 13
    @State private var showSleepingZ = false
    @State private var breathingScale: CGFloat = 1.0
    @State private var zOffset: CGFloat = 0
    @State private var sleepyMouthOffset: CGFloat = 0
    @State private var sleepyWhiskerRotation: Double = 0
    @State private var showHeart = false
    
    // MARK: - Helper Methods
    private func calculateFrameNumber(eyeCenter: CGPoint) -> Int {
        // Skip all calculations in static mode
        if staticMode {
            return 13 // Default center position
        }
        
        handleInteraction()
        
        if isBlinking { return 13 }
        
        // First, prioritize spectating blocks if they're being dragged
        // More aggressively check all possible dragging indicators
        if isSpectatingBlock || gameState.isDragging {
            if let blockPosition = spectatedBlockPosition ?? touchCoordinator.touchLocation {
                // Always use the special block spectating method when dragging is happening
                
                // Move debug print outside the function calculation flow
                DispatchQueue.main.async {
                    #if DEBUG
                    print("🔎 Cat PRIORITY spectating block at: \(blockPosition)")
                    #endif
                }
                
                return EyeGeometry.calculateBlockSpectatingFrame(
                    blockPosition: blockPosition,
                    eyeCenter: eyeCenter,
                    screenHeight: UIScreen.main.bounds.height,
                    totalFrames: totalFrames,
                    defaultFrame: 13
                )
            }
        }
        
        // Normal eye tracking for other interactions
        // First check local touch (from direct gesture), then coordinator's touch, then passed-in touchLocation
        let touch = localTouchLocation ?? touchCoordinator.touchLocation ?? touchLocation
        
        if let touch = touch {
            // Calculate the raw frame number
            let frameNumber = EyeGeometry.calculateFrameNumber(
                touchPoint: touch,
                eyeCenter: eyeCenter,
                totalFrames: totalFrames,
                defaultFrame: 13
            )
            
            // Detect if touch is on the left side of the screen
            let isLeftSide = touch.x < UIScreen.main.bounds.width / 2
            
            // For left side taps, use the mirrored frame
            // The total frames are 25 (0-24), so the mirror calculation is simple
            if isLeftSide && frameNumber != 0 && frameNumber != 12 && frameNumber != 13 && frameNumber != 24 {
                // Mirroring around center frame (12)
                // This creates a natural "backside" rotation effect for the left side
                return 24 - frameNumber
            }
            
            return frameNumber
        }
        return 13
    }
    
    // This overloaded method ensures we directly use the provided touchLocation
    private func calculateFrameNumber(eyeCenter: CGPoint, touchLocation: CGPoint) -> Int {
        // Skip all calculations in static mode
        if staticMode {
            return 13 // Default center position
        }
        
        handleInteraction()
        
        if isBlinking { return 13 }
        
        // Detect if touch is on the left side of the screen
        let isLeftSide = touchLocation.x < UIScreen.main.bounds.width / 2
        
        // Use the provided touchLocation directly
        let frameNumber = EyeGeometry.calculateFrameNumber(
            touchPoint: touchLocation,
            eyeCenter: eyeCenter,
            totalFrames: totalFrames,
            defaultFrame: 13
        )
        
        // For left side taps, use the mirrored frame
        // The total frames are 25 (0-24), so the mirror calculation is simple
        if isLeftSide && frameNumber != 0 && frameNumber != 12 && frameNumber != 13 && frameNumber != 24 {
            // Mirroring around center frame (12)
            // This creates a natural "backside" rotation effect for the left side
            return 24 - frameNumber
        }
        
        return frameNumber
    }
    
    private func handleInteraction() {
        NotificationCenter.default.post(name: .resetIdleTimer, object: nil)
        
        // Cancel any pending sleep animations
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    // Add a method to handle tap behavior specifically
    private func handleTap(at location: CGPoint) {
        // Increment tap count
        tapCount += 1
        
        // Create hearts on tap
        withAnimation {
            showHeart = true
        }
        
        // Trigger haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Post notification for heart generation
        NotificationCenter.default.post(
            name: .generateHeartParticle,
            object: nil,
            userInfo: ["location": location]
        )
        
        // Hide heart after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showHeart = false
            }
        }
    }
    
    // ULTRA DIRECT calculation approach - no complex logic
    private func calculateTargetEyeFrame(controllerRef: DirectCatEyeControl.Type, eyeFrame: Int, isDraggingNow: Bool, size: CGFloat) -> Int {
        // DURING DRAGGING: Directly use the controller frame with NO exceptions
        if isDraggingNow && controllerRef.shared.currentEyeFrame != 0 {
            // Always use the exact frame from DirectCatEyeControl during dragging
            return controllerRef.shared.currentEyeFrame
        }
        
        // Check if we have any direct touch (tap or gesture) - HIGHEST PRIORITY for non-dragging
        if let directTouch = localTouchLocation {
            // Calculate based on the local touch (direct gesture on cat)
            return calculateFrameNumber(eyeCenter: CGPoint(x: size * 0.35, y: size * 0.5), touchLocation: directTouch)
        }
        
        // Check for touch through coordinator - MEDIUM PRIORITY
        if let coordinatorTouch = touchCoordinator.touchLocation {
            // Calculate based on the coordinator touch
            return calculateFrameNumber(eyeCenter: CGPoint(x: size * 0.35, y: size * 0.5), touchLocation: coordinatorTouch)
        }
        
        // Check for touch passed in from parent - LOWEST PRIORITY
        if let parentTouch = touchLocation {
            // Calculate based on the parent-provided touch
            return calculateFrameNumber(eyeCenter: CGPoint(x: size * 0.35, y: size * 0.5), touchLocation: parentTouch)
        }
        
        // DEFAULT: Use center position (13) when no touches are available
        return 13
    }
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            
            // Create local references for the DirectCatEyeControl values
            let controllerRef = DirectCatEyeControl.self
            let eyeFrame = controllerRef.shared.currentEyeFrame
            let isDraggingNow = controllerRef.shared.isDragging
            
            // DEBUG logging moved to onAppear or onChange
            
            // Use ZStack directly without variable assignments
            let targetEyeFrame = calculateTargetEyeFrame(
                controllerRef: controllerRef,
                eyeFrame: eyeFrame,
                isDraggingNow: isDraggingNow,
                size: size
            )
            
            ZStack {
                // Cat ears band with stripes
                ZStack {
                    Image("catband")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.75)
                    
                    // Head stripes between the ears
                    Image("headstripes")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.25)
                        .offset(y: -size * 0.05)
                }
                .position(x: size * 0.5, y: size * 0.25)
                
                // Remove side stripes section
                // Group {
                //     // Left side stripes
                //     Image("greystripes")...
                //     // Right side stripes
                //     Image("greystripes")...
                // }

                // Only show eyes if not sleeping
                if !isSleeping {
                    // Iris backgrounds
                    Group {
                        Ellipse()
                            .fill(Color(red: 0.6, green: 0.65, blue: 0.4).opacity(0.95))
                            .frame(width: size * 0.14, height: size * 0.14)
                            .position(x: size * 0.37, y: size * 0.45)
                            .opacity(isBlinking ? 0 : 1)
                        
                        Ellipse()
                            .fill(Color(red: 0.6, green: 0.65, blue: 0.4).opacity(0.95))
                            .frame(width: size * 0.14, height: size * 0.14)
                            .position(x: size * 0.65, y: size * 0.45)
                            .opacity(isBlinking ? 0 : 1)
                    }

                    // Eyeballs
                    Image("balls")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.95)
                        .position(x: size/2, y: size * 0.45)
                        .opacity(isBlinking ? 0 : 1)
                    
                    // Closed eyes - centered but higher
                    Image("closedclosedeyes")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.95)
                        .position(x: size * 0.39, y: size * 0.40)
                        .opacity(isBlinking ? 1 : 0)
                    
                    // Regular eye animations (pupils)
                    Group {
                        Image("\(currentFrame)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.2)
                            .position(x: size * 0.35, y: size * 0.456)
                            .opacity(isBlinking ? 0 : 1)
                        
                        Image("\(currentFrame)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.2)
                            .position(x: size * 0.65, y: size * 0.456)
                            .opacity(isBlinking ? 0 : 1)
                    }
                } else {
                    // Sleeping eyes (permanently closed)
                    Image("closedclosedeyes")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.95)
                        .position(x: size * 0.39, y: size * 0.40)
                }

                // Sleeping Z's with enhanced positioning
                if isSleeping {
                    // Enhanced sleeping mouth with side-to-side movement
                    Image("justMouth")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.8)
                        .position(x: size/2 + sleepyMouthOffset, y: size * 0.55)
                        .scaleEffect(breathingScale)
                        .onAppear {
                            // Combine breathing and side movement
                            withAnimation(
                                .easeInOut(duration: 3)
                                .repeatForever(autoreverses: true)
                            ) {
                                breathingScale = 1.3
                                sleepyMouthOffset = 5
                            }
                        }
                    
                    // Keep whiskers while sleeping with more twitchy movement
                    Image("Whiskers")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 1.1)
                        .position(x: size * 0.5, y: size * 0.5)
                        .rotationEffect(.degrees(sleepyWhiskerRotation))
                        .onAppear {
                            // More frequent, random whisker twitches
                            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    sleepyWhiskerRotation = Double.random(in: -3...3)
                                }
                            }
                        }
                    
                    // Enhanced Z's animation
                    SleepingZs()
                        .position(x: size * 0.7, y: size * 0.3)
                        .scaleEffect(1.2) // Made larger
                } else {
                    MouthAndWhiskers(mood: mood, size: size, isBlinking: isBlinking, staticMode: staticMode)
                }
            }
            // Now use the computed target frame in the onChange handler
            .onChange(of: targetEyeFrame) { _, newValue in
                // Immediately set frame with no animation if we're dragging
                if isDraggingNow {
                    currentFrame = newValue
                } else if !staticMode {
                    // Only use animation for non-dragging interactions
                    animateToFrame(newValue)
                } else {
                    // In static mode, just set the frame directly without animation
                    currentFrame = newValue
                }
            }
            
            // Add debug logging here where it's safe
            .onChange(of: isDraggingNow) { _, newValue in
                #if DEBUG
                if newValue {
                    print("👁 CatFeatures reading eye frame: \(eyeFrame)")
                }
                #endif
            }
            
            // Add direct gesture handling to the cat features
            .contentShape(Rectangle()) // Ensure the entire area is tappable
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Process all interactions, even in static mode
                        // This ensures direct interaction works in all modes
                        
                        // Convert to local coordinates for eye tracking
                        localTouchLocation = value.location
                        isDragging = true
                        lastUpdatedLocation = Date()
                        
                        // Determine if this is likely a tap rather than a drag
                        if tapCount == 0 {
                            // We'll decide at onEnded if this was a tap
                            tapCount = 1
                        }
                        
                        // Notify other components about this interaction
                        NotificationCenter.default.post(name: .resetIdleTimer, object: nil)
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        // Distinguish between tap and drag
                        let wasTap = tapCount == 1
                        tapCount = 0
                        
                        // If this was a tap, generate heart particles
                        if wasTap {
                            handleTap(at: value.location)
                        }
                        
                        // Keep the eye position for a moment before resetting
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if Date().timeIntervalSince(lastUpdatedLocation) >= 0.3 {
                                // Only reset if there hasn't been a new touch
                                localTouchLocation = nil
                            }
                        }
                    }
            )
            // CRITICAL: Check for eye control updates very frequently (16 times per second)
            .onReceive(Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()) { _ in
                // Only act if dragging state is active
                if DirectCatEyeControl.shared.isDragging {
                    let currentEyeFrame = DirectCatEyeControl.shared.currentEyeFrame
                    
                    // IMPORTANT: Only update when we have a valid frame (not 0)
                    if currentEyeFrame != 0 {
                        // Force immediate update with no animation
                        if self.currentFrame != currentEyeFrame {
                            self.currentFrame = currentEyeFrame
                            
                            // Move debug print outside of View hierarchy
                            DispatchQueue.main.async {
                                #if DEBUG
                                print("⚡️ Cat eye TIMER UPDATE: frame=\(currentEyeFrame)")
                                #endif
                            }
                        }
                    } else {
                        // If eye frame is 0 but dragging is true, we have a state inconsistency
                        // Try to recover by setting to center frame (13)
                        DirectCatEyeControl.shared.currentEyeFrame = 13
                        self.currentFrame = 13
                        
                        DispatchQueue.main.async {
                            #if DEBUG
                            print("⚠️ DRAGGING STATE INCONSISTENCY DETECTED - Recovered to frame 13")
                            #endif
                        }
                    }
                }
            }
            // Add a timer to check for external touch updates
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                // When not directly interacting, use either the TouchCoordinator or passed-in touch location
                if !isDragging && (touchCoordinator.touchLocation != nil || touchLocation != nil) {
                    // This allows the eyes to follow external touches
                    lastUpdatedLocation = Date()
                }
            }
            // Add listener for block dragging
            .onReceive(NotificationCenter.default.publisher(for: .init("BlockDragging"))) { notification in
                if let userInfo = notification.userInfo as? [String: Any],
                   let position = userInfo["position"] as? CGPoint {
                    
                    // Just track state - don't recalculate frames
                    isSpectatingBlock = true
                    spectatedBlockPosition = position
                    
                    // Trust the singleton's frame value directly
                    self.currentFrame = DirectCatEyeControl.shared.currentEyeFrame
                }
            }
            
            // Add listener for block dragging ended - ULTRA SIMPLE
            .onReceive(NotificationCenter.default.publisher(for: .init("BlockDraggingEnded"))) { _ in
                // DIRECT: Hard reset everything to center with no complex logic
                print("🔵 DRAG ENDED: RESETTING CAT EYE TO CENTER (13)")
                
                // DIRECT APPROACH: Hard reset all state to known good values
                DirectCatEyeControl.shared.isDragging = false
                DirectCatEyeControl.shared.currentEyeFrame = 13 // CENTER
                self.currentFrame = 13 // CENTER
                isSpectatingBlock = false
                spectatedBlockPosition = nil
            }
            
            // Add direct listener for game state
            .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
                // Force update eye position if dragging state changes
                if isDraggingNow {
                    // Immediately force downward eye position when dragging starts
                    currentFrame = eyeFrame
                }
            }
            
            // Add listener for direct dragging state changes
            .onReceive(NotificationCenter.default.publisher(for: .init("GameDraggingStateChanged"))) { notification in
                if let userInfo = notification.userInfo as? [String: Any],
                   let isDragging = userInfo["isDragging"] as? Bool {
                    
                    if isDragging {
                        // Force CENTER position initially
                        DirectCatEyeControl.shared.isDragging = true
                        DirectCatEyeControl.shared.currentEyeFrame = 13 // CENTER
                        
                        // Force immediate eye position update to center
                        withAnimation(.easeOut(duration: 0.1)) {
                            currentFrame = 13 // CENTER
                            isSpectatingBlock = true
                        }
                        
                        // Log state change
                        DispatchQueue.main.async {
                            #if DEBUG
                            print("🎲 GAME DRAGGING STARTED: Set center frame (13)")
                            #endif
                        }
                    } else {
                        // Reset all dragging state
                        withAnimation(.easeOut(duration: 0.2)) {
                            DirectCatEyeControl.shared.isDragging = false
                            DirectCatEyeControl.shared.currentEyeFrame = 13 // CENTER
                            currentFrame = 13 // CENTER
                            isSpectatingBlock = false
                            spectatedBlockPosition = nil
                        }
                        
                        // Log state change
                        DispatchQueue.main.async {
                            #if DEBUG
                            print("🎲 GAME DRAGGING ENDED: Reset to center frame (13)")
                            #endif
                        }
                    }
                }
            }
            
            // DIRECT FORCE NOTIFICATION: No complex state management, just direct control
            .onReceive(NotificationCenter.default.publisher(for: .init("ForceCatEyeFrame"))) { notification in
                if let userInfo = notification.userInfo as? [String: Any],
                   let frame = userInfo["frame"] as? Int,
                   let isDragging = userInfo["isDragging"] as? Bool {
                
                    // DIRECT: Apply the frame immediately with no animations
                    DirectCatEyeControl.shared.isDragging = isDragging
                    DirectCatEyeControl.shared.currentEyeFrame = frame
                    self.currentFrame = frame
                    
                    // Track block spectating state
                    isSpectatingBlock = isDragging
                    
                    // Update the position if provided
                    if let position = userInfo["position"] as? CGPoint {
                        spectatedBlockPosition = isDragging ? position : nil
                    } else {
                        spectatedBlockPosition = nil
                    }
                    
                    print("🔴 FORCE CAT EYE: Set to frame \(frame), dragging=\(isDragging)")
                }
            }
            
            // Add special FINAL RESET handler with highest priority
            .onReceive(NotificationCenter.default.publisher(for: .init("FinalDragReset"))) { _ in
                // This is our last-chance reset handler
                // Unconditionally reset ALL state to ensure clean state
                
                // DIRECT Reset - force UI frame to center
                self.currentFrame = 13
                
                // Reset shared state
                DirectCatEyeControl.shared.isDragging = false
                DirectCatEyeControl.shared.currentEyeFrame = 13
                
                // Clear ALL local tracking state
                isSpectatingBlock = false
                spectatedBlockPosition = nil
                
                print("🔄 FINAL RESET: Cat eye FORCED to center frame (13)")
            }
            
            // SIMPLE ENFORCER TIMER: Make sure our eye frame is maintained during dragging
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                if DirectCatEyeControl.shared.isDragging {
                    let frameToEnforce = DirectCatEyeControl.shared.currentEyeFrame
                    if self.currentFrame != frameToEnforce {
                        // Force immediate update to the correct frame
                        self.currentFrame = frameToEnforce
                        print("🔄 ENFORCER: Maintaining cat eye frame \(frameToEnforce) during dragging")
                    }
                }
            }
            
            // CRITICAL: Add listener for gesture mode changes
            .onReceive(NotificationCenter.default.publisher(for: .init("GestureModeChanged"))) { notification in
                if let mode = notification.object as? GestureMode {
                    // When switching to cat interaction mode, ensure we're not in a stuck state
                    if mode == .catInteraction {
                        // Only reset if we're not actively dragging
                        if !DirectCatEyeControl.shared.isDragging {
                            // Reset to neutral state for cat interaction mode
                            isSpectatingBlock = false
                            spectatedBlockPosition = nil
                            
                            // Don't change the frame immediately - let natural eye tracking take over
                            // This allows taps to work properly in cat mode
                            print("🐱 GESTURE MODE: Switched to cat interaction mode")
                        }
                    }
                }
            }
        }
    }
    
    // Faster eye movement animation - special version for block dragging
    private func animateToFrameForDragging(_ targetFrame: Int) {
        // If in static mode, skip all animations
        if staticMode {
            currentFrame = targetFrame
            return
        }
        
        // ALWAYS skip animation for block spectating - immediate response is critical
        // When spectating blocks, we use direct frame setting for maximum responsiveness
        currentFrame = targetFrame
            
        // Move debug print outside of the function flow
        DispatchQueue.main.async {
            #if DEBUG
            print("📊 Cat eyes FORCE SET to frame: \(targetFrame) (no animation)")
            #endif
        }
    }
    
    // Faster eye movement animation
    private func animateToFrame(_ targetFrame: Int) {
        // If in static mode, skip all animations
        if staticMode {
            currentFrame = targetFrame
            return
        }
        
        // Use the fast version if we're spectating a block
        if isSpectatingBlock {
            animateToFrameForDragging(targetFrame)
            return
        }
        
        let frameDiff = targetFrame - currentFrame
        let duration = 0.2 // Reduced from 0.3
        let steps = 3 // Reduced from 5
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * Double(i) / Double(steps)) {
                withAnimation(.easeInOut(duration: duration / Double(steps))) {
                    currentFrame = currentFrame + (frameDiff / steps)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: duration / Double(steps))) {
                currentFrame = targetFrame
            }
        }
    }
    
    // CRITICAL NEW METHOD: Calculate the appropriate eye frame based on block position
    private func calculateDraggingEyeFrame(for position: CGPoint) -> Int {
        // Determine horizontal position on screen
        let screenWidth = UIScreen.main.bounds.width
        let leftThird = screenWidth / 3
        let rightThird = screenWidth * 2 / 3
        
        // Use specific DOWN frames based on horizontal position
        if position.x < leftThird {
            DispatchQueue.main.async {
                #if DEBUG
                print("⬇️⬅️ Cat looking DOWN-LEFT: Frame 6 for position \(Int(position.x)), \(Int(position.y))")
                #endif
            }
            return 6 // Down-left
        } else if position.x > rightThird {
            DispatchQueue.main.async {
                #if DEBUG
                print("⬇️➡️ Cat looking DOWN-RIGHT: Frame 19 for position \(Int(position.x)), \(Int(position.y))")
                #endif
            }
            return 19 // Down-right
        } else {
            DispatchQueue.main.async {
                #if DEBUG
                print("⬇️ Cat looking STRAIGHT DOWN: Frame 13 for position \(Int(position.x)), \(Int(position.y))")
                #endif
            }
            return 13 // Straight down
        }
    }
    
    // MARK: - Mouth & Whiskers
    private struct MouthAndWhiskers: View {
        let mood: CatMood
        let size: CGFloat
        let isBlinking: Bool
        let staticMode: Bool
        @State private var whiskerRotation: Double = 0
        @State private var mouthOffset: CGFloat = 0

        var body: some View {
            ZStack {
                // Whiskers with mood-based motion
                Image("Whiskers")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 1.1)
                    .position(x: size * 0.5, y: size * 0.5)
                    .rotationEffect(.degrees(whiskerRotation))
                    .onChange(of: isBlinking) { _, newValue in
                        // Skip animation in static mode
                        if staticMode {
                            whiskerRotation = newValue ? 2 : 0
                            return
                        }
                        
                        if newValue {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                whiskerRotation = 2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    whiskerRotation = 0
                                }
                            }
                        }
                    }
                    .onChange(of: mood) { _, newMood in
                        // For curious mood during block dragging, add subtle whisker motion
                        if newMood == .curious {
                            // Start a timer to add subtle whisker movement while spectating
                            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
                                // Only animate if still in curious mood
                                if mood == .curious {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        whiskerRotation = Double.random(in: -1.5...1.5)
                                    }
                                } else {
                                    // Stop timer if mood changed
                                    timer.invalidate()
                                    
                                    // Reset rotation
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        whiskerRotation = 0
                                    }
                                }
                            }
                        }
                    }

                // Different mouth expression based on mood
                if mood == .curious {
                    // Concentrating mouth for block spectating
                    Image("SleepyMouth")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.15) // Smaller mouth when concentrating
                        .position(x: size * 0.52, y: size * 0.58)
                        .offset(x: mouthOffset)
                        .onAppear {
                            // Add subtle breathing effect for mouth
                            withAnimation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                            ) {
                                mouthOffset = 2
                            }
                        }
                } else {
                    // Regular mouth
                Image("SleepyMouth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.2)
                    .position(x: size * 0.52, y: size * 0.6)
                }
            }
        }
    }
}

// Enhanced SleepingZs animation
struct SleepingZs: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 8) { // Increased spacing
            ForEach(0..<3) { index in
                Text("Z")
                    .font(.system(size: 16 + CGFloat(index) * 4)) // Larger sizes
                    .fontWeight(.bold) // Made bolder
                    .foregroundColor(.blue.opacity(0.8)) // More opaque
                    .offset(y: offset - CGFloat(index) * 15) // More vertical spacing
                    .opacity(opacity)
                    .rotationEffect(.degrees(-15))
                    .shadow(color: .blue.opacity(0.3), radius: 4) // Added glow
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.4),
                        value: offset
                    )
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                offset -= 30 // Larger movement
                opacity = 1
            }
        }
    }
}
