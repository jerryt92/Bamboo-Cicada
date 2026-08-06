//
//  CicadaTuning.swift
//  Bamboo Cicada
//

import Foundation

enum CicadaTuning {
    // 刚性绳圆周运动每帧允许的最大角速度。越大，竹知了沿圆弧甩得越快。
    static var maximumSpinVelocityDegreesPerFrame = 20.0

    // 屏幕“台球桌”平面内的重力响应。越大，倾斜手机时知了越快滑向重力下垂方向。
    static var ropeGravityResponse = 0.62

    // 手机线性加速度造成的惯性力响应。越大，甩手机时越容易给圆周运动加速。
    static var ropeAccelerationResponse = 0.72

    // 从这个运动强度开始，逐渐从重力下垂区过渡到高速甩动区。
    static var highSpeedBlendStartIntensity = 0.34

    // 到这个运动强度时，基本进入高速甩动区。
    static var highSpeedBlendEndIntensity = 0.72

    // 高速区间仍保留的最小重力比例。越小，高速时越不被重力拖慢。
    static var highSpeedMinimumGravityInfluence = 0.16

    // 高速区间对加速度的额外放大倍数。越大，甩动越容易持续加速。
    static var highSpeedAccelerationBoost = 1.85

    // 高速区间追向目标旋转速度的力度。越大，进入甩动后越快转起来；过大会产生速度突变。
    static var highSpeedSpinDriveResponse = 0.22

    // 高速区首次锁方向时，只要已有这点角速度，就优先沿当前运动方向继续甩。
    static var highSpeedMotionDirectionLockVelocity = 0.06

    // 高速混合比例低于这个值且速度也很低时，才释放上一次锁定的甩动方向。
    static var highSpeedDirectionUnlockRatio = 0.08

    // 低速/高速混合比例的平滑速度。越大，状态切换越跟手；越小，过渡越柔。
    static var highSpeedBlendSmoothing = 0.12

    // 第一次快速甩动时预先给高速区的最低混合比例，避免从 0 爬升造成起转卡顿。
    static var highSpeedBlendKickstartRatio = 0.32

    // 重力和加速度输入的低通平滑比例。越大越跟手，越小越能过滤甩动尖峰。
    static var motionInputSmoothing = 0.26

    // 单帧角速度允许变化的最大值，避免大幅加速度或高速驱动造成画面顿跳。
    static var maximumAngularVelocityDeltaPerFrame = 2.8

    // 每帧保留的角速度比例。越接近 1，旋转惯性越强；越小，越快被空气/摩擦耗散。
    static var ropeAngularDamping = 0.988

    // 声音的极低速噪声门限。只过滤传感器静止微抖；低速重力摆动也会按真实角速度发声。
    static var ropeAudioVelocityDeadzone = 0.02

    // 声音播放速度倍率。调大后同样的摆速会播放得更尖、更快。
    static var audioPlaybackRateMultiplier = 1.0

    // 声音播放速度上限，避免高速摆动时音频变得过快。
    static var maximumAudioPlaybackRate = 1.0

    // 启动时只 prepare 一部分播放器，不播放音频，确保冷启动完全静音。
    static let audioPrewarmPlayerCount = 4

    // 是否启用运动过程中的触感。触感只跟随相位脉冲，不在起转第一帧打断动画。
    static let isMotionHapticsEnabled = true

    // 刚性绳摩擦触感累计多少角度触发一次。越小，重力摆动时触感越细密。
    static let frictionHapticPhaseDegrees = 18.0

    // 低于这个角速度时不触发摩擦触感，避免完全静止时轻微传感器噪声也震动。
    static let minimumFrictionHapticVelocityDegreesPerFrame = 0.02

    // 摩擦触感的最低强度，让低速重力摆动也有可感知的质感；调低会让摩擦更轻。
    static let frictionHapticMinimumIntensity = 0.5

    // 摩擦触感的速度映射倍率。越大，同样速度下触感越强。
    static let frictionHapticSpeedMultiplier = 1.2

    // 两次触感脉冲之间的最短间隔，防止高频摆动时震动过密。
    static let hapticMinimumInterval: TimeInterval = 0.03

    // 转速映射到触感强度的对数曲线。越大，低速触感越容易被感知。
    static let hapticIntensityLogarithmicCurve = 9.0

    // 触感硬件预热的最短间隔，避免在动画帧里反复 prepare 造成卡顿。
    static let hapticPrepareMinimumInterval: TimeInterval = 0.25

    // 运动积分假定的刷新率，需要和 ContentView 的 frameTimer 保持一致。
    static let framesPerSecond = 60.0

    // 摆体累计经过多少角度触发一次声音/触感相位脉冲。
    static let audioPhaseDegrees = 180.0

    // 单帧最多触发的声音脉冲数，避免极端速度下一帧塞入太多音效造成卡顿。
    static let maximumAudioPulsesPerFrame = 1

    // 当前最大角速度下完成一圈所需的最短时间，用于同步外部节奏。
    static var minimumRotationPeriod: TimeInterval {
        360.0 / (maximumSpinVelocityDegreesPerFrame * framesPerSecond)
    }

    // 当前最大角速度下相邻声音脉冲的最短时间。
    static var minimumAudioPulsePeriod: TimeInterval {
        audioPhaseDegrees / (maximumSpinVelocityDegreesPerFrame * framesPerSecond)
    }
}
