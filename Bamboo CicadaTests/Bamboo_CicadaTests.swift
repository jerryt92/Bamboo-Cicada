//
//  Bamboo_CicadaTests.swift
//  Bamboo CicadaTests
//
//  Created by Tian Jingli on 2026/8/4.
//

import Testing
@testable import Bamboo_Cicada

struct Bamboo_CicadaTests {

    @Test func gravityTargetMapsDeviceTiltToScreenArc() {
        #expect(abs(CicadaRestOrientation.targetAngleDegrees(gravityX: 0, gravityY: -1) - 0) < 0.001)
        #expect(abs(CicadaRestOrientation.targetAngleDegrees(gravityX: 1, gravityY: 0) - 270) < 0.001)
        #expect(abs(CicadaRestOrientation.targetAngleDegrees(gravityX: -1, gravityY: 0) - 90) < 0.001)
    }

    @Test func shortestAngleUsesNearestWraparoundPath() {
        #expect(CicadaRestOrientation.shortestAngleDegrees(from: 350, to: 10) == 20)
        #expect(CicadaRestOrientation.shortestAngleDegrees(from: 10, to: 350) == -20)
    }

    @Test func tangentialForcePullsAlongRigidRopeArc() {
        #expect(abs(CicadaRestOrientation.tangentialForce(angleDegrees: 0, forceX: 0, forceY: 1)) < 0.001)
        #expect(CicadaRestOrientation.tangentialForce(angleDegrees: 90, forceX: 0, forceY: 1) < -0.99)
        #expect(CicadaRestOrientation.tangentialForce(angleDegrees: 270, forceX: 0, forceY: 1) > 0.99)
    }

    @Test func highSpeedDirectionKeepsExistingGravityMotionDirection() {
        let direction = CicadaSpinDirection.lockedDirection(
            currentDirection: nil,
            angularVelocity: 0.2,
            blendRatio: 0.5
        )

        #expect(direction == 1)
    }

    @Test func highSpeedDirectionIgnoresAccelerationWhenStill() {
        let direction = CicadaSpinDirection.lockedDirection(
            currentDirection: nil,
            angularVelocity: 0.01,
            blendRatio: 0.5
        )

        #expect(direction == nil)
    }

    @Test func highSpeedDirectionDoesNotReverseUntilStopped() {
        let direction = CicadaSpinDirection.lockedDirection(
            currentDirection: 1,
            angularVelocity: 3,
            blendRatio: 0.8
        )

        #expect(direction == 1)
    }

    @Test func highSpeedDirectionReleasesWhenStopped() {
        let direction = CicadaSpinDirection.lockedDirection(
            currentDirection: 1,
            angularVelocity: 0.001,
            blendRatio: 0.8
        )

        #expect(direction == nil)
    }


    @Test func gravityCanCreateDirectionWhenUnlocked() {
        let velocity = CicadaSpinDirection.velocityAfterGravity(
            baseVelocity: 0,
            gravityDelta: -0.2,
            lockedDirection: nil
        )

        #expect(abs(velocity + 0.2) < 0.001)
    }

    @Test func gravityStopsLockedDirectionBeforeReversing() {
        let velocity = CicadaSpinDirection.velocityAfterGravity(
            baseVelocity: 0.2,
            gravityDelta: -2,
            lockedDirection: 1
        )

        #expect(velocity == 0)
    }

    @Test func accelerationDoesNotCreateDirectionFromStillness() {
        let velocity = CicadaSpinDirection.velocityAfterAcceleration(
            baseVelocity: 0.01,
            accelerationDelta: -2,
            lockedDirection: nil
        )

        #expect(abs(velocity - 0.01) < 0.001)
    }

    @Test func accelerationIgnoresOppositeGravityDirection() {
        let velocity = CicadaSpinDirection.velocityAfterAcceleration(
            baseVelocity: 0.2,
            accelerationDelta: -2,
            lockedDirection: nil
        )

        #expect(abs(velocity - 0.2) < 0.001)
    }

    @Test func accelerationCannotReverseLockedDirection() {
        let velocity = CicadaSpinDirection.velocityAfterAcceleration(
            baseVelocity: 0.2,
            accelerationDelta: -2,
            lockedDirection: 1
        )

        #expect(abs(velocity - 0.2) < 0.001)
    }

    @Test func accelerationCanBoostExistingDirection() {
        let velocity = CicadaSpinDirection.velocityAfterAcceleration(
            baseVelocity: 0.2,
            accelerationDelta: 0.5,
            lockedDirection: nil
        )

        #expect(abs(velocity - 0.7) < 0.001)
    }

    @Test func tuningKeepsOriginalSpinVelocityContract() {
        #expect(CicadaTuning.minimumRotationPeriod == 360.0 / (CicadaTuning.maximumSpinVelocityDegreesPerFrame * CicadaTuning.framesPerSecond))
        #expect(CicadaTuning.minimumAudioPulsePeriod == CicadaTuning.audioPhaseDegrees / (CicadaTuning.maximumSpinVelocityDegreesPerFrame * CicadaTuning.framesPerSecond))
    }

}
