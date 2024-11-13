//
//  NotionFace.swift
//  TetheredSouls
//
//  Created by Jahan khan on 11/9/24.
//

import SwiftUI

struct NotionFace: View {
    @State private var phase = 0.0
    @State private var isWatching = false
    @State private var mood: CatMood = .normal
    @State private var lastInteractionTime = Date()
    @State private var eyePosition: CGPoint = .zero // Track eye movement
    @Binding var debugEyePosition: CGPoint
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Base circle with grey gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.80, blue: 0.78),
                            Color(red: 0.75, green: 0.72, blue: 0.70)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 85, height: 85)  // Reduced from 100
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            
            CatFeatures(
                phase: phase,
                isWatching: isWatching,
                mood: mood,
                eyePosition: eyePosition
            )
            .frame(width: 120, height: 120)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleInteraction(.watching)
                    let center = CGPoint(x: 60, y: 60)
                    updateEyePosition(value.location, center: center)
                }
                .onEnded { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            eyePosition = .zero
                            debugEyePosition = .zero  // Update debug info
                        }
                        resetMood()
                    }
                }
        )
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.05)) {
                phase += 0.05
                updateMoodBasedOnTime()
            }
        }
    }
    
    private func handleInteraction(_ newMood: CatMood) {
        withAnimation(.easeInOut(duration: 0.3)) {
            mood = newMood
            isWatching = true
            lastInteractionTime = Date()
        }
    }
    
    private func resetMood() {
        withAnimation(.easeOut(duration: 0.3)) {
            mood = .normal
            isWatching = false
        }
    }
    
    private func updateMoodBasedOnTime() {
        let timeSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
        if timeSinceLastInteraction > 10 {
            // Occasionally get sleepy when idle
            if Double.random(in: 0...1) < 0.01 {
                handleInteraction(.sleepy)
            }
        }
    }
    
    private func updateEyePosition(_ location: CGPoint, center: CGPoint) {
        let delta = CGPoint(
            x: (location.x - center.x) / 60,
            y: (location.y - center.y) / 60
        )
        
        // Normalize the values to [-1, 1]
        let magnitude = sqrt(pow(delta.x, 2) + pow(delta.y, 2))
        let normalized = magnitude > 1 ? CGPoint(
            x: delta.x / magnitude,
            y: delta.y / magnitude
        ) : delta
        
        eyePosition = normalized
        debugEyePosition = normalized
    }
}

// Preview
#Preview {
    NotionFace(debugEyePosition: .constant(.zero))
        .padding()
        .background(Color.gray.opacity(0.2))
}
