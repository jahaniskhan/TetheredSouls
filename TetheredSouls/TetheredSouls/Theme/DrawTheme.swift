// Theme/DrawingTheme.swift
import SwiftUI
import Foundation

enum DrawingTheme {
    // Line Drawing
    struct LineStyle {
        static let thin: CGFloat = 1.5
        static let medium: CGFloat = 2.5
        static let thick: CGFloat = 3.5
        static let wobbleAmplitude: CGFloat = 0.8
    }
    
    // Colors
    struct Colors {
        // Primary palette (muted but playful)
        static let cream = Color(red: 0.98, green: 0.96, blue: 0.92)
        static let charcoal = Color(red: 0.27, green: 0.27, blue: 0.27)
        static let sage = Color(red: 0.75, green: 0.82, blue: 0.73)
        static let dustyRose = Color(red: 0.89, green: 0.71, blue: 0.71)
        static let cloudBlue = Color(red: 0.71, green: 0.82, blue: 0.89)
        
        // Accent colors
        static let sunflower = Color(red: 0.95, green: 0.85, blue: 0.45)
        static let coral = Color(red: 0.95, green: 0.65, blue: 0.55)
        static let mint = Color(red: 0.65, green: 0.89, blue: 0.82)
    }
    
    // Typography
    struct Typography {
        static let display = Font.custom("Quicksand-Bold", size: 32)
        static let title = Font.custom("Quicksand-SemiBold", size: 24)
        static let body = Font.custom("Quicksand-Medium", size: 16)
        static let caption = Font.custom("Quicksand-Regular", size: 12)
    }
    
    // Drawing Helpers
    struct Shapes {
        static func handDrawnRect(_ rect: CGRect) -> Path {
            Path { path in
                let points = generateHandDrawnPoints(for: rect)
                path.move(to: points[0])
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
                path.closeSubpath()
            }
        }
        
        static func handDrawnCircle(center: CGPoint, radius: CGFloat) -> Path {
            let points = 36 // Number of points for smooth circle
            let wobbleRange = LineStyle.wobbleAmplitude
            
            return Path { path in
                for i in 0...points {
                    let angle = (2 * .pi * CGFloat(i)) / CGFloat(points)
                    let wobble = CGFloat.random(in: -wobbleRange...wobbleRange)
                    let adjustedRadius = radius + wobble
                    
                    let x = center.x + adjustedRadius * cos(angle)
                    let y = center.y + adjustedRadius * sin(angle)
                    
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()
            }
        }
        
        static func handDrawnStar(center: CGPoint, radius: CGFloat, points: Int = 5) -> Path {
            let wobbleRange = LineStyle.wobbleAmplitude
            return Path { path in
                let angleStep = (2 * .pi) / Double(points)
                for i in 0...points {
                    let angle = Double(i) * angleStep - .pi / 2
                    let wobble = CGFloat.random(in: -wobbleRange...wobbleRange)
                    
                    let innerRadius = radius * 0.4 + wobble
                    let outerRadius = radius + wobble
                    
                    let point = i % 2 == 0 
                        ? CGPoint(
                            x: center.x + outerRadius * cos(angle),
                            y: center.y + outerRadius * sin(angle)
                        )
                        : CGPoint(
                            x: center.x + innerRadius * cos(angle),
                            y: center.y + innerRadius * sin(angle)
                        )
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                path.closeSubpath()
            }
        }
        
        static func handDrawnHeart(center: CGPoint, size: CGFloat) -> Path {
            let wobbleRange = LineStyle.wobbleAmplitude
            return Path { path in
                let points = 20
                for i in 0...points {
                    let angle = (2 * .pi * Double(i)) / Double(points)
                    let wobble = CGFloat.random(in: -wobbleRange...wobbleRange)
                    
                    // Heart shape parametric equations
                    let x = size * (16 * pow(sin(angle), 3)) / 16
                    let y = -size * (13 * cos(angle) - 5 * cos(2 * angle) - 2 * cos(3 * angle) - cos(4 * angle)) / 16
                    
                    let point = CGPoint(
                        x: center.x + x + wobble,
                        y: center.y + y + wobble
                    )
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addQuadCurve(
                            to: point,
                            control: CGPoint(
                                x: center.x + x + wobble/2,
                                y: center.y + y + wobble/2
                            )
                        )
                    }
                }
            }
        }
        
        static func handDrawnCloud(center: CGPoint, size: CGFloat) -> Path {
            let wobbleRange = LineStyle.wobbleAmplitude
            return Path { path in
                let baseRadius = size * 0.3
                let circles = [
                    (offset: CGPoint(x: -baseRadius, y: 0), radius: baseRadius),
                    (offset: CGPoint(x: baseRadius, y: 0), radius: baseRadius),
                    (offset: CGPoint(x: 0, y: -baseRadius/2), radius: baseRadius * 1.2),
                    (offset: CGPoint(x: -baseRadius * 1.5, y: -baseRadius/3), radius: baseRadius * 0.8),
                    (offset: CGPoint(x: baseRadius * 1.5, y: -baseRadius/3), radius: baseRadius * 0.9)
                ]
                
                for (i, circle) in circles.enumerated() {
                    let points = 12
                    for j in 0...points {
                        let angle = (2 * .pi * Double(j)) / Double(points)
                        let wobble = CGFloat.random(in: -wobbleRange...wobbleRange)
                        
                        let x = center.x + circle.offset.x + (circle.radius + wobble) * cos(angle)
                        let y = center.y + circle.offset.y + (circle.radius + wobble) * sin(angle)
                        
                        if i == 0 && j == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                path.closeSubpath()
            }
        }
        
        private static func generateHandDrawnPoints(for rect: CGRect) -> [CGPoint] {
            let cornerPoints = [
                CGPoint(x: rect.minX, y: rect.minY),  // Top left
                CGPoint(x: rect.maxX, y: rect.minY),  // Top right
                CGPoint(x: rect.maxX, y: rect.maxY),  // Bottom right
                CGPoint(x: rect.minX, y: rect.maxY)   // Bottom left
            ]
            
            // Parameters for controlled randomness
            let wobbleFrequency = 3  // Number of subtle curves per side
            let maxWobbleDistance = LineStyle.wobbleAmplitude  // Max deviation from straight line
            let pointsPerSide = 8    // More points = smoother curve
            
            var allPoints: [CGPoint] = []
            
            // Generate points for each side
            for i in 0..<4 {
                let start = cornerPoints[i]
                let end = cornerPoints[(i + 1) % 4]
                
                // Generate intermediate points with controlled wobble
                for t in 0...pointsPerSide {
                    let progress = CGFloat(t) / CGFloat(pointsPerSide)
                    
                    // Base point on straight line
                    let x = start.x + (end.x - start.x) * progress
                    let y = start.y + (end.y - start.y) * progress
                    
                    // Add subtle wobble using sine wave
                    let wobble = sin(progress * .pi * CGFloat(wobbleFrequency))
                    let wobbleAmount = wobble * maxWobbleDistance
                    
                    // Apply wobble perpendicular to line direction
                    let isVertical = abs(end.x - start.x) < abs(end.y - start.y)
                    let wobblePoint = CGPoint(
                        x: x + (isVertical ? wobbleAmount : 0),
                        y: y + (isVertical ? 0 : wobbleAmount)
                    )
                    
                    allPoints.append(wobblePoint)
                }
            }
            
            return allPoints
        }
    }
}
