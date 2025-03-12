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
                
                // Show an overlay when cell is part of a projection
                if isPreview {
                    Rectangle()
                        .fill(previewColor)
                        .opacity(0.5)
                }
                
                if showHeart {
                    HeartParticle(color: colors.randomElement() ?? Theme.primary)
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        if isOccupied {
            return isPreview ? Color.white.opacity(0.3) : Theme.primary
        } else {
            return Color.white.opacity(0.05)
        }
    }
    
    private var previewColor: Color {
        guard let block = selectedBlock else { return .clear }
        return block.color.color
    }
}
