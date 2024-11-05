import SwiftUI
import Foundation

struct CellView: View {
    let isOccupied: Bool
    let row: Int
    let column: Int
    let selectedBlock: Block?
    let isPreview: Bool
    @State private var showHeart = false

    private let colors: [Color] = [
        Theme.primary,
        Theme.secondary,
        Theme.tertiary,
        Theme.quaternary
    ]
    
    var body: some View {
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            showHeart = false
                        }
                    }
                }
            
            if showHeart {
                HeartParticle(color: colors.randomElement() ?? Theme.primary)
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
