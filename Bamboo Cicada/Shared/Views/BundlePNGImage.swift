//
//  BundlePNGImage.swift
//  Bamboo Cicada
//

import SwiftUI
import UIKit

struct BundlePNGImage: View {
    let name: String

    var body: some View {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.25, blue: 0.17),
                    Color(red: 0.46, green: 0.67, blue: 0.42),
                    Color(red: 0.92, green: 0.82, blue: 0.54)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
