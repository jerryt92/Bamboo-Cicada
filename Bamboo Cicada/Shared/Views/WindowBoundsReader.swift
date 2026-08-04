//
//  WindowBoundsReader.swift
//  Bamboo Cicada
//

import SwiftUI
import UIKit

struct WindowBoundsReader: UIViewRepresentable {
    @Binding var size: CGSize

    func makeUIView(context: Context) -> BoundsView {
        let view = BoundsView()
        view.onBoundsChange = { newSize in
            if size != newSize {
                size = newSize
            }
        }
        return view
    }

    func updateUIView(_ uiView: BoundsView, context: Context) {
        uiView.onBoundsChange = { newSize in
            if size != newSize {
                size = newSize
            }
        }
        uiView.reportBounds()
    }

    final class BoundsView: UIView {
        var onBoundsChange: ((CGSize) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            reportBounds()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            reportBounds()
        }

        func reportBounds() {
            guard let window else { return }
            let newSize = window.bounds.size
            DispatchQueue.main.async { [weak self] in
                self?.onBoundsChange?(newSize)
            }
        }
    }
}
