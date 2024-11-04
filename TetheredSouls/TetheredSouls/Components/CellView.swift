import SwiftUI

struct CellView: View {
    let isOccupied: Bool
    @State private var isHovered = false
    
    var body: some View {
        Rectangle()
            .fill(isOccupied ? Theme.primary : Theme.surface)
            .overlay(
                Rectangle()
                    .stroke(isHovered ? Theme.primary : Theme.stroke, lineWidth: 1)
            )
            .aspectRatio(1, contentMode: .fit)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}