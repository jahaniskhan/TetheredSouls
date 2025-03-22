//
//  EyeGeometry.swift
//  TetheredSouls
//
//  Created by Jahan Khan on 11/9/24
//  BRAND NEW
//

import SwiftUI
import Foundation

struct EyeGeometry {
    // MARK: - Configuration
    struct Configuration {
        // The fractions for each eye's center:
        static let leftEyeCenter  = CGPoint(x: 0.35, y: 0.5)
        static let rightEyeCenter = CGPoint(x: 0.65, y: 0.5)

        // Ellipse half-width/half-height
        static let boundaryA: CGFloat = 12.0
        static let boundaryB: CGFloat = 8.0
    }

    enum EyeRole {
        case master
        case slave
    }

    // MARK: - Pupil State
    struct PupilState: Equatable {
        let offset: CGPoint    // offset from the eye center
        let angle: Double      // the angle used for positioning
        let rotation: Double   // tangent-based orientation
    }

    // MARK: - Properties
    let role: EyeRole
    let center: CGPoint
    let boundaryA: CGFloat
    let boundaryB: CGFloat

    init(role: EyeRole, center: CGPoint, boundaryA: CGFloat, boundaryB: CGFloat) {
        self.role      = role
        self.center    = center
        self.boundaryA = boundaryA
        self.boundaryB = boundaryB
    }

    // MARK: - Build a pupil state pinned to ellipse boundary
    func pupilState(at angle: Double) -> PupilState {
        // Normalize angle to [-π, π]
        var normalizedAngle = angle
        while normalizedAngle > .pi { normalizedAngle -= 2 * .pi }
        while normalizedAngle < -.pi { normalizedAngle += 2 * .pi }
        
        // Get exact point on ellipse boundary
        let px = boundaryA * cos(normalizedAngle)
        let py = boundaryB * sin(normalizedAngle)
        let offset = CGPoint(x: px, y: py)
        
        // Get tangent angle (derivative of ellipse)
        // dx/dt = -a*sin(t), dy/dt = b*cos(t)
        let dx = -boundaryA * sin(normalizedAngle)
        let dy = boundaryB * cos(normalizedAngle)
        let tangentAngle = atan2(dy, dx)
        
        return PupilState(
            offset: offset,
            angle: normalizedAngle,
            rotation: tangentAngle + .pi  // Point inward
        )
    }
    
    // MARK: - Helper Methods
    func isOffsetWithinEllipse(_ offset: CGPoint) -> Bool {
        // eq. value = x²/a² + y²/b² <= 1
        let x = offset.x
        let y = offset.y
        let eqVal = (x*x)/(boundaryA*boundaryA) + (y*y)/(boundaryB*boundaryB)
        return eqVal <= 1.0
    }

    static func calculateFrameNumber(
        touchPoint: CGPoint,
        eyeCenter: CGPoint,
        totalFrames: Int,
        defaultFrame: Int = 13
    ) -> Int {
        #if DEBUG
        print("=== Eye Tracking Debug ===")
        print("Touch point: \(touchPoint)")
        print("Eye center: \(eyeCenter)")
        #endif
        
        // Convert touch to relative coordinates from eye center
        let dx = touchPoint.x - eyeCenter.x
        let dy = touchPoint.y - eyeCenter.y
        
        // Calculate angle from eye center to touch point
        var angle = atan2(dy, dx)
        
        // Normalize angle to 0-2π range, starting from 12 o'clock position
        // Adjust to make 0 at 12 o'clock and positive clockwise
        angle = -angle + .pi/2
        if angle < 0 {
            angle += 2 * .pi
        }
        
        // Map angle to frame number (0-24)
        // Adjust the mapping to ensure full range of motion
        let frameNumber = Int((angle / (2 * .pi)) * Double(totalFrames))
        
        // Ensure we can reach all frames (0-24)
        let clampedFrame = min(max(frameNumber, 0), totalFrames - 1)
        
        #if DEBUG
        print("Original angle (radians): \(angle)")
        print("Raw frame number: \(frameNumber)")
        print("Final frame: \(clampedFrame)")
        print("=====================")
        #endif
        
        return clampedFrame
    }
    
    // New method specifically for block dragging with downward-biased eye positions
    static func calculateBlockSpectatingFrame(
        blockPosition: CGPoint,
        eyeCenter: CGPoint,
        screenHeight: CGFloat,
        totalFrames: Int,
        defaultFrame: Int = 13
    ) -> Int {
        // Instead of using complex angle calculations, we'll use a simpler grid-based approach
        // Divide the screen into three regions: left, center, and right
        
        // First determine horizontal direction (left, center, right)
        let screenWidth = UIScreen.main.bounds.width
        let screenLeftZone = screenWidth * 0.4
        let screenRightZone = screenWidth * 0.6
        
        var targetFrame: Int
        
        if blockPosition.x < screenLeftZone {
            // Looking DOWN-RIGHT when on left side
            targetFrame = 20
            
            #if DEBUG
            print("👀 Cat EYE FRAME: \(targetFrame) (DOWN-RIGHT) for block at \(Int(blockPosition.x)), \(Int(blockPosition.y))")
            #endif
        } else if blockPosition.x > screenRightZone {
            // Looking DOWN-LEFT when on right side
            targetFrame = 5
            
            #if DEBUG
            print("👀 Cat EYE FRAME: \(targetFrame) (DOWN-LEFT) for block at \(Int(blockPosition.x)), \(Int(blockPosition.y))")
            #endif
        } else {
            // Keep center-down the same
            targetFrame = 2
            
            #if DEBUG
            print("👀 Cat EYE FRAME: \(targetFrame) (DOWN-CENTER) for block at \(Int(blockPosition.x)), \(Int(blockPosition.y))")
            #endif
        }
        
        return targetFrame
    }
    
    static func debugTouchInfo(location: CGPoint?, parentSize: CGSize) {
        guard let touch = location else { return }
        #if DEBUG
        print("=== Touch Debug ===")
        print("Raw touch location: \(touch)")
        print("Parent size: \(parentSize)")
        print("==================")
        #endif
    }
}
