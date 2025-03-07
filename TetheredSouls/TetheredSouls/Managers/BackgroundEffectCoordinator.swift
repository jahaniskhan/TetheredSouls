import SwiftUI

class BackgroundEffectCoordinator: ObservableObject {
    static let shared = BackgroundEffectCoordinator()
    @Published var activeEffects: [BackgroundEffect] = []
    
    func animateEffects(for block: Block, at position: CGPoint) {
        let newEffect = BackgroundEffect(
            type: .symbol(block.symbol),
            position: position,
            lifespan: 1.5
        )
        activeEffects.append(newEffect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + newEffect.lifespan) {
            self.activeEffects.removeAll { $0.id == newEffect.id }
        }
    }
    
    private func randomScreenPosition() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 0.1...0.9) * UIScreen.main.bounds.width,
            y: CGFloat.random(in: 0.1...0.9) * UIScreen.main.bounds.height
        )
    }
}

struct BackgroundEffect: Identifiable {
    let id = UUID()
    let type: EffectType
    let position: CGPoint
    let lifespan: TimeInterval
    
    enum EffectType {
        case symbol(String)
        case image(String)
    }
} 