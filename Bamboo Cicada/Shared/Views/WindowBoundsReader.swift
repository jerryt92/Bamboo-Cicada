//
//  WindowBoundsReader.swift
//  Bamboo Cicada
//

import SwiftUI
import UIKit

/// 读取所在窗口尺寸，并在布局变化（折叠/展开、旋转）时回传窗口场景。
struct WindowBoundsReader: UIViewRepresentable {
    @Binding var size: CGSize
    var onSceneLayout: ((UIWindowScene) -> Void)? = nil

    func makeUIView(context: Context) -> BoundsView {
        let view = BoundsView()
        bindCallbacks(to: view)
        return view
    }

    func updateUIView(_ uiView: BoundsView, context: Context) {
        bindCallbacks(to: uiView)
        uiView.reportBounds()
    }

    /// 绑定尺寸与场景回调。
    private func bindCallbacks(to view: BoundsView) {
        view.onBoundsChange = { newSize in
            if size != newSize {
                size = newSize
            }
        }
        view.onSceneLayout = onSceneLayout
    }

    /// 监听窗口挂载与布局的承载视图。
    final class BoundsView: UIView {
        var onBoundsChange: ((CGSize) -> Void)?
        var onSceneLayout: ((UIWindowScene) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            reportBounds()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            reportBounds()
        }

        /// 异步回传窗口尺寸与场景，避免在视图更新过程中修改状态。
        func reportBounds() {
            guard let window else { return }
            let newSize = window.bounds.size
            let scene = window.windowScene
            DispatchQueue.main.async { [weak self] in
                self?.onBoundsChange?(newSize)
                if let scene {
                    self?.onSceneLayout?(scene)
                }
            }
        }
    }
}
