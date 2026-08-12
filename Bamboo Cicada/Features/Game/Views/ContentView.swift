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
    @StateObject private var displayLink = DisplayLinkDriver()
    @AppStorage(HapticStrength.storageKey) private var hapticStrengthRawValue = HapticStrength.medium.rawValue
    @AppStorage(CicadaBackgroundStyle.storageKey) private var backgroundStyleRawValue = CicadaBackgroundStyle.bamboo.rawValue
    @AppStorage(CicadaStyle.storageKey) private var cicadaStyleRawValue = CicadaStyle.red.rawValue
    @AppStorage(AudioSelection.storageKey) private var audioSelectionRawValue = AudioSelection.wawawa1.rawValue

    private var language: AppLanguage {
        AppLanguage(locale: locale)
    }

    private var hapticStrength: HapticStrength {
        HapticStrength(rawValue: hapticStrengthRawValue) ?? .medium
    }

    private var isHapticsActive: Bool {
        CicadaTuning.isMotionHapticsEnabled && hapticStrength != .off
    }

    private var isFrictionHapticsActive: Bool {
        CicadaTuning.isMotionHapticsEnabled && hapticStrength != .off
    }

    private var backgroundStyle: CicadaBackgroundStyle {
        CicadaBackgroundStyle(rawValue: backgroundStyleRawValue) ?? .bamboo
    }

    private var cicadaStyle: CicadaStyle {
        CicadaStyle(rawValue: cicadaStyleRawValue) ?? .red
    }

    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                let canvasSize = windowSize == .zero ? proxy.size : windowSize

                ZStack {
                    BambooForestBackground(activity: motion.shakeIntensity, style: backgroundStyle)
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .position(x: canvasSize.width * 0.5, y: canvasSize.height * 0.5)

                    CicadaToyView(
                        orbitAngle: motion.orbitAngle,
                        spinSpeedRatio: motion.spinSpeedRatio,
                        wingSpread: motion.wingSpread,
                        buzzLevel: motion.shakeIntensity,
                        style: cicadaStyle
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
        }
        .navigationViewStyle(.stack)
        .background(Color(red: 0.08, green: 0.25, blue: 0.17))
        .ignoresSafeArea(.all)
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $isShowingIntroduction) {
            CicadaIntroductionView(
                language: language,
                isPresented: $isShowingIntroduction
            )
        }
        .onAppear {
            startGame(wakeHaptics: true)
        }
        .onDisappear {
            stopGame()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active, !isShowingIntroduction {
                UIApplication.shared.isIdleTimerDisabled = true
                buzzer.restoreAudioSession()
                haptics.prepare()
            }
        }
        .onChange(of: isShowingIntroduction) { isPresented in
            if isPresented {
                pauseGameForPresentation()
            } else {
                startGame(wakeHaptics: false)
            }
        }
        .onChange(of: audioSelectionRawValue) { _ in
            buzzer.reload(with: AudioSelection(rawValue: audioSelectionRawValue) ?? .wawawa1)
        }
        .onReceive(displayLink.$tick) { _ in
            guard isGameRunning else { return }
            motion.settleMotion(frameInterval: displayLink.frameInterval)
            buzzer.syncMotion(rate: motion.normalizedAngularVelocity, isMoving: motion.spinSpeedRatio > 0)
            if motion.spinStartPulseID != lastStartPulseID {
                lastStartPulseID = motion.spinStartPulseID
                if isHapticsActive {
                    Task { @MainActor in
                        haptics.startPulse(speedRatio: motion.spinSpeedRatio, strength: hapticStrength)
                    }
                }
            }
            if motion.audioPulseID != lastAudioPulseID {
                let pulseCount = motion.audioPulseID - lastAudioPulseID
                lastAudioPulseID = motion.audioPulseID
                if isHapticsActive {
                    Task { @MainActor in
                        haptics.phasePulse(speedRatio: motion.spinSpeedRatio, count: pulseCount, strength: hapticStrength)
                    }
                }
                buzzer.playPulses(count: pulseCount, rate: motion.normalizedAngularVelocity)
            }
            if motion.frictionHapticPulseID != lastFrictionHapticPulseID {
                lastFrictionHapticPulseID = motion.frictionHapticPulseID
                if isFrictionHapticsActive {
                    Task { @MainActor in
                        haptics.phasePulse(
                            speedRatio: max(motion.spinSpeedRatio, motion.frictionHapticLevel),
                            count: 1,
                            strength: hapticStrength
                        )
                    }
                }
            }
        }
    }

    private func startGame(wakeHaptics: Bool) {
        guard !isGameRunning else { return }
        lastAudioPulseID = motion.audioPulseID
        lastStartPulseID = motion.spinStartPulseID
        lastFrictionHapticPulseID = motion.frictionHapticPulseID
        UIApplication.shared.isIdleTimerDisabled = true
        buzzer.start()
        buzzer.ensureAudioIsWarm()
        motion.start()
        displayLink.start()
        haptics.resume()
        if wakeHaptics {
            haptics.wake()
        }
        isGameRunning = true
    }

    private func stopGame() {
        guard isGameRunning else { return }
        isGameRunning = false
        displayLink.stop()
        motion.stop()
        buzzer.stop()
        haptics.reset()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func pauseGameForPresentation() {
        guard isGameRunning else { return }
        isGameRunning = false
        displayLink.stop()
        motion.pause()
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

@MainActor
private final class DisplayLinkDriver: NSObject, ObservableObject {
    @Published private(set) var tick = 0
    @Published private(set) var frameInterval: TimeInterval = 1.0 / CicadaTuning.framesPerSecond

    private var displayLink: CADisplayLink?

    func start() {
        guard displayLink == nil else { return }

        let displayLink = CADisplayLink(target: self, selector: #selector(didRefresh(_:)))
        let maximumRate = Float(UIScreen.main.maximumFramesPerSecond)
        displayLink.preferredFrameRateRange = CAFrameRateRange(
            minimum: min(60, maximumRate),
            maximum: maximumRate,
            preferred: maximumRate
        )
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    deinit {
        displayLink?.invalidate()
    }

    @objc private func didRefresh(_ displayLink: CADisplayLink) {
        let interval = displayLink.targetTimestamp - displayLink.timestamp
        frameInterval = interval > 0 ? interval : 1.0 / CicadaTuning.framesPerSecond
        tick += 1
    }
}
