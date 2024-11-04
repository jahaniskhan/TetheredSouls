import SwiftUI

struct BlockSelectionView: View {
    var body: some View {
        VStack {
            Text("AVAILABLE BLOCKS")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 20) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                        .fill(Theme.primary.opacity(0.2))
                        .frame(height: 60)
                }
            }
        }
        .padding(Theme.Layout.padding)
        .background(Theme.surface)
        .cornerRadius(Theme.Layout.cornerRadius)
    }
}

#Preview {
    BlockSelectionView()
        .padding()
        .background(Theme.background)
}