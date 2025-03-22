import SwiftUI

struct BlockView: View {
    let block: Block
    
    var body: some View {
        ZStack {
            ForEach(0..<block.shape.count, id: \.self) { row in
                ForEach(0..<block.shape[row].count, id: \.self) { col in
                    if block.shape[row][col] {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(block.color.color)
                            .frame(width: 30, height: 30)
                            .offset(x: CGFloat(col * 30), y: CGFloat(row * 30))
                    }
                }
            }
        }
    }
}