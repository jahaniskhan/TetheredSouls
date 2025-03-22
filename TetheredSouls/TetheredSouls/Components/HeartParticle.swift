import SwiftUI

struct HeartParticle: View {
    let color: Color
    let id: UUID
    
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var isAnimating = false
    
    // Random direction for more natural movement
    private let randomDirection: CGFloat = CGFloat.random(in: -5...5)
    
    // Random duration for varied animation timing - reduced from 0.6...1.0 to 0.4...0.7
    private let animationDuration: Double = Double.random(in: 0.4...0.7)
    
    // Random size for visual variety
    private let randomSize: CGFloat = CGFloat.random(in: 0.8...1.2)
    
    var body: some View {
        ZStack {
            // Add a glow effect behind the heart
            Image(systemName: "heart.fill")
                .foregroundColor(color.opacity(0.7))
                .blur(radius: 3)
                .scaleEffect(isAnimating ? 1.8 * randomSize : 0)
                .opacity(isAnimating ? 0.9 : 0)
            
            // Main heart
            Image(systemName: "heart.fill")
                .foregroundColor(color)
                .shadow(color: color.opacity(0.9), radius: 3, x: 0, y: 0)
                .scaleEffect(isAnimating ? 1.5 * randomSize : 0)
        }
        .opacity(isAnimating ? 0 : 1)
        .rotationEffect(.degrees(isAnimating ? Double.random(in: -45...45) : 0))
        .offset(x: xOffset, y: yOffset)
        .onAppear {
            // Small delay for staggered effect if multiple hearts appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                // Main animation - speed increased from 1.0 to 1.2
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).speed(1.2)) {
                    scale = 1.0
                    rotation = Double.random(in: -30...30)
                }
                
                // Float upward animation with slight random horizontal movement
                // Increased speed (shorter duration) and higher upward movement
                withAnimation(.easeOut(duration: animationDuration)) {
                    isAnimating = true
                    yOffset = -100 - CGFloat.random(in: 0...30) // Float upward faster (from -90 to -100)
                    xOffset = randomDirection * 15 // More horizontal drift for quicker visual exit
                }
            }
        }
        .id(id)
    }
}

// Preview
struct HeartParticle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.1).edgesIgnoringSafeArea(.all)
            
            // Show multiple hearts for preview
            ForEach(0..<5, id: \.self) { i in
                HeartParticle(
                    color: [.pink, .red, .purple, .orange, .blue][i % 5],
                    id: UUID()
                )
                .offset(
                    x: CGFloat.random(in: -100...100),
                    y: CGFloat.random(in: -50...50)
                )
            }
        }
    }
}
