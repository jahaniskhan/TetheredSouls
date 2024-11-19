import SwiftUI
import Foundation

struct CatDebugPrinter {
    // MARK: - Debug Variables
    private static var lastPrintTime = Date()
    private static let printThrottle: TimeInterval = 0.5  // Print every 0.5 seconds
    
    // MARK: - Debug Prints
    static func printGeometryState(
        leftState: EyeGeometry.PupilState,
        rightState: EyeGeometry.PupilState,
        centerPoint: CGPoint,
        size: CGFloat
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastPrintTime) >= printThrottle else { return }
        lastPrintTime = now
        
        #if DEBUG
        // Calculate expected center
        let expectedCenter = CGPoint(x: size * 0.5, y: size * 0.5)
        let centerDelta = CGPoint(
            x: abs(centerPoint.x - expectedCenter.x),
            y: abs(centerPoint.y - expectedCenter.y)
        )
        
        // Calculate eye centers
        let leftEyeCenter = CGPoint(
            x: size * EyeGeometry.Configuration.leftEyeCenter.x,
            y: size * EyeGeometry.Configuration.leftEyeCenter.y
        )
        let rightEyeCenter = CGPoint(
            x: size * EyeGeometry.Configuration.rightEyeCenter.x,
            y: size * EyeGeometry.Configuration.rightEyeCenter.y
        )
        
        // Since we now create separate EyeGeometry instances for each eye with their own centers,
        // we need to create those instances here as well for accurate calculations.
        let leftEyeGeometry = EyeGeometry(
            center: leftEyeCenter,
            boundaryA: EyeGeometry.Configuration.boundaryA,
            boundaryB: EyeGeometry.Configuration.boundaryB
        )
        let rightEyeGeometry = EyeGeometry(
            center: rightEyeCenter,
            boundaryA: EyeGeometry.Configuration.boundaryA,
            boundaryB: EyeGeometry.Configuration.boundaryB
        )
        
        // Calculate tangent angles
        let leftTangentAngle = leftEyeGeometry.calculateTangentAngle(offset: leftState.offset)
        let rightTangentAngle = rightEyeGeometry.calculateTangentAngle(offset: rightState.offset)
        
        // Convert angles to degrees
        let leftTangentDegrees = leftTangentAngle != nil ? leftTangentAngle! * 180 / .pi : nil
        let rightTangentDegrees = rightTangentAngle != nil ? rightTangentAngle! * 180 / .pi : nil
        
        // Check if offsets are within ellipse boundaries
        let leftWithinEllipse = leftEyeGeometry.isOffsetWithinEllipse(offset: leftState.offset)
        let rightWithinEllipse = rightEyeGeometry.isOffsetWithinEllipse(offset: rightState.offset)
        
        print("""
        
        🔍 GEOMETRY STATE
        ----------------
        Center Alignment:
        Expected: \(formatPoint(expectedCenter))
        Actual:   \(formatPoint(centerPoint))
        Delta:    \(formatPoint(centerDelta))
        
        Eye Centers:
        Left:  \(formatPoint(leftEyeCenter))
        Right: \(formatPoint(rightEyeCenter))
        
        Pupil States:
        Left Eye:
          Offset: \(formatPoint(leftState.offset))
          Within Ellipse: \(leftWithinEllipse)
          Angle: \(String(format: "%.4f", leftState.angle * 180 / .pi))°
          Rotation: \(String(format: "%.4f", leftState.rotation * 180 / .pi))°
          Tangent Angle: \(leftTangentDegrees != nil ? "\(String(format: "%.4f", leftTangentDegrees!))°" : "Undefined")
        Right Eye:
          Offset: \(formatPoint(rightState.offset))
          Within Ellipse: \(rightWithinEllipse)
          Angle: \(String(format: "%.4f", rightState.angle * 180 / .pi))°
          Rotation: \(String(format: "%.4f", rightState.rotation * 180 / .pi))°
          Tangent Angle: \(rightTangentDegrees != nil ? "\(String(format: "%.4f", rightTangentDegrees!))°" : "Undefined")
        
        Boundaries:
        Width:  \(EyeGeometry.Configuration.boundaryA * 2)
        Height: \(EyeGeometry.Configuration.boundaryB * 2)
        ----------------
        
        """)
        #endif
    }
    
    // MARK: - Helper Functions
    private static func formatPoint(_ point: CGPoint) -> String {
        String(format: "(%.2f, %.2f)", point.x, point.y)
    }
}
