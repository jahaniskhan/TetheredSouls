//
//  DoodleElement.swift
//  TetheredSouls
//
//  Created by Jahan khan on 11/10/24.
//
import SwiftUI
import Swift
import CoreFoundation
import Foundation

// MARK: - DoodleElement
// Main view that manages doodle selection and appearance
struct DoodleElement: View {
    private let type: DoodleType
    private let rotation: Double
    private let thickness: CGFloat
    private let color: Color
    
    // Initialize with type, rotation and streak which affects thickness and color intensity
    init(type: DoodleType, rotation: Double, streak: Int) {
        self.type = type
        self.rotation = rotation
        self.thickness = CGFloat(min(streak, 10)) * 0.08 + 0.5
        
        // Let the colors speak their truth
        let colors: [Color] = [
            Theme.block1,        // Pure, unfiltered
            Theme.block2,        // Raw emotion
            Theme.block3,        // Deep connection
            Theme.textPrimary    // The essence
        ]
        
        // Let the color intensity grow with the streak
        let streakIntensity = Double(min(streak, 10)) * 0.1 + 0.6
        self.color = colors[Int.random(in: 0..<colors.count)]
            .opacity(streakIntensity)
    }
    
    var body: some View {
        content
            .rotationEffect(.degrees(rotation))
    }
    
    // MARK: - Private Views
    // Switch between different doodle types
    @ViewBuilder
    private var content: some View {
        switch type {
        case .star: StarDoodle(color: color)
        case .heart: HeartDoodle(color: color)
        case .semicolon: SemicolonDoodle(color: color)
        case .moon: MoonDoodle(color: color, thickness: thickness)
        case .swirl: SwirlDoodle(color: color, thickness: thickness)
        case .xSmile: XSmileDoodle(color: color)
        }
    }
}

// MARK: - Supporting Types
public enum DoodleType: Hashable {
    case star, heart, semicolon, moon, swirl, xSmile  // Simple, clean symbols
}

// MARK: - Private Components

// Simple star emoticon
private struct StarDoodle: View {
    let color: Color
    
    var body: some View {
        Text("✧")  // Clean sparkle
            .font(.system(size: 20))
            .foregroundColor(color)
    }
}

// Simple heart emoticon
private struct HeartDoodle: View {
    let color: Color
    
    var body: some View {
        Text("♡")  // Simple outline heart
            .font(.system(size: 20))
            .foregroundColor(color)
    }
}

// Better semicolon
private struct SemicolonDoodle: View {
    let color: Color
    
    var body: some View {
        Text("⁏")  // Using a more stylized semicolon
            .font(.system(size: 20))
            .foregroundColor(color)
    }
}

// Fixed moon
private struct MoonDoodle: View {
    let color: Color
    let thickness: CGFloat
    
    var body: some View {
        Text("☽")  // Using moon symbol instead of drawing
            .font(.system(size: 20))
            .foregroundColor(color)
    }
}

// Gentle swirl
private struct SwirlDoodle: View {
    let color: Color
    let thickness: CGFloat
    
    var body: some View {
        Text("꩜")  // Gentle circular swirl
            .font(.system(size: 20))
            .foregroundColor(color)
    }
}

// X-eyed smile - minimalist tattoo style
private struct XSmileDoodle: View {
    let color: Color
    
    var body: some View {
        Path { path in
            // Left X
            path.move(to: CGPoint(x: 8, y: 8))
            path.addLine(to: CGPoint(x: 12, y: 12))
            path.move(to: CGPoint(x: 12, y: 8))
            path.addLine(to: CGPoint(x: 8, y: 12))
            
            // Right X
            path.move(to: CGPoint(x: 18, y: 8))
            path.addLine(to: CGPoint(x: 22, y: 12))
            path.move(to: CGPoint(x: 22, y: 8))
            path.addLine(to: CGPoint(x: 18, y: 12))
            
            // Simple curved smile
            path.move(to: CGPoint(x: 8, y: 18))
            path.addQuadCurve(
                to: CGPoint(x: 22, y: 18),
                control: CGPoint(x: 15, y: 22)
            )
        }
        .stroke(color, style: StrokeStyle(
            lineWidth: 1.5,
            lineCap: .round,
            lineJoin: .round
        ))
    }
}
