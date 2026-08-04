//
//  BambooForestBackground.swift
//  Bamboo Cicada
//

import SwiftUI

struct BambooForestBackground: View {
    let activity: Double

    var body: some View {
        BundlePNGImage(name: "BambooLogoBackground")
            .overlay {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.16),
                        Color.clear,
                        Color(red: 0.95, green: 0.86, blue: 0.38).opacity(0.14)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        .overlay {
            Canvas { context, size in
                for index in 0..<8 {
                    let x = size.width * CGFloat(index) / 14.0
                    var path = Path()
                    path.move(to: CGPoint(x: x - 28, y: -20))
                    path.addLine(to: CGPoint(x: x + CGFloat(activity * 12), y: size.height + 40))
                    context.stroke(
                        path,
                        with: .color(Color(red: 0.05, green: 0.18, blue: 0.12).opacity(index.isMultiple(of: 2) ? 0.14 : 0.08)),
                        lineWidth: index.isMultiple(of: 3) ? 12 : 7
                    )
                }
            }
            .blur(radius: 9)
        }
        .overlay {
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.22)
                ],
                center: .center,
                startRadius: 120,
                endRadius: 620
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea(.all)
    }
}
