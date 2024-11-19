import SwiftUI

struct EyeGeometry {
    // MARK: - Configuration
    struct Configuration {
        // MARK: - Layout
        static let baseSize: CGFloat = 100.0
        // Adjust these based on your 'balls.png' image
        static let leftEyeCenter = CGPoint(x: 0.35, y: 0.5)  
        static let rightEyeCenter = CGPoint(x: 0.65, y: 0.5)
        static let boundaryA: CGFloat = 9.2  // Semi-major axis
        static let boundaryB: CGFloat = 6.7  // Semi-minor axis

        // MARK: - Performance
        static let scaleNormalization: CGFloat = 150.0//60.0
        static let centerThreshold: CGFloat = 0.001
    }

    // MARK: - Types
    struct PupilState: Equatable {
        let offset: CGPoint
        let angle: Double
        let rotation: Double

        var debugDescription: String {
            """
            Offset: (x: \(String(format: "%.2f", offset.x)), y: \(String(format: "%.2f", offset.y)))
            Angle: \(String(format: "%.2f", angle * 180 / .pi))°
            Rotation: \(String(format: "%.2f", rotation * 180 / .pi))°
            """
        }

        static func == (lhs: PupilState, rhs: PupilState) -> Bool {
            lhs.offset == rhs.offset &&
            lhs.angle == rhs.angle &&
            lhs.rotation == rhs.rotation
        }
    }

    // MARK: - Properties
    let center: CGPoint
    let boundaryA: CGFloat
    let boundaryB: CGFloat

    // MARK: - Initialization
    init(center: CGPoint, boundaryA: CGFloat, boundaryB: CGFloat) {
        self.center = center
        self.boundaryA = boundaryA
        self.boundaryB = boundaryB
    }

    func initialPupilState() -> PupilState {
        // Set the initial offset at the covertex (0, boundaryB)
        let offset = CGPoint(x: 0, y: boundaryB)
        let tangentAngle = calculateTangentAngle(offset: offset) ?? 0
        return PupilState(offset: offset, angle: 0, rotation: tangentAngle)
    }

    // MARK: - Public Methods
    func calculatePupilPosition(for touchPoint: CGPoint) -> PupilState {
        // Removed center point check since we want pupils to always be on ellipse boundary
        // Removed distance check since we want pupils to always be on ellipse boundary
        // Removed scale factor since we want pupils to always be on full ellipse boundary
        
        let (deltaX, deltaY) = calculateDeltas(from: touchPoint)
        let theta = atan2(deltaY, deltaX)
        
        // Calculate the offset on the ellipse boundary
        let constrainedX = boundaryA * cos(theta)
        let constrainedY = boundaryB * sin(theta)
        let offset = CGPoint(x: constrainedX, y: constrainedY)
        
        // Calculate the tangent angle at the constrained position
        let tangentAngle = calculateTangentAngle(offset: offset) ?? 0
        
        return PupilState(
            offset: offset,
            angle: theta,
            rotation: tangentAngle
        )
    }

    // MARK: - Private Methods
    private func isCenterPoint(_ point: CGPoint) -> Bool {
        abs(point.x - center.x) < Configuration.centerThreshold && abs(point.y - center.y) < Configuration.centerThreshold
    }

    private func calculateDeltas(from point: CGPoint) -> (x: CGFloat, y: CGFloat) {
        (point.x - center.x, point.y - center.y)
    }

    private func calculateDistance(deltaX: CGFloat, deltaY: CGFloat) -> CGFloat {
        sqrt(deltaX * deltaX + deltaY * deltaY)
    }

    private func calculateConstrainedOffset(theta: Double, scale: CGFloat) -> (x: CGFloat, y: CGFloat) {
        // Reduce the movement range to keep pupils more within bounds
        let x = boundaryA * cos(theta) * scale //* 0.8
        let y = boundaryB * sin(theta) * scale //* 0.8
        return (x, y)
    }

    // MARK: - Tangent Angle Calculation
    func calculateTangentAngle(offset: CGPoint) -> Double? {
        let x = offset.x
        let y = offset.y
        let a = boundaryA
        let b = boundaryB

        // Avoid division by zero
        guard y != 0 else {
            return x >= 0 ? -.pi / 2 : .pi / 2
        }

        let numerator = -b * b * x
        let denominator = a * a * y

        var tangentAngle = atan2(numerator, denominator)

        // Limit the rotation to a reasonable range, e.g., between -45° and +45°
        let maxRotation = (.pi / 4)  // 45 degrees in radians
        tangentAngle = max(min(tangentAngle, maxRotation), -maxRotation)

        return tangentAngle
    }

    // MARK: - Ellipse Boundary Check
    func isOffsetWithinEllipse(offset: CGPoint) -> Bool {
        let x = offset.x
        let y = offset.y
        let a = boundaryA
        let b = boundaryB
        let value = (x * x) / (a * a) + (y * y) / (b * b)
        return value <= 1.0
    }
}

// MARK: - Debug Helpers
#if DEBUG
extension EyeGeometry {
    func debugPrint(state: PupilState) {
        print("""
        🔍 EyeGeometry Debug:
        Center: \(formatPoint(center))
        Boundaries: (A: \(boundaryA), B: \(boundaryB))
        State: \(state.debugDescription)
        """)
    }

    private func formatPoint(_ point: CGPoint) -> String {
        String(format: "(%.2f, %.2f)", point.x, point.y)
    }
}
#endif
