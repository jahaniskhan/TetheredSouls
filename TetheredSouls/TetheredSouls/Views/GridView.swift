import SwiftUI

struct GridView: View {
    @Binding var grid: [[Bool]]
    
    var body: some View {
        VStack(spacing: Theme.Layout.gridSpacing) {
            ForEach(0..<10) { row in
                HStack(spacing: Theme.Layout.gridSpacing) {
                    ForEach(0..<10) { column in
                        CellView(isOccupied: grid[row][column])
                            .animation(.easeOut(duration: 0.2), value: grid[row][column])
                    }
                }
            }
        }
        .padding(Theme.Layout.gridSpacing)
        .background(Theme.stroke)
        .cornerRadius(Theme.Layout.cornerRadius)
    }
}