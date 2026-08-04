//
//  CicadaTuning.swift
//  Bamboo Cicada
//

import Foundation

enum CicadaTuning {
    static var maximumSpinVelocityDegreesPerFrame = 18.0
    static var audioPlaybackRateMultiplier = 1.0
    static var maximumAudioPlaybackRate = 1.0
    static let hapticMinimumInterval: TimeInterval = 0.045
    static let framesPerSecond = 60.0
    static let audioPhaseDegrees = 180.0

    static var minimumRotationPeriod: TimeInterval {
        360.0 / (maximumSpinVelocityDegreesPerFrame * framesPerSecond)
    }

    static var minimumAudioPulsePeriod: TimeInterval {
        audioPhaseDegrees / (maximumSpinVelocityDegreesPerFrame * framesPerSecond)
    }
}
