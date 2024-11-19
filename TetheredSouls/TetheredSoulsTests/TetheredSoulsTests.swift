import Testing
import SwiftUI
@testable import TetheredSouls

struct TetheredSoulsTests {
    // Constants for testing
    let centerPoint = CGPoint(x: 35, y: 60)
    
    @Test
    func testPupilOrientationAndTangents() async throws {
        let geometry = CatFeatures.EyeGeometry(
            center: self.centerPoint,
            boundaryA: 8,
            boundaryB: 6
        )
        
        // Test cardinal directions
        let testPoints: [(point: CGPoint, expectedRotation: Double)] = [
            (CGPoint(x: centerPoint.x + 60, y: centerPoint.y),     // Right
             .pi/2),                                               // 90°
            (CGPoint(x: centerPoint.x, y: centerPoint.y - 60),     // Up
             0),                                                   // 0°
            (CGPoint(x: centerPoint.x - 60, y: centerPoint.y),     // Left
             -.pi/2),                                             // -90°
            (CGPoint(x: centerPoint.x, y: centerPoint.y + 60),     // Down
             .pi)                                                 // 180°
        ]
        
        for (point, expectedRotation) in testPoints {
            let result = geometry.calculatePupilPosition(for: point)
            
            // Test tangent angle
            let rotationDiff = abs(result.rotation - expectedRotation)
            #expect(rotationDiff < 0.001 || abs(rotationDiff - 2 * .pi) < 0.001,
                   "Incorrect tangent rotation for point \(point)")
            
            // Test perpendicularity
            let radiusAngle = result.angle
            let tangentAngle = result.rotation
            let dotProduct = cos(radiusAngle) * cos(tangentAngle) + 
                           sin(radiusAngle) * sin(tangentAngle)
            #expect(abs(dotProduct) < 0.001,
                   "Radius and tangent should be perpendicular")
        }
    }
    
    @Test
    func testSmoothRotationTransition() async throws {
        let geometry = CatFeatures.EyeGeometry(
            center: self.centerPoint,
            boundaryA: 8,
            boundaryB: 6
        )
        
        // Test smooth transition between close points
        let point1 = CGPoint(x: centerPoint.x + 30, y: centerPoint.y)
        let point2 = CGPoint(x: centerPoint.x + 30, y: centerPoint.y + 1)
        
        let result1 = geometry.calculatePupilPosition(for: point1)
        let result2 = geometry.calculatePupilPosition(for: point2)
        
        // Rotation change should be small for small position change
        let rotationDiff = abs(result2.rotation - result1.rotation)
        #expect(rotationDiff < 0.1,
               "Rotation should change smoothly between nearby points")
    }
}
