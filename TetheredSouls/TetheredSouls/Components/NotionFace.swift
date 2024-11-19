//
//  NotionFace.swift
//  TetheredSouls
//
//  Created by Jahan khan on 11/9/24.
//MARK: - PARENT OF CATFEATURES

import SwiftUI
import Foundation
import CoreGraphics

struct NotionFace: View {
    // MARK: - State
    @State private var phase = 0.0
    @State private var isWatching = false
    @State private var mood: CatMood = .normal
    @State private var eyePosition: CGPoint = .zero
    @State private var touchLocation: CGPoint?
    
    // MARK: - Configuration
    struct NotionFaceConfiguration {
        static let updateInterval: TimeInterval = 0.05
        static let resetDelay: TimeInterval = 0.5
        static let sleepChance: Double = 0.01
    }
    
    // MARK: - Timer
    let timer = Timer.publish(
        every: NotionFaceConfiguration.updateInterval,
        on: .main,
        in: .common
    ).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            // Left Eye Geometry and Pupil State
            let leftEyeCenter = CGPoint(
                x: size * EyeGeometry.Configuration.leftEyeCenter.x,
                y: size * EyeGeometry.Configuration.leftEyeCenter.y
            )
            let leftEyeGeometry = EyeGeometry(
                center: leftEyeCenter,
                boundaryA: EyeGeometry.Configuration.boundaryA,
                boundaryB: EyeGeometry.Configuration.boundaryB
            )
            let leftPupilState = leftEyeGeometry.calculatePupilPosition(
                for: CGPoint(
                    x: leftEyeCenter.x + eyePosition.x,
                    y: leftEyeCenter.y + eyePosition.y
                )
            )

            // Right Eye Geometry and Pupil State
            let rightEyeCenter = CGPoint(
                x: size * EyeGeometry.Configuration.rightEyeCenter.x,
                y: size * EyeGeometry.Configuration.rightEyeCenter.y
            )
            let rightEyeGeometry = EyeGeometry(
                center: rightEyeCenter,
                boundaryA: EyeGeometry.Configuration.boundaryA,
                boundaryB: EyeGeometry.Configuration.boundaryB
            )
            let rightPupilState = rightEyeGeometry.calculatePupilPosition(
                for: CGPoint(
                    x: rightEyeCenter.x + eyePosition.x,
                    y: rightEyeCenter.y + eyePosition.y
                )
            )
            
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
                    touchLocation: eyePosition,
                    onDebugUpdate: { left, right in
                        CatDebugPrinter.printGeometryState(
                            leftState: left,
                            rightState: right,
                            centerPoint: CGPoint(
                                x: EyeGeometry.Configuration.baseSize / 2,
                                y: EyeGeometry.Configuration.baseSize / 2
                            ),
                            size: size
                        )
                    }
                )
                .frame(width: 120, height: 120)
            }
            .coordinateSpace(name: "NotionFaceCoordinateSpace")
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleInteraction(.watching)
                        let location = value.location(in: .named("NotionFaceCoordinateSpace"))
                        touchLocation = location
                        eyePosition = location
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + NotionFaceConfiguration.resetDelay
                        ) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                touchLocation = nil
                                eyePosition = .zero
                            }
                            resetMood()
                        }
                    }
            )
            .onReceive(timer) { _ in
                withAnimation(
                    .linear(duration: NotionFaceConfiguration.updateInterval)
                ) {
                    phase += NotionFaceConfiguration.updateInterval
                    updateMoodBasedOnTime()
                }
            }
            .accessibilityIdentifier("CatView")
        }
    }
    
    // MARK: - Interaction Methods
    private func handleInteraction(_ newMood: CatMood) {
        withAnimation(.easeInOut(duration: 0.3)) {
            mood = newMood
            isWatching = true
        }
    }
    
    private func resetMood() {
        withAnimation(.easeOut(duration: 0.3)) {
            mood = .normal
            isWatching = false
        }
    }
    
    private func updateMoodBasedOnTime() {
        if Double.random(in: 0...1) < NotionFaceConfiguration.sleepChance {
            handleInteraction(.sleepy)
        }
    }
    
    private func updateEyePosition(_ location: CGPoint, eyeGeometry: EyeGeometry) {
        let pupilState = eyeGeometry.calculatePupilPosition(for: location)
        
        withAnimation(.linear(duration: NotionFaceConfiguration.updateInterval)) {
            eyePosition = pupilState.offset
        }
    }
}

// MARK: - Preview
struct NotionFace_Previews: PreviewProvider {
    static var previews: some View {
        NotionFace()
            .padding()
            .background(Color.gray.opacity(0.2))
    }
}
