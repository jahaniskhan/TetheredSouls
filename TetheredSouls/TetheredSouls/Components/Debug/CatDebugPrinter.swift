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
        size: CGFloat,
        // (Optional) If you have direct access to the user's touch location:
        //  pass it here. If you don't, you can pass nil or remove this param.
        rawTouch: CGPoint? = nil
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastPrintTime) >= printThrottle else { return }
        lastPrintTime = now

        #if DEBUG
        // 1) Eye centers in the local coordinate space
        let leftEyeCenter = CGPoint(
            x: size * EyeGeometry.Configuration.leftEyeCenter.x,
            y: size * EyeGeometry.Configuration.leftEyeCenter.y
        )
        let rightEyeCenter = CGPoint(
            x: size * EyeGeometry.Configuration.rightEyeCenter.x,
            y: size * EyeGeometry.Configuration.rightEyeCenter.y
        )

        // 2) Expected center = (size/2, size/2)
        let expectedCenter = CGPoint(x: size * 0.5, y: size * 0.5)
        let centerDelta = CGPoint(
            x: centerPoint.x - expectedCenter.x,
            y: centerPoint.y - expectedCenter.y
        )

        // 3) Eye geometry for boundary checks
        let leftEyeGeometry = EyeGeometry(
            role: .master,
            center: leftEyeCenter,
            boundaryA: EyeGeometry.Configuration.boundaryA,
            boundaryB: EyeGeometry.Configuration.boundaryB
        )
        let rightEyeGeometry = EyeGeometry(
            role: .slave,
            center: rightEyeCenter,
            boundaryA: EyeGeometry.Configuration.boundaryA,
            boundaryB: EyeGeometry.Configuration.boundaryB
        )

        // 4) Check if offset is within ellipse bounds
        let leftWithinEllipse  = leftEyeGeometry.isOffsetWithinEllipse(leftState.offset)
        let rightWithinEllipse = rightEyeGeometry.isOffsetWithinEllipse(rightState.offset)

        // 5) Additional metrics: raw ellipse equation values + distances
        let leftEquationValue  = ellipseEquationValue(
            offset: leftState.offset,
            a: EyeGeometry.Configuration.boundaryA,
            b: EyeGeometry.Configuration.boundaryB
        )
        let rightEquationValue = ellipseEquationValue(
            offset: rightState.offset,
            a: EyeGeometry.Configuration.boundaryA,
            b: EyeGeometry.Configuration.boundaryB
        )

        // Distances from eye center
        let leftOffsetDistance  = hypot(leftState.offset.x, leftState.offset.y)
        let rightOffsetDistance = hypot(rightState.offset.x, rightState.offset.y)

        // Boundary distances
        let leftBoundaryDist  = hypot(EyeGeometry.Configuration.boundaryA, EyeGeometry.Configuration.boundaryB)
        let rightBoundaryDist = leftBoundaryDist  // same A/B if eyes match

        print("""

        🔍 GEOMETRY STATE
        ----------------
        1) Visual Center vs. Expected
           - Expected center:     \(formatPoint(expectedCenter))
           - Actual centerPoint:  \(formatPoint(centerPoint))
           - Delta:               \(formatPoint(centerDelta))

        2) Eye Centers (local coords):
           - Left Eye Center:     \(formatPoint(leftEyeCenter))
           - Right Eye Center:    \(formatPoint(rightEyeCenter))

        3) Pupils
           (We measure offset from each eye center.)

           Left Eye:
             offset:      \(formatPoint(leftState.offset))
             eq. value:   \(String(format: "%.3f", leftEquationValue)) \
             => (<=1 is inside ellipse)
             withinEllipse:  \(leftWithinEllipse)
             distance:       \(String(format: "%.2f", leftOffsetDistance))
             boundaryDist:    ~\(String(format: "%.2f", leftBoundaryDist))
             angle:           \(String(format: "%.2f", leftState.angle * 180 / .pi))°
             rotation:        \(String(format: "%.2f", leftState.rotation * 180 / .pi))°

           Right Eye:
             offset:      \(formatPoint(rightState.offset))
             eq. value:   \(String(format: "%.3f", rightEquationValue))
             withinEllipse:  \(rightWithinEllipse)
             distance:       \(String(format: "%.2f", rightOffsetDistance))
             boundaryDist:    ~\(String(format: "%.2f", rightBoundaryDist))
             angle:           \(String(format: "%.2f", rightState.angle * 180 / .pi))°
             rotation:        \(String(format: "%.2f", rightState.rotation * 180 / .pi))°

        4) Optional: Touch Location
           \(rawTouch != nil ?
                "User's drag: " + formatPoint(rawTouch!) :
                "No active drag location.")

        5) Ellipse Boundaries:
           - width:  \(EyeGeometry.Configuration.boundaryA * 2)
           - height: \(EyeGeometry.Configuration.boundaryB * 2)

        ----------------
        """)

        #endif
    }

    // MARK: - Helper Functions
    /// ellipseEquationValue = (x^2 / a^2) + (y^2 / b^2).
    /// If <= 1 => offset is inside ellipse; if ~1 => on boundary; >1 => outside.
    private static func ellipseEquationValue(offset: CGPoint, a: CGFloat, b: CGFloat) -> CGFloat {
        let x2 = offset.x * offset.x
        let y2 = offset.y * offset.y
        let a2 = a * a
        let b2 = b * b
        return (x2 / a2) + (y2 / b2)
    }

    private static func formatPoint(_ point: CGPoint) -> String {
        String(format: "(%.2f, %.2f)", point.x, point.y)
    }
}
