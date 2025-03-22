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
        
        // Let the colors be vibrant and varied
        let colors: [Color] = [
            Color.purple.opacity(0.7),       // Bright purple
            Color.blue.opacity(0.7),         // Bright blue
            Color.red.opacity(0.7),          // Bright red
            Color.orange.opacity(0.7),       // Bright orange
            Color.green.opacity(0.7),        // Bright green
            Color.pink.opacity(0.7),         // Bright pink
            Color.yellow.opacity(0.7),       // Bright yellow
            Color.cyan.opacity(0.7)          // Bright cyan
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
        case .twentyEight:
            // Explicitly render "28" as text to ensure it appears
            Text("28")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        case .star, .heart, .moon, .sparkle:
            Image(systemName: type.systemName)
                .font(.system(size: 18))
                .foregroundColor(color)
        case .semicolon:
            Text(";")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        case .xSmile:
            // Use the custom XSmileDoodle view instead of text
            XSmileDoodle(color: color)
        case .swirl:
            Image(systemName: type.systemName)
                .font(.system(size: 16))
                .foregroundColor(color)
                .rotationEffect(.degrees(Double.random(in: 0...360)))
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
        Text("✦")
            .font(.system(size: 36, weight: .black))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.6), radius: 5, x: 0, y: 0)
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

// Replace the complex SemicolonDoodle with a simple text-based one
private struct SemicolonDoodle: View {
    let color: Color
    
    var body: some View {
        Text(";")  // Using a real semicolon character
            .font(.system(size: 24, weight: .bold))  // Larger and bolder to be more visible
            .foregroundColor(color)
            .shadow(color: color.opacity(0.5), radius: 2, x: 0, y: 0)  // Add a subtle shadow for visibility
    }
}

// Fixed moon
private struct MoonDoodle: View {
    let color: Color
    let thickness: CGFloat
    
    var body: some View {
        Text("☽")  // Using moon symbol
            .font(.system(size: 32))  // Increased from 20
            .foregroundColor(color)
            .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 0)
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

// Create a custom XSmileDoodle that looks like the image (two X's and a smile)
private struct XSmileDoodle: View {
    let color: Color
    
    var body: some View {
        // Draw the X X smile face using Path for precise control
        ZStack {
            // For better visibility against any background
            Color.clear.frame(width: 30, height: 30)
            
            Path { path in
                // Left X eye
                path.move(to: CGPoint(x: 5, y: 5))
                path.addLine(to: CGPoint(x: 11, y: 11))
                path.move(to: CGPoint(x: 11, y: 5))
                path.addLine(to: CGPoint(x: 5, y: 11))
                
                // Right X eye
                path.move(to: CGPoint(x: 19, y: 5))
                path.addLine(to: CGPoint(x: 25, y: 11))
                path.move(to: CGPoint(x: 25, y: 5))
                path.addLine(to: CGPoint(x: 19, y: 11))
                
                // Smile (curved line)
                path.move(to: CGPoint(x: 7, y: 20))
                path.addQuadCurve(
                    to: CGPoint(x: 23, y: 20),
                    control: CGPoint(x: 15, y: 26)
                )
            }
            .stroke(color, style: StrokeStyle(
                lineWidth: 2.5,       // Thicker lines for visibility
                lineCap: .round,
                lineJoin: .round
            ))
        }
        // Give it a touch more room than other doodles since it's custom drawn
        .frame(width: 30, height: 30)
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

// Add this new doodle type implementation
private struct TwentyEightDoodle: View {
    let color: Color
    
    var body: some View {
        Text("28")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.5), radius: 2, x: 0, y: 0)
    }
}
