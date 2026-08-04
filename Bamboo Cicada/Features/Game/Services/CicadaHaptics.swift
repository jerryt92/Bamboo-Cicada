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

    func prepare() {
        mediumFeedback.prepare()
        strongFeedback.prepare()
        heavyFeedback.prepare()
    }

    func wake() {
        strongFeedback.impactOccurred(intensity: 0.75)
        prepare()
    }

    func reset() {
        lastPhasePulseTime = 0
        prepare()
    }

    func startPulse(intensity: Double) {
        lastPhasePulseTime = 0
        strongFeedback.impactOccurred(intensity: min(1, max(0.65, 0.62 + intensity * 0.28)))
        prepare()
    }

    func phasePulse(intensity: Double, speedRatio: Double, count: Int) {
        guard count > 0 else { return }
        let now = CACurrentMediaTime()

        guard now - lastPhasePulseTime >= CicadaTuning.hapticMinimumInterval else {
            prepare()
            return
        }
        lastPhasePulseTime = now

        let impact = min(1, max(0.48, 0.45 + speedRatio * 0.45 + intensity * 0.22))
        if speedRatio > 0.72 || count > 1 {
            heavyFeedback.impactOccurred(intensity: impact)
        } else if speedRatio > 0.34 {
            strongFeedback.impactOccurred(intensity: impact)
        } else {
            mediumFeedback.impactOccurred(intensity: impact)
        }
        prepare()
    }
}
