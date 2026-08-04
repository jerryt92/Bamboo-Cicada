//
//  GestureProtectedView.swift
//  Bamboo Cicada
//

import SwiftUI
import UIKit

struct GestureProtectedView<Content: View>: UIViewControllerRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> GestureDeferringHostingController<AnyView> {
        GestureDeferringHostingController(rootView: fullScreenContent)
    }

    func updateUIViewController(_ uiViewController: GestureDeferringHostingController<AnyView>, context: Context) {
        uiViewController.rootView = fullScreenContent
        uiViewController.setNeedsUpdateOfHomeIndicatorAutoHidden()
        uiViewController.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    private var fullScreenContent: AnyView {
        AnyView(
            content
                .background(Color(red: 0.08, green: 0.25, blue: 0.17))
                .ignoresSafeArea(.all)
        )
    }
}

final class GestureDeferringHostingController<Content: View>: UIHostingController<Content> {
    private var appliedSafeAreaCompensation: UIEdgeInsets = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        modalPresentationCapturesStatusBarAppearance = true
        applyFullscreenBackground()
        neutralizeSafeArea()
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyFullscreenBackground()
        neutralizeSafeArea()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyFullscreenBackground()
        neutralizeSafeArea()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        neutralizeSafeArea()
    }

    private func applyFullscreenBackground() {
        let backgroundColor = UIColor(red: 0.08, green: 0.25, blue: 0.17, alpha: 1)
        view.backgroundColor = backgroundColor
        view.isOpaque = true
        view.clipsToBounds = false
        view.insetsLayoutMarginsFromSafeArea = false
        view.layoutMargins = .zero
        view.superview?.backgroundColor = backgroundColor
        view.window?.backgroundColor = backgroundColor
    }

    private func neutralizeSafeArea() {
        let insets = view.safeAreaInsets
        let compensation = UIEdgeInsets(
            top: -insets.top,
            left: -insets.left,
            bottom: -insets.bottom,
            right: -insets.right
        )
        guard compensation != appliedSafeAreaCompensation else { return }
        appliedSafeAreaCompensation = compensation
        additionalSafeAreaInsets = compensation
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        .bottom
    }

    override var prefersStatusBarHidden: Bool {
        true
    }
}
