import SwiftUI

struct CatFeatures: View {
    let phase: Double
    let isWatching: Bool
    let mood: CatMood
    let eyePosition: CGPoint
    
    private struct EyeGeometry {
        let center: CGPoint
        let boundaryA: CGFloat  // horizontal radius
        let boundaryB: CGFloat  // vertical radius
        
        func calculatePupilPosition(for touchPoint: CGPoint) -> (position: CGPoint, angle: Double) {
            // Calculate angle from eye center to touch point
            let deltaX = touchPoint.x - center.x
            let deltaY = touchPoint.y - center.y
            let theta = atan2(deltaY, deltaX)
            
            // Calculate constrained position within elliptical boundary
            let constrainedX = boundaryA * cos(theta)
            let constrainedY = boundaryB * sin(theta)
            
            return (
                CGPoint(x: center.x + constrainedX, y: center.y + constrainedY),
                theta
            )
        }
    }
    
    private func calculatePupilOffset(basePosition: CGPoint) -> (offset: CGPoint, angle: Double) {
        let eyeGeometry = EyeGeometry(
            center: basePosition,
            boundaryA: 8,  // Max horizontal movement
            boundaryB: 6   // Max vertical movement
        )
        
        return eyeGeometry.calculatePupilPosition(for: CGPoint(
            x: basePosition.x + eyePosition.x * 60,
            y: basePosition.y + eyePosition.y * 60
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Ears with adjusted size and position
                Group {
                    // Left ear
                    Image("EarHump")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.7)  // Increased from 0.5
                        .position(x: size * 0.25, y: size * 0.15)
                        .scaleEffect(x: 1.2)
                    
                    // Right ear
                    Image("EarHump")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.7)  // Increased from 0.5
                        .position(x: size * 0.75, y: size * 0.15)
                        .scaleEffect(x: 1.2)
                    
                    // Inner ears with adjusted positioning
                }
                
                // Eyes with adjusted sizing and positioning
                Group {
                    // Base eye whites
                    Image("balls")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.9)  // Increased size
                    
                    // Pupils with pendulum movement
                    ZStack {
                        // Left pupil
                        Image("Pupil")
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.75)  // Increased from 0.35
                            .position(x: size * 0.35, y: size * 0.5)
                            .offset(x: calculatePupilOffset(basePosition: CGPoint(x: size * 0.35, y: size * 0.5)).offset.x,
                                    y: calculatePupilOffset(basePosition: CGPoint(x: size * 0.35, y: size * 0.5)).offset.y)
                        
                        // Right pupil
                        Image("Pupil")
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.75)  // Increased from 0.35
                            .position(x: size * 0.65, y: size * 0.5)
                            .offset(x: calculatePupilOffset(basePosition: CGPoint(x: size * 0.65, y: size * 0.5)).offset.x,
                                    y: calculatePupilOffset(basePosition: CGPoint(x: size * 0.65, y: size * 0.5)).offset.y)
                    }
                }
                .frame(width: size * 0.9)
                .position(x: size * 0.5, y: size * 0.45)
                
                // Mouth and whiskers with adjusted size
                Group {
                    Image("Whiskers")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.9)
                    
                    Image(getMouthAsset())
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.35)
                }
                .position(x: size * 0.5, y: size * 0.7)
            }
        }
    }
    
    private func getMouthAsset() -> String {
        switch mood {
        case .sleepy:
            return "SleepyMouth"
        case .happy:
            return "justMouth"
        default:
            return "ClosedMouth"
        }
    }
}

enum CatMood {
    case normal
    case happy
    case sad
    case sleepy
    case watching
}

// Preview
struct CatFeatures_Previews: PreviewProvider {
    static var previews: some View {
        CatFeatures(
            phase: 0,
            isWatching: false,
            mood: .normal,
            eyePosition: .zero
        )
        .frame(width: 120, height: 120) // Increased from 100 to match new size
        .background(Color.white)
        .previewLayout(.fixed(width: 200, height: 200))
    }
}
