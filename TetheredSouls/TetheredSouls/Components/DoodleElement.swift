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
        self.thickness = CGFloat(min(streak, 10)) * 0.2 + 1.0
        
        // Let the colors speak their truth
        let colors: [Color] = [
            Theme.block1,        // Pure, unfiltered
            Theme.block2,        // Raw emotion
            Theme.block3,        // Deep connection
            Theme.textPrimary    // The essence
        ]
        
        // Let the color intensity grow with the streak
        let streakIntensity = Double(min(streak, 10)) * 0.2 + 0.8
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
        case .sparkle: SparkleDoodle(color: color)
        case .puzzle: PuzzleDoodle(color: color)
        }
    }
}

// MARK: - Supporting Types
// DELETE THESE LINES (keep the Models/DoodleType.swift version)
// enum DoodleType: String, CaseIterable {
//     case star = "star.fill"
//     ...
// }

// MARK: - Private Components

// Simple star emoticon
private struct StarDoodle: View {
    let color: Color
    
    var body: some View {
        Text("✦")  // Bolder star symbol
            .font(.system(size: 28, weight: .black)) // Increased size and weight
            .foregroundColor(color)
            .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 0)
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

// Add missing doodle types
private struct SparkleDoodle: View {
    let color: Color
    
    var body: some View {
        Text("✨")
            .font(.system(size: 20))
            .foregroundColor(color)
    }
}

private struct PuzzleDoodle: View {
    let color: Color
    
    var body: some View {
        Text("🧩")
            .font(.system(size: 20))
            .foregroundColor(color)
    }
}
