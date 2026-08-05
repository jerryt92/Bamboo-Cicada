//
//  CicadaRestOrientation.swift
//  Bamboo Cicada
//

import Foundation

enum CicadaRestOrientation {
    // 把 CoreMotion 重力方向投影到屏幕平面，再转换成视图使用的 orbitAngle。
    static func targetAngleDegrees(gravityX: Double, gravityY: Double) -> Double {
        guard abs(gravityX) + abs(gravityY) > 0.0001 else { return 0 }
        let screenDownX = abs(gravityX) < 0.0001 ? 0 : gravityX
        let screenDownY = abs(gravityY) < 0.0001 ? 0 : -gravityY
        let visualAngle = atan2(screenDownY, screenDownX)
        return normalizedDegrees((visualAngle - .pi / 2.0) * 180.0 / .pi)
    }

    // 计算屏幕平面内合力在刚性绳圆周切线方向上的分量。
    static func tangentialForce(angleDegrees: Double, forceX: Double, forceY: Double) -> Double {
        let angle = angleDegrees * .pi / 180.0
        let tangentX = -cos(angle)
        let tangentY = -sin(angle)
        return forceX * tangentX + forceY * tangentY
    }

    // 取两个角度之间最短的差值，避免跨过 0/360 度时跳变。
    static func shortestAngleDegrees(from current: Double, to target: Double) -> Double {
        var delta = normalizedDegrees(target - current)
        if delta > 180 {
            delta -= 360
        }
        return delta
    }

    static func normalizedDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360)
        if value < 0 {
            value += 360
        }
        return value
    }
}

enum CicadaSpinDirection {
    static func lockedDirection(
        currentDirection: Double?,
        angularVelocity: Double,
        blendRatio: Double
    ) -> Double? {
        if currentDirection != nil,
           abs(angularVelocity) < CicadaTuning.ropeAudioVelocityDeadzone {
            return nil
        }

        guard blendRatio > CicadaTuning.highSpeedDirectionUnlockRatio,
              currentDirection == nil else {
            return currentDirection
        }

        return direction(for: angularVelocity, threshold: CicadaTuning.highSpeedMotionDirectionLockVelocity)
    }

    static func velocityAfterGravity(
        baseVelocity: Double,
        gravityDelta: Double,
        lockedDirection: Double?
    ) -> Double {
        let candidateVelocity = baseVelocity + gravityDelta
        guard let lockedDirection else { return candidateVelocity }
        guard candidateVelocity * lockedDirection <= 0 else { return candidateVelocity }
        return 0
    }

    static func velocityAfterAcceleration(
        baseVelocity: Double,
        accelerationDelta: Double,
        lockedDirection: Double?
    ) -> Double {
        let referenceDirection = lockedDirection
            ?? direction(for: baseVelocity, threshold: CicadaTuning.highSpeedMotionDirectionLockVelocity)

        guard let referenceDirection,
              accelerationDelta * referenceDirection > 0 else {
            return baseVelocity
        }

        return baseVelocity + accelerationDelta
    }

    private static func direction(for velocity: Double, threshold: Double) -> Double? {
        guard abs(velocity) >= threshold else { return nil }
        return velocity < 0 ? -1 : 1
    }
}
