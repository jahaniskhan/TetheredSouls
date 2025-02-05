import SwiftUI

struct BlockView: View {
    let block: Block
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(block.color.color)
                .frame(width: 30, height: 30)
            
            Text("■")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
} 