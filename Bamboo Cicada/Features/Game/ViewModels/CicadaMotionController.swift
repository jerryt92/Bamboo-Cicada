//
//  CicadaMotionController.swift
//  Bamboo Cicada
//

import Combine
import CoreMotion
import Foundation

@MainActor
final class CicadaMotionController: ObservableObject {
    @Published var shakeIntensity: Double = 0
    @Published var sway: Double = 0
    @Published var orbitAngle: Double = 0
    @Published var spinSpeedRatio: Double = 0
    @Published var audioPulseID = 0
    @Published var audioPulsePeriod: TimeInterval = CicadaTuning.minimumAudioPulsePeriod
    @Published var audioPlaybackRate: Double = 1.0
    @Published var spinStartPulseID = 0
    @Published var rotationPeriod: TimeInterval = 1.5

    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private let startThreshold = 0.14
    private let sustainThreshold = 0.07
    private let spinVelocityDeadzone = 0.16
    private let directionUnlockFrames = 4
    private var rawIntensity: Double = 0
    private var rawSway: Double = 0
    private var spinVelocity: Double = 0
    private var spinDirection: Double?
    private var hasLockedSpinDirection = false
    private var isInSpinDeadzone = true
    private var directionSampleSum: Double = 0
    private var settledFrameCount = 0
    private var totalOrbitAngle: Double = 0
    private var audioPhaseAccumulator = 0.0

    var wingSpread: Double {
        min(1, 0.2 + shakeIntensity * 0.8)
    }

    func start() {
        queue.name = "Bamboo Cicada Motion"
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.accelerometerUpdateInterval = 1.0 / 60.0

        if manager.isDeviceMotionAvailable {
            manager.startDeviceMotionUpdates(to: queue) { motion, _ in
                guard let motion else { return }
                let rotation = motion.rotationRate
                let acceleration = motion.userAcceleration
                let rotationStrength = hypot(rotation.x, hypot(rotation.y, rotation.z)) / 3.5
                let accelerationStrength = hypot(acceleration.x, hypot(acceleration.y, acceleration.z)) / 0.7
                let nextIntensity = min(1, max(rotationStrength, accelerationStrength))
                let nextSway = max(-1, min(1, rotation.z / 5.0 + acceleration.x * 0.55))

                Task { @MainActor [weak self] in
                    self?.rawIntensity = nextIntensity
                    self?.rawSway = nextSway
                }
            }
        }

        if manager.isAccelerometerAvailable {
            manager.startAccelerometerUpdates(to: queue) { data, _ in
                guard let data else { return }
                let acceleration = data.acceleration
                let magnitude = hypot(acceleration.x, hypot(acceleration.y, acceleration.z))
                let shake = min(1, abs(magnitude - 1.0) / 0.32)
                let nextSway = max(-1, min(1, acceleration.x * 0.75))

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.rawIntensity = max(self.rawIntensity, shake)
                    if abs(nextSway) > abs(self.rawSway) {
                        self.rawSway = nextSway
                    }
                }
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        manager.stopAccelerometerUpdates()
        rawIntensity = 0
        rawSway = 0
        spinVelocity = 0
        spinDirection = nil
        hasLockedSpinDirection = false
        isInSpinDeadzone = true
        directionSampleSum = 0
        settledFrameCount = 0
        totalOrbitAngle = 0
        audioPhaseAccumulator = 0
        shakeIntensity = 0
        sway = 0
        orbitAngle = 0
        spinSpeedRatio = 0
        audioPulseID = 0
        audioPulsePeriod = CicadaTuning.minimumAudioPulsePeriod
        audioPlaybackRate = 1.0
        spinStartPulseID = 0
        rotationPeriod = 1.5
    }

    func settleMotion() {
        shakeIntensity = shakeIntensity * 0.82 + rawIntensity * 0.18
        sway = sway * 0.78 + rawSway * 0.22

        if !hasLockedSpinDirection {
            directionSampleSum = directionSampleSum * 0.78 + rawSway
        }

        if shakeIntensity > startThreshold, !hasLockedSpinDirection {
            let sampledDirection = abs(directionSampleSum) > 0.04 ? directionSampleSum : rawSway
            let lockedDirection: Double = sampledDirection < 0 ? -1 : 1
            spinDirection = lockedDirection
            hasLockedSpinDirection = true
            isInSpinDeadzone = false
            audioPhaseAccumulator = 0
            spinStartPulseID += 1
            settledFrameCount = 0
        }

        let maximumSpinVelocity = CicadaTuning.maximumSpinVelocityDegreesPerFrame
        let activeThreshold = isInSpinDeadzone ? startThreshold : sustainThreshold
        if shakeIntensity > activeThreshold, let direction = spinDirection {
            if isInSpinDeadzone {
                spinStartPulseID += 1
                isInSpinDeadzone = false
            }
            let normalizedIntensity = max(0, (shakeIntensity - sustainThreshold) / (1 - sustainThreshold))
            let speedRatio = min(1, pow(normalizedIntensity, 0.7))
            let targetVelocity = direction * maximumSpinVelocity * speedRatio
            spinVelocity += (targetVelocity - spinVelocity) * 0.24
        } else {
            spinVelocity *= 0.94
            if abs(spinVelocity) < spinVelocityDeadzone {
                spinVelocity = 0
                isInSpinDeadzone = true
            }
        }

        let effectiveSpinVelocity = abs(spinVelocity) < spinVelocityDeadzone ? 0 : spinVelocity
        let effectiveAngularSpeed = abs(effectiveSpinVelocity)
        spinSpeedRatio = min(1, effectiveAngularSpeed / maximumSpinVelocity)
        audioPlaybackRate = spinSpeedRatio * CicadaTuning.maximumAudioPlaybackRate
        if effectiveAngularSpeed > 0 {
            rotationPeriod = max(CicadaTuning.minimumRotationPeriod, 360.0 / (effectiveAngularSpeed * CicadaTuning.framesPerSecond))
            audioPulsePeriod = max(CicadaTuning.minimumAudioPulsePeriod, CicadaTuning.audioPhaseDegrees / (effectiveAngularSpeed * CicadaTuning.framesPerSecond))
        }

        totalOrbitAngle += effectiveSpinVelocity
        if effectiveAngularSpeed > 0 {
            audioPhaseAccumulator += effectiveAngularSpeed
            var pulseCount = 0
            while audioPhaseAccumulator >= CicadaTuning.audioPhaseDegrees, pulseCount < 4 {
                pulseCount += 1
                audioPhaseAccumulator -= CicadaTuning.audioPhaseDegrees
            }
            if pulseCount > 0 {
                audioPulseID += pulseCount
            }
        }
        orbitAngle = totalOrbitAngle
        updateDirectionResetState()
        rawIntensity *= 0.94
        rawSway *= 0.94
    }

    private func updateDirectionResetState() {
        let isSettled = isInSpinDeadzone
            && shakeIntensity < startThreshold
            && rawIntensity < startThreshold
            && abs(spinVelocity) < spinVelocityDeadzone

        if isSettled {
            settledFrameCount += 1
        } else {
            settledFrameCount = 0
        }

        guard settledFrameCount >= directionUnlockFrames else { return }
        spinDirection = nil
        hasLockedSpinDirection = false
        isInSpinDeadzone = true
        directionSampleSum = 0
        audioPhaseAccumulator = 0
        settledFrameCount = directionUnlockFrames
    }
}
