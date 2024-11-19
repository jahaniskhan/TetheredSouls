//
//  TetheredSoulsUITests.swift
//  TetheredSoulsUITests
//
//  Created by Jahan khan on 11/3/24.
//

import XCTest

final class CatFeaturesUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Always launch in portrait mode for consistent coordinates
        let app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]  // Optional: Add if you want to detect UI testing in app
        app.launch()
    }
    
    @MainActor
    func testEyeMovement() throws {
        let app = XCUIApplication()
        
        // Access your cat view using accessibility identifier
        let catView = app.otherElements["CatView"]
        XCTAssertTrue(catView.exists, "Cat view should be visible")
        
        // UI tests must launch the application that they test.
        // Test center position
        let centerPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        centerPoint.tap()
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Test eye tracking at different points
        let testPoints: [(CGVector, String)] = [
            (CGVector(dx: 0.2, dy: 0.2), "top-left"),
            (CGVector(dx: 0.8, dy: 0.2), "top-right"),
            (CGVector(dx: 0.2, dy: 0.8), "bottom-left"),
            (CGVector(dx: 0.8, dy: 0.8), "bottom-right")
        ]
        
        for (vector, description) in testPoints {
            let point = app.coordinate(withNormalizedOffset: vector)
            point.tap()
            
            // Verify debug panel updates
            let debugPanel = app.staticTexts["EyeDebugPanel"]
            XCTAssertTrue(debugPanel.exists, "Debug panel should be visible after tapping \(description)")
            
            // Give time for animation
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    @MainActor
    func testMoodTransitions() throws {
        let app = XCUIApplication()
        
        // Test different moods if you have UI controls for them
        let moods = ["normal", "happy", "sad", "sleepy", "watching"]
        
        for mood in moods {
            let moodButton = app.buttons["\(mood)MoodButton"]
            if moodButton.exists {
                moodButton.tap()
                
                // Verify mouth asset changed
                let mouthImage = app.images["\(mood)Mouth"]
                XCTAssertTrue(mouthImage.exists, "Mouth should change for \(mood) mood")
                
                // Give time for animation
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    @MainActor
    func testEyeTrackingPerformance() throws {
        let app = XCUIApplication()
        
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            // Test a smooth eye movement
            let startPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
            let endPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
            
            startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        }
    }
    
    @MainActor
    func testAccessibility() throws {
        let app = XCUIApplication()
        
        // Test voice over labels
        let catView = app.otherElements["CatView"]
        XCTAssertTrue(catView.exists)
        XCTAssertNotNil(catView.label, "Cat view should have accessibility label")
        
        // Test debug panel accessibility
        let debugPanel = app.staticTexts["EyeDebugPanel"]
        XCTAssertTrue(debugPanel.exists)
        XCTAssertNotNil(debugPanel.label, "Debug panel should have accessibility label")
    }
}
