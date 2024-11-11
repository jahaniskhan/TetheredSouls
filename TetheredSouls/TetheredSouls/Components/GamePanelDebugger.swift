//
//  GamePanelDebugger.swift
//  TetheredSouls
//
//  Created by Jahan khan on 11/10/24.
//

import SwiftUI

struct GamePanelDebugger: View {
    @Binding var score: Int
    @Binding var currentStreak: Int
    @State private var isExpanded = false
    @State private var showStateInspector = false
    @State private var selectedSticker: StickerType = .flowerstamp
    
    // Debug controls
    @State private var streakInput: String = "0"
    @State private var scoreInput: String = "0"
    
    var streakTestingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Streak Testing")
                .font(.caption)
            
            Stepper("Streak: \(currentStreak)", 
                value: $currentStreak,
                in: 0...100)
            
            HStack {
                ForEach([5, 10, 15], id: \.self) { value in
                    Button("Hit \(value)") {
                        withAnimation { currentStreak = value }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Debug Header
            HStack {
                Text("🛠 Debug Controls")
                    .font(.system(size: 12, weight: .medium))
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            
            if isExpanded {
                // Streak Controls
                VStack(alignment: .leading, spacing: 8) {
                    Text("Streak Testing")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    HStack {
                        Button("🎯 Hit Streak 5") {
                            withAnimation { currentStreak = 5 }
                        }
                        Button("🎯 Hit Streak 10") {
                            withAnimation { currentStreak = 10 }
                        }
                    }
                    .buttonStyle(DebugButtonStyle())
                    
                    // Score Controls
                    Text("Score Testing")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    HStack {
                        Button("💯 Add 100") {
                            withAnimation { score += 100 }
                        }
                        Button("💥 Reset") {
                            withAnimation {
                                score = 0
                                currentStreak = 0
                            }
                        }
                    }
                    .buttonStyle(DebugButtonStyle())
                }
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(8)
            }
        }
        .padding(8)
        .background(Theme.secondary.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }
}

struct DebugButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? 
                          Theme.primary.opacity(0.2) : 
                          Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}
