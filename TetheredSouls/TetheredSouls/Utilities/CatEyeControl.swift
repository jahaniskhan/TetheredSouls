//
//  CatEyeControl.swift
//  TetheredSouls
//
//  Created for cat eye tracking during block dragging
//

import Foundation
import UIKit  // Add this import for UIScreen

// CRITICAL: Global shared controller for direct cat eye access
public class DirectCatEyeControl {
    public static let shared = DirectCatEyeControl()
    
    // This value will be directly read by CatFeatures
    public var currentEyeFrame: Int = 13
    public var isDragging: Bool = false
    
    // Private initializer for singleton
    private init() {}
    
    // Add a method to control updates in one place
    public func updateForDragging(at position: CGPoint) {
        isDragging = true
        
        // Keep the same sensitive zones
        let screenWidth = UIScreen.main.bounds.width
        let leftZone = screenWidth * 0.4
        let rightZone = screenWidth * 0.6
        
        // FINAL FIX: Swap the frame numbers to invert the looking direction
        if position.x < leftZone {
            currentEyeFrame = 20 // Look RIGHT when dragging on LEFT side
        } else if position.x > rightZone {
            currentEyeFrame = 5 // Look LEFT when dragging on RIGHT side
        } else {
            currentEyeFrame = 2 // Keep center-down the same
        }
    }
    
    public func resetAfterDragging() {
        isDragging = false
        currentEyeFrame = 13 // CENTER
    }
}
