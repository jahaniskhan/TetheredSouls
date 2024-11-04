import SwiftUI

struct LoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Theme.primary, lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .rotationEffect(Angle(degrees: rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                
                Text("LOADING")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.text)
            }
        }
    }
}

#Preview {
    LoadingView()
}