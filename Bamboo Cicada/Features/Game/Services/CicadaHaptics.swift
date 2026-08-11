//
//  CicadaHaptics.swift
//  Bamboo Cicada
//

import Combine
import Foundation
import QuartzCore
import UIKit

enum HapticStrength: String, CaseIterable, Identifiable {
    case off
    case gentle
    case medium
    case strong

    static let storageKey = "hapticStrength"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .off: 0
        case .gentle: 0.65
        case .medium: 1.0
        case .strong: 1.3
        }
    }
}

private struct HapticPulse: Sendable {
    var speedRatio: Double
    var strengthMultiplier: Double
    var count: Int

    func merged(with other: HapticPulse) -> HapticPulse {
        HapticPulse(
            speedRatio: max(speedRatio, other.speedRatio),
            strengthMultiplier: max(strengthMultiplier, other.strengthMultiplier),
            count: max(count, other.count)
        )
    }
}

private final class HapticPulseScheduler: @unchecked Sendable {
    private let queue = DispatchQueue(label: "Bamboo Cicada Haptic Scheduler", qos: .userInitiated)
    private var pendingPulse: HapticPulse?
    private var lastPulseTime: TimeInterval = 0
    private var isDeliveryScheduled = false
    private var generation = 0

    func request(
        _ pulse: HapticPulse,
        minimumInterval: TimeInterval,
        deliver: @escaping @Sendable (HapticPulse) -> Void
    ) {
        queue.async { [weak self] in
            guard let self else { return }
            self.pendingPulse = self.pendingPulse.map { $0.merged(with: pulse) } ?? pulse
            guard !self.isDeliveryScheduled else { return }

            self.isDeliveryScheduled = true
            let delay = max(0, minimumInterval - (CACurrentMediaTime() - self.lastPulseTime))
            let deliveryGeneration = self.generation
            self.queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, deliveryGeneration == self.generation else { return }
                self.isDeliveryScheduled = false
                guard let nextPulse = self.pendingPulse else { return }
                self.pendingPulse = nil
                self.lastPulseTime = CACurrentMediaTime()
                DispatchQueue.main.async {
                    deliver(nextPulse)
                }
            }
        }
    }

    func cancel() {
        queue.async { [weak self] in
            guard let self else { return }
            self.generation += 1
            self.pendingPulse = nil
            self.isDeliveryScheduled = false
            self.lastPulseTime = 0
        }
    }
}

@MainActor
final class CicadaHaptics: ObservableObject {
    private let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let strongFeedback = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private let pulseScheduler = HapticPulseScheduler()
    private var lastPrepareTime: TimeInterval = 0
    private var hasPendingPrepare = false
    private var isSuspended = false

    func prepare() {
        guard !isSuspended else { return }
        let now = CACurrentMediaTime()
        guard now - lastPrepareTime >= CicadaTuning.hapticPrepareMinimumInterval else { return }
        lastPrepareTime = now
        mediumFeedback.prepare()
        strongFeedback.prepare()
        heavyFeedback.prepare()
    }

    func wake() {
        isSuspended = false
        heavyFeedback.impactOccurred(intensity: 1.0)
        prepare()
    }

    func reset() {
        isSuspended = false
        lastPrepareTime = 0
        hasPendingPrepare = false
        pulseScheduler.cancel()
        prepare()
    }

    func suspend() {
        isSuspended = true
        hasPendingPrepare = false
        pulseScheduler.cancel()
    }

    func resume() {
        isSuspended = false
        prepare()
    }

    func startPulse(speedRatio: Double, strength: HapticStrength) {
        isSuspended = false
        strongFeedback.impactOccurred(intensity: intensity(for: speedRatio, strength: strength.multiplier))
        schedulePrepare()
    }

    func phasePulse(speedRatio: Double, count: Int, strength: HapticStrength) {
        isSuspended = false
        guard count > 0 else { return }

        pulseScheduler.request(
            HapticPulse(
                speedRatio: speedRatio,
                strengthMultiplier: strength.multiplier,
                count: count
            ),
            minimumInterval: CicadaTuning.hapticMinimumInterval
        ) { [weak self] pulse in
            Task { @MainActor [weak self] in
                self?.performPhasePulse(pulse)
            }
        }
    }

    private func performPhasePulse(_ pulse: HapticPulse) {
        guard !isSuspended else { return }

        // 保持同一种触感发生器，避免跨阈值时出现体感台阶。
        heavyFeedback.impactOccurred(
            intensity: intensity(for: pulse.speedRatio, strength: pulse.strengthMultiplier)
        )
        schedulePrepare()
    }

    private func intensity(for speedRatio: Double, strength: Double) -> Double {
        let speed = max(0, min(1, speedRatio))
        let curve = CicadaTuning.hapticIntensityLogarithmicCurve
        let logarithmicIntensity = log1p(curve * speed) / log1p(curve)
        return min(1, logarithmicIntensity * strength)
    }

    private func schedulePrepare() {
        guard !hasPendingPrepare else { return }
        hasPendingPrepare = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.hasPendingPrepare = false
                self.prepare()
            }
        }
    }
}
