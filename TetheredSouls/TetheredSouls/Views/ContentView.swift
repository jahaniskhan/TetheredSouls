import SwiftUI


struct ContentView: View {
    private let columns: Int = 10
    private let rows: Int = 10
    
    @State private var grid: [[Bool]] = Array(repeating: Array(repeating: false, count: 10), count: 10)
    @State private var score: Int = 0
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(white: 0.1),
                    Color(white: 0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: Theme.Layout.spacing) {
                VStack(spacing: 8) {
                    Text("TETHERED")
                        .font(Theme.Typography.title)
                        .foregroundColor(Theme.text)
                    
                    Text("SCORE: \(score)")
                        .font(Theme.Typography.score)
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, Theme.Layout.padding)
                        .padding(.vertical, 8)
                        .background(Theme.surface)
                        .cornerRadius(Theme.Layout.cornerRadius)
                }
                .padding(.top, 20)
                
                GridView(grid: $grid)
                    .padding(.horizontal, Theme.Layout.padding)
                
                BlockSelectionView()
                    .padding(.horizontal, Theme.Layout.padding)
                    .padding(.bottom, 20)
            }
            
            if isLoading {
                LoadingView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isLoading = false
                            }
                        }
                    }
            }
        }
    }
}
