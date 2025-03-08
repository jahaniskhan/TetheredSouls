import SwiftUI

struct HeartParticle: View {
    let color: Color
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "heart.fill")
            .foregroundColor(color)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1
                    rotation = Double.random(in: -30...30)
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    opacity = 0
                    scale = 1.5
                }
            }
    }
}
