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

    @Test func tuningKeepsOriginalSpinVelocityContract() {
        #expect(CicadaTuning.minimumRotationPeriod == 360.0 / (CicadaTuning.maximumSpinVelocityDegreesPerFrame * CicadaTuning.framesPerSecond))
        #expect(CicadaTuning.minimumAudioPulsePeriod == CicadaTuning.audioPhaseDegrees / (CicadaTuning.maximumSpinVelocityDegreesPerFrame * CicadaTuning.framesPerSecond))
    }

}
