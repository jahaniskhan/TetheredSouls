import SwiftUI

struct BlockInventoryCounter: View {
    let count: Int
    let maxCount: Int
    
    var body: some View {
        HStack(spacing: 1) {
            // Main LED-style count
            Text("\(String(format: "%02d", count))")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(count > 0 ? Theme.primary : Theme.textSecondary)
            
            Text("/")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.stroke)
            
            Text("\(maxCount)")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Theme.background)
        .cornerRadius(2)
    }
}

// Preview provider
struct BlockInventoryCounter_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack(spacing: 10) {
                BlockInventoryCounter(count: 20, maxCount: 20)
                BlockInventoryCounter(count: 10, maxCount: 20)
                BlockInventoryCounter(count: 0, maxCount: 20)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}