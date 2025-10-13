//
//  ConfettiView.swift
//  Brrow
//
//  Nike SNKRS-style celebration confetti animation
//

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiShape()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(
                            x: particle.x,
                            y: isAnimating ? geometry.size.height + 50 : particle.y
                        )
                        .opacity(isAnimating ? 0 : 1)
                }
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }

    private func generateParticles() {
        particles = (0..<200).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: -400...(-50)),
                size: CGFloat.random(in: 6...16),
                rotation: Double.random(in: 0...360),
                color: [
                    // Vibrant greens
                    Theme.Colors.primary,
                    Color(hex: "10B981") ?? .green,
                    Color(hex: "34D399") ?? .green,
                    Color(hex: "6EE7B7") ?? .green,
                    Color(hex: "A7F3D0") ?? .green,
                    // Complementary colors
                    Color(hex: "06B6D4") ?? .cyan,
                    Color(hex: "14B8A6") ?? .teal,
                    Theme.Colors.accent,
                    Color.yellow,
                    Color(hex: "FCD34D") ?? .yellow,
                    // Accent colors
                    Color.pink,
                    Theme.Colors.accentOrange,
                    Color.white.opacity(0.9)
                ].randomElement() ?? Theme.Colors.primary
            )
        }
    }

    private func startAnimation() {
        withAnimation(.easeIn(duration: 3.0)) {
            isAnimating = true
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let rotation: Double
    let color: Color
}

struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Create various confetti shapes
        let shapeType = Int.random(in: 0...4)

        switch shapeType {
        case 0:
            // Circle
            path.addEllipse(in: rect)
        case 1:
            // Square
            path.addRect(rect)
        case 2:
            // Triangle
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        case 3:
            // Star (5-pointed)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let outerRadius = min(rect.width, rect.height) / 2
            let innerRadius = outerRadius * 0.4
            let angleIncrement = Double.pi * 2 / 10

            for i in 0..<10 {
                let angle = angleIncrement * Double(i) - Double.pi / 2
                let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
                let x = center.x + CGFloat(cos(angle)) * radius
                let y = center.y + CGFloat(sin(angle)) * radius

                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()
        case 4:
            // Diamond
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
        default:
            path.addEllipse(in: rect)
        }

        return path
    }
}

// Preview
struct ConfettiView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            ConfettiView()
        }
    }
}
