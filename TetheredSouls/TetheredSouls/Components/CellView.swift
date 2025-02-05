import SwiftUI
import Foundation

struct CellView: View {
    let isOccupied: Bool
    let row: Int
    let column: Int
    let selectedBlock: Block?
    let isPreview: Bool
    @State private var showHeart = false
    @StateObject private var touchCoordinator = GridTouchCoordinator.shared
    
    private let colors: [Color] = [
        Theme.primary,
        Theme.secondary,
        Theme.tertiary,
        Theme.quaternary
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .overlay(
                        Rectangle()
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                    .onTapGesture {
                        if !isOccupied && selectedBlock == nil {
                            showHeart = true
                            
                            // Convert cell center to grid coordinates
                            let cellCenter = CGPoint(
                                x: geo.frame(in: .global).midX,
                                y: geo.frame(in: .global).midY
                            )
                            
                            touchCoordinator.touchLocation = cellCenter
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                showHeart = false
                                touchCoordinator.touchLocation = nil
                            }
                        }
                    }
                
                if showHeart {
                    HeartParticle(color: colors.randomElement() ?? Theme.primary)
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        if isPreview {
            return (selectedBlock?.color.color ?? Theme.primary).opacity(0.3)
        }
        return isOccupied ? Theme.primary : Theme.surface
    }
}
