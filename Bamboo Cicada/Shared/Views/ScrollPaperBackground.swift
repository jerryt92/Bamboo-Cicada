//
//  ScrollPaperBackground.swift
//  Bamboo Cicada
//

import SwiftUI
import UIKit

struct ScrollPaperBackground: View {
    private static let cachedScrollImage: UIImage? = {
        guard let url = Bundle.main.url(forResource: "ChineseScrollBackground", withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }()

    var body: some View {
        GeometryReader { proxy in
            scrollImage
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.89, blue: 0.66).opacity(0.12),
                            Color.clear,
                            Color(red: 0.18, green: 0.09, blue: 0.03).opacity(0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay {
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.93, blue: 0.74).opacity(0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 420
                    )
                }
        }
    }

    @ViewBuilder
    private var scrollImage: some View {
        if let image = Self.cachedScrollImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            BundlePNGImage(name: "ChineseScrollBackground")
        }
    }
}
