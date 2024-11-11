//
//  NotionFace.swift
//  TetheredSouls
//
//  Created by Jahan khan on 11/9/24.
//

import SwiftUI

struct NotionFace: View {
    @State private var phase = 0.0
    @State private var isWatching = false
    @State private var lastTapLocation: CGPoint?
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // White circle background
            Circle()
                .fill(.white)
                .frame(width: 40, height: 40)
                .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
            
            // Cat face that reacts to interactions
            CatFeatures(phase: phase, isWatching: isWatching)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isWatching = true
                    lastTapLocation = value.location
                }
                .onEnded { _ in
                    // Keep watching briefly after touch ends
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isWatching = false
                            lastTapLocation = nil
                        }
                    }
                }
        )
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.05)) {
                phase += 0.05
            }
        }
    }
}

// Preview
#Preview {
    NotionFace()
        .padding()
        .background(Color.gray.opacity(0.2))
}
