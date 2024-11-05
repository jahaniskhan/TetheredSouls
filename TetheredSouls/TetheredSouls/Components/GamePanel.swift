import SwiftUI

struct GamePanel: View {
    let score: Int
    let currentStreak: Int
    let maxStreak: Int = 3
    let progressValue: Double = 0.4
    @State private var systemTime = Date()
    @State private var systemStatus = "IDLE"
    @State private var cpuLoad = [0.2, 0.4, 0.6, 0.3, 0.5]
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 16) {
            // Left status matrix
            VStack(spacing: 4) {
                // Signal strength indicators
                HStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        Rectangle()
                            .fill(Theme.quaternary.opacity(i == 0 ? 1 : 0.3))
                            .frame(width: 3, height: 6 - Double(i))
                    }
                }
                Circle()
                    .fill(Theme.tertiary.opacity(0.3))
                    .frame(width: 6, height: 6)
                
                // Memory status
                Text("64K")
                    .font(.system(size: 4, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
            
            // Digital displays
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(String(format: "%03.1f", Double(score)/10))")
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.text)
                    
                    // CPU usage display
                    VStack(spacing: 1) {
                        ForEach(cpuLoad, id: \.self) { load in
                            Rectangle()
                                .fill(Theme.quaternary.opacity(load))
                                .frame(width: 8, height: 1)
                        }
                    }
                }
                
                HStack(spacing: 6) {
                    // Hearts
                    ForEach(0..<3) { i in
                        Image(systemName: i < currentStreak ? "heart.fill" : "heart")
                            .foregroundColor(i < currentStreak ? Theme.quaternary : Theme.textSecondary)
                            .font(.system(size: 10))
                    }
                    
                    // System info
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SYS.01")
                            .font(.system(size: 6, weight: .medium, design: .monospaced))
                        Text(systemTime.formatted(.dateTime.hour().minute()))
                            .font(.system(size: 6, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            
            Spacer()
            
            // Center status indicators
            VStack(spacing: 4) {
                // Progress indicators
                VStack(spacing: 2) {
                    // Bee progress
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Theme.surface)
                            .frame(width: 40, height: 2)
                        
                        Rectangle()
                            .fill(Theme.quaternary)
                            .frame(width: 40 * progressValue, height: 2)
                        
                        Image(systemName: "ant.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Theme.quaternary)
                            .offset(x: 40 * progressValue - 4, y: -6)
                    }
                    
                    // System status
                    Text(systemStatus)
                        .font(.system(size: 4, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.quaternary)
                }
                
                // Signal matrix
                HStack(spacing: 2) {
                    ForEach(0..<4) { i in
                        Circle()
                            .fill(Theme.primary.opacity(i < 2 ? 1 : 0.3))
                            .frame(width: 2, height: 2)
                    }
                }
            }
            
            // Right indicators
            HStack(spacing: 8) {
                // Status matrix
                VStack(spacing: 3) {
                    ForEach(0..<3) { i in
                        Rectangle()
                            .fill(Theme.primary.opacity(i == 0 ? 1 : 0.3))
                            .frame(width: 10, height: 2)
                    }
                }
                
                // Level and performance
                VStack(spacing: 2) {
                    Text("L1")
                        .font(.system(size: 6, weight: .medium, design: .monospaced))
                    Text("\(Int(progressValue * 100))%")
                        .font(.system(size: 4, weight: .medium, design: .monospaced))
                }
                .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.background)
        .cornerRadius(2)
        .overlay(Rectangle().stroke(Theme.stroke, lineWidth: 1))
        .onReceive(timer) { time in
            systemTime = time
            systemStatus = ["IDLE", "PROC", "SYNC"][Int.random(in: 0...2)]
            // Simulate CPU load changes
            cpuLoad = cpuLoad.map { min(1, max(0, $0 + Double.random(in: -0.2...0.2))) }
        }
    }
}

#Preview {
    GamePanel(score: 193, currentStreak: 2)
        .frame(width: 280)
        .padding()
        .background(Color.black)
}