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
    @Published var frictionHapticPulseID = 0
    @Published var frictionHapticLevel: Double = 0
    @Published var rotationPeriod: TimeInterval = 1.5

    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private var rawIntensity: Double = 0
    private var rawSway: Double = 0
    private var angularVelocity: Double = 0
    private var highSpeedBlendRatio: Double = 0
    private var highSpeedSpinDirection: Double?
    private var audioPhaseAccumulator = 0.0
    private var frictionHapticAccumulator = 0.0
    private var wasMoving = false
    private var hasEmittedPhasePulse = false

    // CoreMotion 的重力向量。屏幕平面里使用 (gravity.x, -gravity.y) 作为“桌面向下”的力。
    private var gravityX = 0.0
    private var gravityY = -1.0

    // CoreMotion 的 userAcceleration。屏幕平面里取反作为手机加速带来的惯性力。
    private var accelerationX = 0.0
    private var accelerationY = 0.0
    private var smoothedGravityX = 0.0
    private var smoothedGravityY = -1.0
    private var smoothedAccelerationX = 0.0
    private var smoothedAccelerationY = 0.0

    var wingSpread: Double {
        min(1, 0.2 + shakeIntensity * 0.8)
    }

    func start() {
        queue.name = "Bamboo Cicada Motion"
        manager.deviceMotionUpdateInterval = 1.0 / CicadaTuning.framesPerSecond
        manager.accelerometerUpdateInterval = 1.0 / CicadaTuning.framesPerSecond

        if manager.isDeviceMotionAvailable {
            manager.startDeviceMotionUpdates(to: queue) { motion, _ in
                guard let motion else { return }
                let gravity = motion.gravity
                let acceleration = motion.userAcceleration
                let accelerationStrength = hypot(acceleration.x, hypot(acceleration.y, acceleration.z)) / 0.7
                let nextIntensity = min(1, accelerationStrength)
                let nextSway = max(-1, min(1, acceleration.x * 0.75))

                Task { @MainActor [weak self] in
                    self?.gravityX = gravity.x
                    self?.gravityY = gravity.y
                    self?.accelerationX = acceleration.x
                    self?.accelerationY = acceleration.y
                    self?.rawIntensity = nextIntensity
                    self?.rawSway = nextSway
                }
            }
        } else if manager.isAccelerometerAvailable {
            manager.startAccelerometerUpdates(to: queue) { data, _ in
                guard let data else { return }
                let acceleration = data.acceleration
                let accelerationMagnitude = hypot(acceleration.x, hypot(acceleration.y, acceleration.z))
                let shake = min(1, abs(accelerationMagnitude - 1.0) / 0.32)
                let nextSway = max(-1, min(1, acceleration.x * 0.75))

                Task { @MainActor [weak self] in
                    // 没有 deviceMotion 时只能用加速度计近似重力，仍然走同一个刚性绳模型。
                    self?.gravityX = acceleration.x
                    self?.gravityY = acceleration.y
                    self?.accelerationX = 0
                    self?.accelerationY = 0
                    self?.rawIntensity = shake
                    self?.rawSway = nextSway
                }
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        manager.stopAccelerometerUpdates()
        rawIntensity = 0
        rawSway = 0
        angularVelocity = 0
        highSpeedBlendRatio = 0
        highSpeedSpinDirection = nil
        audioPhaseAccumulator = 0
        frictionHapticAccumulator = 0
        wasMoving = false
        hasEmittedPhasePulse = false
        gravityX = 0
        gravityY = -1
        accelerationX = 0
        accelerationY = 0
        smoothedGravityX = 0
        smoothedGravityY = -1
        smoothedAccelerationX = 0
        smoothedAccelerationY = 0
        shakeIntensity = 0
        sway = 0
        orbitAngle = 0
        spinSpeedRatio = 0
        audioPulseID = 0
        audioPulsePeriod = CicadaTuning.minimumAudioPulsePeriod
        audioPlaybackRate = 1.0
        spinStartPulseID = 0
        frictionHapticPulseID = 0
        frictionHapticLevel = 0
        rotationPeriod = 1.5
    }

    func settleMotion(frameInterval: TimeInterval) {
        let frameScale = normalizedFrameScale(for: frameInterval)
        shakeIntensity += (rawIntensity - shakeIntensity) * interpolationRatio(baseRatio: 0.18, frameScale: frameScale)
        sway += (rawSway - sway) * interpolationRatio(baseRatio: 0.22, frameScale: frameScale)

        let maximumVelocity = CicadaTuning.maximumSpinVelocityDegreesPerFrame
        let previousAngularVelocity = angularVelocity
        updateSmoothedMotionInput(frameScale: frameScale)
        updateHighSpeedBlend(frameScale: frameScale)
        let force = tablePlaneForceComponents(highSpeedBlendRatio: highSpeedBlendRatio)
        let gravityTangentialForce = CicadaRestOrientation.tangentialForce(
            angleDegrees: orbitAngle,
            forceX: force.gravity.x,
            forceY: force.gravity.y
        )
        let accelerationTangentialForce = CicadaRestOrientation.tangentialForce(
            angleDegrees: orbitAngle,
            forceX: force.acceleration.x,
            forceY: force.acceleration.y
        )

        // 刚性绳约束：重力先决定自然运动方向；加速度只沿既有方向追加能量。
        let gravityDrivenVelocity = CicadaSpinDirection.velocityAfterGravity(
            baseVelocity: angularVelocity,
            gravityDelta: gravityTangentialForce * CicadaTuning.ropeGravityResponse * frameScale,
            lockedDirection: highSpeedSpinDirection
        )
        highSpeedSpinDirection = CicadaSpinDirection.lockedDirection(
            currentDirection: highSpeedSpinDirection,
            angularVelocity: gravityDrivenVelocity,
            blendRatio: highSpeedBlendRatio
        )
        angularVelocity = CicadaSpinDirection.velocityAfterAcceleration(
            baseVelocity: gravityDrivenVelocity,
            accelerationDelta: accelerationTangentialForce * CicadaTuning.ropeGravityResponse * frameScale,
            lockedDirection: highSpeedSpinDirection
        )
        applyHighSpeedSpinDrive(maximumVelocity: maximumVelocity, frameScale: frameScale)
        angularVelocity *= pow(CicadaTuning.ropeAngularDamping, frameScale)
        let velocityDelta = angularVelocity - previousAngularVelocity
        let maximumDelta = CicadaTuning.maximumAngularVelocityDeltaPerFrame * frameScale
        if velocityDelta > maximumDelta {
            angularVelocity = previousAngularVelocity + maximumDelta
        } else if velocityDelta < -maximumDelta {
            angularVelocity = previousAngularVelocity - maximumDelta
        }
        angularVelocity = min(maximumVelocity, max(-maximumVelocity, angularVelocity))

        orbitAngle += angularVelocity * frameScale

        let effectiveAngularSpeed = abs(angularVelocity) < CicadaTuning.ropeAudioVelocityDeadzone
            ? 0
            : abs(angularVelocity)
        spinSpeedRatio = min(1, effectiveAngularSpeed / maximumVelocity)
        audioPlaybackRate = spinSpeedRatio * CicadaTuning.maximumAudioPlaybackRate

        if effectiveAngularSpeed > 0 {
            rotationPeriod = max(CicadaTuning.minimumRotationPeriod, 360.0 / (effectiveAngularSpeed * CicadaTuning.framesPerSecond))
            audioPulsePeriod = max(CicadaTuning.minimumAudioPulsePeriod, CicadaTuning.audioPhaseDegrees / (effectiveAngularSpeed * CicadaTuning.framesPerSecond))
        }

        updateMotionPulses(effectiveAngularSpeed: effectiveAngularSpeed * frameScale)
        updateFrictionHaptics(
            angularSpeed: abs(angularVelocity) * frameScale,
            maximumVelocity: maximumVelocity * frameScale
        )
        rawIntensity *= pow(0.94, frameScale)
        rawSway *= pow(0.94, frameScale)
    }

    private func normalizedFrameScale(for frameInterval: TimeInterval) -> Double {
        let referenceInterval = 1.0 / CicadaTuning.framesPerSecond
        return min(2, max(0.25, frameInterval / referenceInterval))
    }

    private func interpolationRatio(baseRatio: Double, frameScale: Double) -> Double {
        1 - pow(1 - baseRatio, frameScale)
    }

    private func updateSmoothedMotionInput(frameScale: Double) {
        let smoothing = interpolationRatio(
            baseRatio: max(0, min(1, CicadaTuning.motionInputSmoothing)),
            frameScale: frameScale
        )
        smoothedGravityX += (gravityX - smoothedGravityX) * smoothing
        smoothedGravityY += (gravityY - smoothedGravityY) * smoothing
        smoothedAccelerationX += (accelerationX - smoothedAccelerationX) * smoothing
        smoothedAccelerationY += (accelerationY - smoothedAccelerationY) * smoothing
    }

    private func updateHighSpeedBlend(frameScale: Double) {
        let start = CicadaTuning.highSpeedBlendStartIntensity
        let end = max(start + 0.001, CicadaTuning.highSpeedBlendEndIntensity)
        let normalizedIntensity = min(1, max(0, (shakeIntensity - start) / (end - start)))
        let smoothTarget = normalizedIntensity * normalizedIntensity * (3 - 2 * normalizedIntensity)
        if rawIntensity >= end {
            highSpeedBlendRatio = max(highSpeedBlendRatio, CicadaTuning.highSpeedBlendKickstartRatio)
        }
        highSpeedBlendRatio += (smoothTarget - highSpeedBlendRatio) * interpolationRatio(
            baseRatio: CicadaTuning.highSpeedBlendSmoothing,
            frameScale: frameScale
        )
    }

    private func applyHighSpeedSpinDrive(maximumVelocity: Double, frameScale: Double) {
        guard let direction = highSpeedSpinDirection else { return }

        // 高速区不是重置速度，而是把已有角速度平滑拉向同方向目标速度，保留进入瞬间的惯性。
        let targetSpeedRatio = pow(highSpeedBlendRatio, 0.72)
        let targetVelocity = direction * maximumVelocity * targetSpeedRatio
        let response = interpolationRatio(
            baseRatio: CicadaTuning.highSpeedSpinDriveResponse * highSpeedBlendRatio,
            frameScale: frameScale
        )
        angularVelocity += (targetVelocity - angularVelocity) * response
    }

    private func tablePlaneForceComponents(
        highSpeedBlendRatio: Double
    ) -> (gravity: (x: Double, y: Double), acceleration: (x: Double, y: Double)) {
        let minimumGravity = max(0, min(1, CicadaTuning.highSpeedMinimumGravityInfluence))
        let gravityScale = 1 - highSpeedBlendRatio * (1 - minimumGravity)
        let accelerationScale = CicadaTuning.ropeAccelerationResponse
            * (1 + highSpeedBlendRatio * (CicadaTuning.highSpeedAccelerationBoost - 1))

        let gravityForceX = smoothedGravityX * gravityScale
        let gravityForceY = -smoothedGravityY * gravityScale
        let inertialForceX = -smoothedAccelerationX * accelerationScale
        let inertialForceY = smoothedAccelerationY * accelerationScale

        return (
            gravity: (x: gravityForceX, y: gravityForceY),
            acceleration: (x: inertialForceX, y: inertialForceY)
        )
    }

    private func updateMotionPulses(effectiveAngularSpeed: Double) {
        let isMoving = effectiveAngularSpeed > 0
        if isMoving, !wasMoving {
            audioPhaseAccumulator = 0
        }
        wasMoving = isMoving

        guard isMoving else {
            audioPhaseAccumulator = 0
            hasEmittedPhasePulse = false
            return
        }

        audioPhaseAccumulator += effectiveAngularSpeed
        var pulseCount = 0
        while audioPhaseAccumulator >= CicadaTuning.audioPhaseDegrees,
              pulseCount < CicadaTuning.maximumAudioPulsesPerFrame {
            pulseCount += 1
            audioPhaseAccumulator -= CicadaTuning.audioPhaseDegrees
        }

        if pulseCount > 0 {
            audioPulseID += pulseCount
            if hasEmittedPhasePulse {
                spinStartPulseID += 1
            }
            hasEmittedPhasePulse = true
        }
    }

    private func updateFrictionHaptics(angularSpeed: Double, maximumVelocity: Double) {
        guard angularSpeed >= CicadaTuning.minimumFrictionHapticVelocityDegreesPerFrame else {
            frictionHapticAccumulator = 0
            frictionHapticLevel = 0
            return
        }

        frictionHapticAccumulator += angularSpeed
        guard frictionHapticAccumulator >= CicadaTuning.frictionHapticPhaseDegrees else { return }

        frictionHapticAccumulator = frictionHapticAccumulator.truncatingRemainder(
            dividingBy: CicadaTuning.frictionHapticPhaseDegrees
        )
        let speedLevel = min(1, angularSpeed / maximumVelocity * CicadaTuning.frictionHapticSpeedMultiplier)
        frictionHapticLevel = max(CicadaTuning.frictionHapticMinimumIntensity, speedLevel)
        frictionHapticPulseID += 1
    }
}
