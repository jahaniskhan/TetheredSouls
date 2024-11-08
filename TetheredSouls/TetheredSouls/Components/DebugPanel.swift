import SwiftUI
import Foundation

struct DebugPanel: View {
    @ObservedObject var state: GridState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with TE-style warning indicator
            HStack {
                Circle()
                    .fill(Theme.quaternary)
                    .frame(width: 6, height: 6)
                Text("DEBUG MODE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.bottom, 4)
            
            // Data Grid
            VStack(alignment: .leading, spacing: 6) {
                // Grid origin data
                dataRow(label: "GRID", 
                       value: String(format: "%04.1f/%04.1f", 
                       state.calculateGridOrigin().x,
                       state.calculateGridOrigin().y))
                
                // Relative position
                let relativePos = calculateRelativePosition()
                dataRow(label: "REL", 
                       value: String(format: "%04.1f/%04.1f",
                       relativePos.x,
                       relativePos.y))
                
                // Coordinates Section
                dataRow(label: "XY", 
                       value: String(format: "%04.1f/%04.1f", 
                       state.debugInfo.touchPosition.x, 
                       state.debugInfo.touchPosition.y))
                
                dataRow(label: "POS", 
                       value: String(format: "R%02d/C%02d",
                       state.debugInfo.gridPosition.row,
                       state.debugInfo.gridPosition.column))
                
                dataRow(label: "OFF", 
                       value: String(format: "%04.1f/%04.1f",
                       state.debugInfo.blockOffset.x,
                       state.debugInfo.blockOffset.y))
                
                // Status Indicators
                HStack(spacing: 12) {
                    statusIndicator(label: "VALID", 
                                  isActive: state.debugInfo.isValidPlacement,
                                  color: Theme.tertiary)
                    
                    if !state.debugInfo.placementError.isEmpty {
                        statusIndicator(label: "ERR", 
                                     isActive: true, 
                                     color: Theme.quaternary)
                    }
                }
            }
            
            // Matrix Display with TE colors
            VStack(alignment: .leading, spacing: 2) {
                Text("MATRIX")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.top, 4)
                
                ForEach(state.debugInfo.blockShape.indices, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(state.debugInfo.blockShape[row].indices, id: \.self) { col in
                            Rectangle()
                                .fill(state.debugInfo.blockShape[row][col] ? 
                                      Theme.secondary : Theme.stroke)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .cornerRadius(6)
    }
    
    private func dataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 30, alignment: .leading)
            
            Text(value)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.primary)
        }
    }
    
    private func statusIndicator(label: String, isActive: Bool, color: Color = Theme.primary) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? color : Theme.stroke)
                .frame(width: 6, height: 6)
            
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(isActive ? color : Theme.textSecondary)
        }
    }
    
    private func calculateRelativePosition() -> CGPoint {
        let origin = state.calculateGridOrigin()
        return CGPoint(
            x: state.debugInfo.touchPosition.x - origin.x,
            y: state.debugInfo.touchPosition.y - origin.y
        )
    }
}
