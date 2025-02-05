//
//  CatFeatures.swift
//  TetheredSouls
//
//  Created by Jahan Khan on 11/9/24
//  BRAND NEW
//

import SwiftUI

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

enum CatMood {
    case normal, happy, sad, sleepy, watching
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
    
    // Animation states
    @State private var currentFrame: Int = 13
    @State private var showSleepingZ = false
    @State private var breathingScale: CGFloat = 1.0
    @State private var zOffset: CGFloat = 0
    @State private var sleepyMouthOffset: CGFloat = 0
    @State private var sleepyWhiskerRotation: Double = 0
    
    // MARK: - Helper Methods
    private func calculateFrameNumber(eyeCenter: CGPoint) -> Int {
        if isBlinking { return 13 }
        
        if let touch = touchLocation {
            NotificationCenter.default.post(name: .resetIdleTimer, object: nil)
            return EyeGeometry.calculateFrameNumber(
                touchPoint: touch,
                eyeCenter: eyeCenter,
                totalFrames: totalFrames,
                defaultFrame: 13
            )
        }
        return 13
    }
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let leftEyeCenter = CGPoint(x: size * 0.35, y: size * 0.5)
            let targetFrame = calculateFrameNumber(eyeCenter: leftEyeCenter)
            
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
                            .position(x: size * 0.35, y: size * 0.45)
                            .opacity(isBlinking ? 0 : 1)
                        
                        Image("\(currentFrame)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.2)
                            .position(x: size * 0.65, y: size * 0.45)
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
                    MouthAndWhiskers(mood: mood, size: size, isBlinking: isBlinking)
                }
            }
            .onChange(of: targetFrame) { _, newValue in
                animateToFrame(newValue)
            }
        }
    }
    
    // Faster eye movement animation
    private func animateToFrame(_ targetFrame: Int) {
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
    
    // MARK: - Mouth & Whiskers
    private struct MouthAndWhiskers: View {
        let mood: CatMood
        let size: CGFloat
        let isBlinking: Bool
        @State private var whiskerRotation: Double = 0

        var body: some View {
            ZStack {
                Image("Whiskers")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 1.1)
                    .position(x: size * 0.5, y: size * 0.5)
                    .rotationEffect(.degrees(whiskerRotation))
                    .onChange(of: isBlinking) { _, newValue in
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

                Image("SleepyMouth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.2)
                    .position(x: size * 0.52, y: size * 0.6)
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
