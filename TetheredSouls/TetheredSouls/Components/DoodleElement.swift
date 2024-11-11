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
struct DoodleElement: View {
    private let type: DoodleType
    private let rotation: Double
    private let thickness: CGFloat
    private let color: Color
    
    init(type: DoodleType, rotation: Double, streak: Int) {
        self.type = type
        self.rotation = rotation
        // Thicker lines for higher streaks
        self.thickness = CGFloat(min(streak, 10)) * 0.3 + 1.0
        // Color intensity based on streak
        self.color = Theme.textPrimary.opacity(Double(min(streak, 10)) * 0.1 + 0.3)
    }
    
    var body: some View {
        content
            .rotationEffect(.degrees(rotation))
    }
    
    // MARK: - Private Views
    @ViewBuilder
    private var content: some View {
        switch type {
        case .star: StarDoodle(color: color, thickness: thickness)
        case .heart: HeartDoodle()
        case .spiral: SpiralDoodle()
        case .scribble: ScribbleDoodle()
        }
    }
}

// MARK: - Supporting Types
public enum DoodleType: Hashable {
    case star, heart, spiral, scribble
}

// MARK: - Private Components
private struct StarDoodle: View {
    let color: Color
    let thickness: CGFloat
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 15, y: 15)
            let points = (0..<5).map { i -> CGPoint in
                let segments: CGFloat = 5
                let angle: CGFloat = CGFloat(i) * 2 * CGFloat.pi / segments
                return CGPoint(
                    x: center.x + 12 * cos(angle),
                    y: center.y + 12 * sin(angle)
                )
            }
            path.move(to: points[0])
            points[1...].forEach { path.addLine(to: $0) }
            path.closeSubpath()
        }
        .stroke(color, style: StrokeStyle(
            lineWidth: thickness,
            lineCap: .round,
            lineJoin: .round
        ))
    }
}

private struct HeartDoodle: View {
    var body: some View {
        GeometryReader { geometry in
            let width: CGFloat = geometry.size.width
            let height: CGFloat = geometry.size.height
            
            Path { path in
                let startPoint = CGPoint(x: width * 0.5, y: height * 0.3)
                path.move(to: startPoint)
                
                // Left curve
                path.addCurve(
                    to: CGPoint(x: width * 0.5, y: height * 0.8),
                    control1: CGPoint(x: width * 0.2, y: height * 0.4),
                    control2: CGPoint(x: width * 0.3, y: height * 0.7)
                )
                
                // Complete the heart shape
                path.addCurve(
                    to: startPoint,
                    control1: CGPoint(x: width * 0.7, y: height * 0.7),
                    control2: CGPoint(x: width * 0.8, y: height * 0.4)
                )
            }
            .stroke(Theme.textPrimary.opacity(0.3), style: StrokeStyle(
                lineWidth: 1,
                lineCap: .round,
                lineJoin: .round
            ))
        }
    }
}

private struct SpiralDoodle: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 15, y: 15))
            var angle: CGFloat = 0
            while angle < CGFloat.pi * 6 {
                let radius: CGFloat = 2 + angle * 0.5  // Changed division to multiplication
                let x: CGFloat = 15 + radius * cos(angle)
                let y: CGFloat = 15 + radius * sin(angle)
                path.addLine(to: CGPoint(x: x, y: y))
                angle += 0.1
            }
        }
        .stroke(Theme.textPrimary.opacity(0.3), style: StrokeStyle(
            lineWidth: 1,
            lineCap: .round,
            lineJoin: .round
        ))
    }
}

private struct ScribbleDoodle: View {
    var body: some View {
        let points = generatePoints()
        
        Path { path in
            path.move(to: points[0])
            
            for i in 1..<points.count {
                let control = CGPoint(
                    x: (points[i].x + points[i-1].x) * 0.5,
                    y: points[i-1].y + CGFloat.random(in: -2...2)
                )
                path.addQuadCurve(to: points[i], control: control)
            }
        }
        .stroke(Theme.textPrimary.opacity(0.3), style: scribbleStyle)
    }
    
    private func generatePoints() -> [CGPoint] {
        (0..<8).map { i in
            CGPoint(
                x: 10 + CGFloat(i) * 2 + CGFloat.random(in: -1...1),
                y: 15 + sin(CGFloat(i)) * 3 + CGFloat.random(in: -1...1)
            )
        }
    }
    
    private var scribbleStyle: StrokeStyle {
        StrokeStyle(
            lineWidth: 1,
            lineCap: .round,
            lineJoin: .round,
            dash: [1, 2]
        )
    }
}
