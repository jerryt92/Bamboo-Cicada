//
//  AppOrientationLock.swift
//  Bamboo Cicada
//

import UIKit

/// 应用代理：折叠和展开都只允许竖屏，展开后不再切到横屏。
final class AppDelegate: UIResponder, UIApplicationDelegate {
    /// 当前允许的界面方向。iPhone Duo 展开后同样锁定竖屏。
    static var orientationMask: UIInterfaceOrientationMask = .portrait

    /// 系统查询窗口支持的界面方向时只返回竖屏。
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .portrait
    }

    /// 展开、折叠或设备旋转后，把界面拉回截图里的竖屏方向。
    static func refresh(for scene: UIWindowScene) {
        orientationMask = .portrait
        guard scene.interfaceOrientation != .portrait else { return }

        if #available(iOS 16.0, *) {
            for window in scene.windows {
                window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
