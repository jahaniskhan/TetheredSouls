//
//  GamePanelDebugger.swift
//  TetheredSouls
//
//  Created by Jahan khan on 11/10/24.
//

import SwiftUI

struct EyeDebugData {
    let eyeCenter: CGPoint    // E(x,y) from math model
    let touchPoint: CGPoint   // P(x,y) from math model
    let boundaryA: CGFloat    // Horizontal radius
    let boundaryB: CGFloat    // Vertical radius
    
    var angle: Double {
        // θ = arctan((y-Ey)/(x-Ex))
        let deltaY = touchPoint.y - eyeCenter.y
        let deltaX = touchPoint.x - eyeCenter.x
        return atan2(deltaY, deltaX) * 180 / Double.pi
    }
    
    var ellipticalDistance: Double {
        // (x²/a²) + (y²/b²) = 1
        let normalizedX = pow((touchPoint.x - eyeCenter.x) / boundaryA, 2)
        let normalizedY = pow((touchPoint.y - eyeCenter.y) / boundaryB, 2)
        return sqrt(normalizedX + normalizedY)
    }
    
    var formattedString: String {
        """
        Eye Center: (x: \(String(format: "%.2f", eyeCenter.x)), y: \(String(format: "%.2f", eyeCenter.y)))
        Touch Point: (x: \(String(format: "%.2f", touchPoint.x)), y: \(String(format: "%.2f", touchPoint.y)))
        Angle: \(String(format: "%.1f°", angle))
        Boundary Distance: \(String(format: "%.2f", ellipticalDistance))
        """
    }
}

struct GamePanelDebugger: View {
    @Binding var eyePosition: CGPoint
    
    private var debugData: EyeDebugData {
        EyeDebugData(position: eyePosition)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Eye Position")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            
            Text(debugData.formattedString)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(8)
    }
}
