//
//  splashView.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Icon with animation
                Image("Icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .shadow.opacity(0.3), radius: 20, x: 0, y: 10)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .animation(
                        .spring(response: 1.0, dampingFraction: 0.6, blendDuration: 0),
                        value: scale
                    )
                    .animation(
                        .easeInOut(duration: 0.8),
                        value: opacity
                    )
                
                // Optional: App name or loading text
                Text("Swift Boilerplate")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                    .opacity(opacity)
                    .animation(
                        .easeInOut(duration: 0.8).delay(0.3),
                        value: opacity
                    )
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryMain))
                    .scaleEffect(1.2)
                    .opacity(opacity)
                    .animation(
                        .easeInOut(duration: 0.8).delay(0.6),
                        value: opacity
                    )
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start the entrance animation
        withAnimation {
            scale = 1.0
            opacity = 1.0
            isAnimating = true
        }
        
        // Add a subtle pulse animation after entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scale = 1.05
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashView()
}

