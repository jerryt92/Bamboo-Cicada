//
//  CicadaToyView.swift
//  Bamboo Cicada
//

import SwiftUI

struct CicadaToyView: View {
    let orbitAngle: Double
    let spinSpeedRatio: Double
    let wingSpread: Double
    let buzzLevel: Double

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let center = CGPoint(x: width * 0.5, y: height * 0.5)
            let cicadaScale: CGFloat = 0.72
            let cicadaBodyHeight: CGFloat = 166
            let cicadaBodyHalfHeight = cicadaBodyHeight * 0.5
            let radius = min(width, height) * 0.36
            let restAngle = Double.pi / 2
            let angle = restAngle + orbitAngle * .pi / 180.0
            let cicadaCenter = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            let bodyRotationRadians = angle - .pi / 2
            let bodyRotation = bodyRotationRadians * 180 / .pi
            let cordAttachment = rotatedPoint(
                center: cicadaCenter,
                local: CGPoint(x: 0, y: -cicadaBodyHalfHeight * cicadaScale),
                radians: bodyRotationRadians
            )

            ZStack {
                cord(from: center, to: cordAttachment)

                bambooStick(height: height, center: center)

                cicadaBody(x: cicadaCenter.x, y: cicadaCenter.y, rotation: bodyRotation, scale: cicadaScale)

                beadPair(x: center.x, y: center.y)
            }
            .transaction { transaction in
                transaction.animation = nil
            }
        }
    }

    private func rotatedPoint(center: CGPoint, local: CGPoint, radians: Double) -> CGPoint {
        CGPoint(
            x: center.x + local.x * cos(radians) - local.y * sin(radians),
            y: center.y + local.x * sin(radians) + local.y * cos(radians)
        )
    }

    private func bambooStick(height: CGFloat, center: CGPoint) -> some View {
        let stickLength = height - center.y + 72
        let stickCenterY = center.y + stickLength * 0.5 - 28

        return Capsule()
            .fill(Color(red: 0.93, green: 0.79, blue: 0.51))
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.32))
                    .frame(width: 6, height: stickLength * 0.82)
                    .offset(x: -5, y: stickLength * 0.08)
            }
            .frame(width: 16, height: stickLength)
            .position(x: center.x, y: stickCenterY)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 5)
    }

    private func cord(from start: CGPoint, to end: CGPoint) -> some View {
        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(Color(red: 0.62, green: 0.58, blue: 0.43), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }

    private func beadPair(x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 32, height: 32)
                Circle()
                    .fill(.red)
                    .frame(width: 32, height: 32)
            }
        }
        .overlay {
            VStack(spacing: 22) {
                Circle().fill(.white.opacity(0.35)).frame(width: 8, height: 8)
                Circle().fill(.white.opacity(0.35)).frame(width: 8, height: 8)
            }
            .offset(x: -5, y: 0)
        }
        .shadow(color: .black.opacity(0.22), radius: 8, y: 6)
        .position(x: x, y: y)
    }

    private func cicadaBody(x: CGFloat, y: CGFloat, rotation: Double, scale: CGFloat) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.91, green: 0.75, blue: 0.43))
                .frame(width: 92, height: 166)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.red)
                        .frame(height: 16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.25), radius: 14, y: 10)

            HStack(spacing: 26) {
                GlossyEye()
                GlossyEye()
            }
            .padding(.top, 48)

            HStack(spacing: 24) {
                Wing(side: .left, spread: wingSpread)
                Wing(side: .right, spread: wingSpread)
            }
            .padding(.top, 72)
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .position(x: x, y: y)
    }
}

private struct GlossyEye: View {
    var body: some View {
        Circle()
            .fill(.black)
            .frame(width: 15, height: 15)
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white.opacity(0.45))
                    .frame(width: 5, height: 5)
                    .offset(x: 3, y: 3)
            }
            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
    }
}

private struct Wing: View {
    enum Side {
        case left
        case right
    }

    let side: Side
    let spread: Double

    var body: some View {
        let direction: Double = side == .left ? 1 : -1

        return LeafWingShape()
            .fill(Color(red: 1.0, green: 0.92, blue: 0.68))
            .overlay {
                LeafWingShape()
                    .stroke(Color.white.opacity(0.55), lineWidth: 2)
            }
            .frame(width: 48, height: 148)
            .rotationEffect(.degrees(direction * (5 + spread * 6)), anchor: .top)
            .offset(x: (side == .left ? -1 : 1) * (-3 + spread * 3), y: 8)
            .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
    }
}

private struct LeafWingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX + rect.width * 0.12, y: rect.minY + rect.height * 0.24),
            control2: CGPoint(x: rect.maxX + rect.width * 0.12, y: rect.minY + rect.height * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX - rect.width * 0.12, y: rect.minY + rect.height * 0.78),
            control2: CGPoint(x: rect.minX - rect.width * 0.12, y: rect.minY + rect.height * 0.24)
        )
        path.closeSubpath()
        return path
    }
}
