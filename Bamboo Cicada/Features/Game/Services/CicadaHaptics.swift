//
//  CicadaHaptics.swift
//  Bamboo Cicada
//

import Combine
import QuartzCore
import UIKit

@MainActor
final class CicadaHaptics: ObservableObject {
    private let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let strongFeedback = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private var lastPhasePulseTime: TimeInterval = 0
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
        lastPhasePulseTime = 0
        lastPrepareTime = 0
        hasPendingPrepare = false
        prepare()
    }

    func suspend() {
        isSuspended = true
        lastPhasePulseTime = 0
        hasPendingPrepare = false
    }

    func resume() {
        isSuspended = false
        prepare()
    }

    func startPulse(intensity: Double) {
        isSuspended = false
        lastPhasePulseTime = 0
        strongFeedback.impactOccurred(intensity: min(0.9, max(0.68, 0.64 + intensity * 0.24)))
        schedulePrepare()
    }

    func phasePulse(intensity: Double, speedRatio: Double, count: Int) {
        isSuspended = false
        guard count > 0 else { return }
        let now = CACurrentMediaTime()

        guard now - lastPhasePulseTime >= CicadaTuning.hapticMinimumInterval else {
            return
        }
        lastPhasePulseTime = now

        let impact = min(0.92, max(0.56, 0.52 + speedRatio * 0.42 + intensity * 0.24))
        if speedRatio > 0.52 || count > 1 {
            heavyFeedback.impactOccurred(intensity: impact)
        } else if speedRatio > 0.12 {
            strongFeedback.impactOccurred(intensity: max(0.56, impact))
        } else {
            mediumFeedback.impactOccurred(intensity: max(0.5, impact))
        }
        schedulePrepare()
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
