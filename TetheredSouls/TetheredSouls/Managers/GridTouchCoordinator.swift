import SwiftUI
import Foundation

class GridTouchCoordinator: ObservableObject {
    static let shared = GridTouchCoordinator()
    
    @Published var currentPosition: CGPoint?
    @Published var isBlockActive = false
    
    @Published var touchLocation: CGPoint? = nil {
        didSet {
            print("GridTouchCoordinator location updated: \(String(describing: touchLocation))")
        }
    }

    private init() {}

    func handleGridTap(location: CGPoint, geometry: GeometryProxy) {
        let cellSize = geometry.size.width / 10
        let column = Int((location.x / cellSize).rounded(.toNearestOrEven))
        let row = Int((location.y / cellSize).rounded(.toNearestOrEven))
        
        // Immediate update
        DispatchQueue.main.async {
            self.currentPosition = CGPoint(x: column, y: row)
            self.isBlockActive = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.isBlockActive = false
        }
    }
} 
