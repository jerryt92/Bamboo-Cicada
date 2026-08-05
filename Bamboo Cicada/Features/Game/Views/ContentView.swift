//
//  ContentView.swift
//  Bamboo Cicada
//
//  Created by Tian Jingli on 2026/8/4.
//

import Combine
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var motion = CicadaMotionController()
    @StateObject private var buzzer = CicadaBuzzer()
    @StateObject private var haptics = CicadaHaptics()
    @State private var lastAudioPulseID = 0
    @State private var lastStartPulseID = 0
    @State private var lastFrictionHapticPulseID = 0
    @State private var isShowingIntroduction = false
    @State private var isGameRunning = false
    @State private var windowSize: CGSize = .zero
    private let frameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var language: AppLanguage {
        AppLanguage(locale: locale)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let canvasSize = windowSize == .zero ? proxy.size : windowSize

                ZStack {
                    BambooForestBackground(activity: motion.shakeIntensity)
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .position(x: canvasSize.width * 0.5, y: canvasSize.height * 0.5)

                    CicadaToyView(
                        orbitAngle: motion.orbitAngle,
                        spinSpeedRatio: motion.spinSpeedRatio,
                        wingSpread: motion.wingSpread,
                        buzzLevel: motion.shakeIntensity
                    )
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .position(x: canvasSize.width * 0.5, y: canvasSize.height * 0.5)

                    WindowBoundsReader(size: $windowSize)
                        .frame(width: 0, height: 0)
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .ignoresSafeArea(.all)
            }
            .ignoresSafeArea(.all)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingIntroduction = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                    .accessibilityLabel(language.introductionButtonAccessibility)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .background(Color(red: 0.08, green: 0.25, blue: 0.17))
        .ignoresSafeArea(.all)
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $isShowingIntroduction) {
            CicadaIntroductionView(
                language: language,
                isPresented: $isShowingIntroduction
            )
            .presentationBackground(.clear)
        }
        .onAppear {
            startGame(wakeHaptics: true)
        }
        .onDisappear {
            stopGame()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, !isShowingIntroduction {
                UIApplication.shared.isIdleTimerDisabled = true
                buzzer.restoreAudioSession()
                haptics.prepare()
            }
        }
        .onChange(of: isShowingIntroduction) { _, isPresented in
            if isPresented {
                pauseGameForPresentation()
            } else {
                startGame(wakeHaptics: false)
            }
        }
        .onReceive(frameTimer) { _ in
            guard isGameRunning else { return }
            motion.settleMotion()
            buzzer.syncMotion(rate: motion.audioPlaybackRate, isMoving: motion.spinSpeedRatio > 0)
            if motion.spinStartPulseID != lastStartPulseID {
                lastStartPulseID = motion.spinStartPulseID
                if CicadaTuning.isMotionHapticsEnabled {
                    Task { @MainActor in
                        haptics.startPulse(intensity: motion.shakeIntensity)
                    }
                }
            }
            if motion.audioPulseID != lastAudioPulseID {
                let pulseCount = motion.audioPulseID - lastAudioPulseID
                lastAudioPulseID = motion.audioPulseID
                if CicadaTuning.isMotionHapticsEnabled {
                    Task { @MainActor in
                        haptics.phasePulse(intensity: motion.shakeIntensity, speedRatio: motion.spinSpeedRatio, count: pulseCount)
                    }
                }
                buzzer.playPulses(count: pulseCount, rate: motion.audioPlaybackRate)
            }
            if motion.frictionHapticPulseID != lastFrictionHapticPulseID {
                lastFrictionHapticPulseID = motion.frictionHapticPulseID
                if CicadaTuning.isMotionHapticsEnabled {
                    Task { @MainActor in
                        haptics.phasePulse(
                            intensity: max(motion.shakeIntensity, motion.frictionHapticLevel),
                            speedRatio: max(motion.spinSpeedRatio, motion.frictionHapticLevel),
                            count: 1
                        )
                    }
                }
            }
        }
    }

    private func startGame(wakeHaptics: Bool) {
        guard !isGameRunning else { return }
        lastAudioPulseID = 0
        lastStartPulseID = 0
        lastFrictionHapticPulseID = 0
        UIApplication.shared.isIdleTimerDisabled = true
        buzzer.start()
        buzzer.ensureAudioIsWarm()
        motion.start()
        haptics.resume()
        if wakeHaptics {
            haptics.wake()
        }
        isGameRunning = true
    }

    private func stopGame() {
        guard isGameRunning else { return }
        isGameRunning = false
        motion.stop()
        buzzer.stop()
        haptics.reset()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func pauseGameForPresentation() {
        guard isGameRunning else { return }
        isGameRunning = false
        motion.stop()
        buzzer.pauseForPresentation()
        haptics.suspend()
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
