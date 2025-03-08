import SwiftUI
import Foundation

class GridTouchCoordinator: ObservableObject {
    static let shared = GridTouchCoordinator()
    
    @Published var currentPosition: CGPoint?
    @Published var isBlockActive = false
    
    @Published var touchLocation: CGPoint? = nil {
        didSet {
            // Comment out eye tracking debug prints
            // print("GridTouchCoordinator location updated: \(String(describing: touchLocation))")
        }
    }

    private init() {}

    func handleGridTap(location: CGPoint, geometry: GeometryProxy) {
        let adjustedLocation = CGPoint(
            x: location.x - geometry.frame(in: .global).origin.x,
            y: location.y - geometry.frame(in: .global).origin.y
        )
        
        // Use geometry.size for grid calculations
        let cellSize = geometry.size.width / 10
        let column = Int((adjustedLocation.x / cellSize).rounded())
        let row = Int((adjustedLocation.y / cellSize).rounded())
        
        print("🎯 Final grid placement: (\(column), \(row))")
    }
} 
