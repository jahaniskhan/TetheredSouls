import SwiftUI

struct CatFeatures: View {
    let phase: Double
    let isWatching: Bool
    
    private func wobble(_ point: CGPoint) -> CGPoint {
        let baseWobble = sin(phase * 2) * 0.5
        return CGPoint(
            x: point.x + baseWobble,
            y: point.y + cos(phase * 2) * 0.3
        )
    }
    
    var body: some View {
        ZStack {
            // Cat ears with pink inside
            Path { path in
                // Left ear
                path.move(to: wobble(CGPoint(x: 12, y: 12)))
                path.addQuadCurve(
                    to: wobble(CGPoint(x: 20, y: 12)),
                    control: CGPoint(x: 16, y: 4)
                )
                
                // Right ear
                path.move(to: wobble(CGPoint(x: 28, y: 12)))
                path.addQuadCurve(
                    to: wobble(CGPoint(x: 36, y: 12)),
                    control: CGPoint(x: 32, y: 4)
                )
            }
            .stroke(Color.black, lineWidth: 1.5)
            
            // Ear insides
            Path { path in
                path.addEllipse(in: CGRect(x: 15, y: 8, width: 6, height: 4))
                path.addEllipse(in: CGRect(x: 31, y: 8, width: 6, height: 4))
            }
            .fill(Color.pink.opacity(0.6))
            
            // Eyes with blinking animation
            let eyeShift = isWatching ? 1.5 : sin(phase * 3) * 0.5
            Path { path in
                let leftEye = wobble(CGPoint(x: 15 + eyeShift, y: 18))
                path.addEllipse(in: CGRect(x: leftEye.x, y: leftEye.y, width: 4, height: abs(sin(phase * 5)) * 3 + 1))
                
                let rightEye = wobble(CGPoint(x: 25 + eyeShift, y: 18))
                path.addEllipse(in: CGRect(x: rightEye.x, y: rightEye.y, width: 4, height: abs(sin(phase * 5)) * 3 + 1))
            }
            .fill(Color.black)
            
            // Cute nose
            Path { path in
                let nose = wobble(CGPoint(x: 20, y: 22))
                path.addEllipse(in: CGRect(x: nose.x, y: nose.y, width: 3, height: 2))
            }
            .fill(Color.pink)
            
            // Curved whiskers
            Path { path in
                // Left whiskers
                for y in [-2, 0, 2] {
                    let start = wobble(CGPoint(x: 8, y: 22 + Double(y)))
                    let end = wobble(CGPoint(x: 15, y: 22 + Double(y)))
                    path.move(to: start)
                    path.addQuadCurve(
                        to: end,
                        control: CGPoint(x: 11, y: 21 + Double(y))
                    )
                }
                // Right whiskers
                for y in [-2, 0, 2] {
                    let start = wobble(CGPoint(x: 25, y: 22 + Double(y)))
                    let end = wobble(CGPoint(x: 32, y: 22 + Double(y)))
                    path.move(to: start)
                    path.addQuadCurve(
                        to: end,
                        control: CGPoint(x: 29, y: 21 + Double(y))
                    )
                }
            }
            .stroke(Color.black.opacity(0.6), lineWidth: 0.8)
            
            // Cute mouth
            Path { path in
                let mouthCenter = wobble(CGPoint(x: 20, y: 25))
                path.move(to: CGPoint(x: mouthCenter.x - 2, y: mouthCenter.y))
                path.addQuadCurve(
                    to: CGPoint(x: mouthCenter.x + 2, y: mouthCenter.y),
                    control: CGPoint(x: mouthCenter.x, y: mouthCenter.y + 1)
                )
            }
            .stroke(Color.black.opacity(0.6), lineWidth: 0.8)
        }
    }
}
