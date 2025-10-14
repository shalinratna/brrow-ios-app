//
//  ConfettiView.swift
//  Brrow
//
//  Continuous confetti animation for purchase success
//

import SwiftUI
import Darwin

struct ConfettiView: View {
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiParticles) { particle in
                    ConfettiShape(shape: particle.shape)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .rotationEffect(particle.rotation)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                startConfettiContinuously(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
        .allowsHitTesting(false)
    }

    private func startConfettiContinuously(in size: CGSize) {
        // Create initial burst
        createBurst(count: 50, in: size)

        // Continuously spawn new confetti every 0.3 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            createBurst(count: 8, in: size)
        }
    }

    private func createBurst(count: Int, in size: CGSize) {
        for _ in 0..<count {
            let particle = ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20, // Start above screen
                size: CGFloat.random(in: 8...16),
                color: randomConfettiColor(),
                shape: ConfettiShapeType.allCases.randomElement() ?? .circle,
                velocity: CGFloat.random(in: 2...4),
                rotation: Angle(degrees: Double.random(in: 0...360)),
                angularVelocity: Double.random(in: -180...180)
            )

            confettiParticles.append(particle)

            // Animate the particle falling
            animateParticle(particle, in: size)
        }
    }

    private func animateParticle(_ particle: ConfettiParticle, in size: CGSize) {
        // Random drift left/right as it falls
        let drift = CGFloat.random(in: -50...50)
        let endX = particle.x + drift
        let endY = size.height + 50 // Fall off bottom of screen

        withAnimation(.linear(duration: Double.random(in: 3...5))) {
            if let index = confettiParticles.firstIndex(where: { $0.id == particle.id }) {
                confettiParticles[index].x = endX
                confettiParticles[index].y = endY
                confettiParticles[index].rotation.degrees += particle.angularVelocity * 5
                confettiParticles[index].opacity = 0
            }
        }

        // Remove particle after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            confettiParticles.removeAll { $0.id == particle.id }
        }
    }

    private func randomConfettiColor() -> Color {
        let colors: [Color] = [
            .pink, .purple, .blue, .cyan, .teal, .mint,
            .green, .yellow, .orange, .red,
            Color(hex: "10B981") ?? .green,
            Color(hex: "06B6D4") ?? .cyan,
            Color(hex: "F59E0B") ?? .orange,
            Color(hex: "EC4899") ?? .pink,
            Color(hex: "8B5CF6") ?? .purple
        ]
        return colors.randomElement() ?? .blue
    }
}

// Confetti particle model
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var shape: ConfettiShapeType
    var velocity: CGFloat
    var rotation: Angle
    var angularVelocity: Double
    var opacity: Double = 1.0
}

// Different confetti shapes
enum ConfettiShapeType: CaseIterable {
    case circle
    case square
    case triangle
    case star
}

// Shape renderer
struct ConfettiShape: Shape {
    let shape: ConfettiShapeType

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .circle:
            return Circle().path(in: rect)
        case .square:
            return Rectangle().path(in: rect)
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path
        case .star:
            return starPath(in: rect)
        }
    }

    private func starPath(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4

        for i in 0..<5 {
            let angle = (Double(i) * 72 - 90) * .pi / 180
            let point = CGPoint(
                x: center.x + CGFloat(Darwin.cos(angle)) * radius,
                y: center.y + CGFloat(Darwin.sin(angle)) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }

            let innerAngle = (Double(i) * 72 + 36 - 90) * .pi / 180
            let innerPoint = CGPoint(
                x: center.x + CGFloat(Darwin.cos(innerAngle)) * innerRadius,
                y: center.y + CGFloat(Darwin.sin(innerAngle)) * innerRadius
            )
            path.addLine(to: innerPoint)
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color.black
        ConfettiView()
    }
    .ignoresSafeArea()
}
