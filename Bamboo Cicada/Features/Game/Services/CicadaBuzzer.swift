//
//  CicadaBuzzer.swift
//  Bamboo Cicada
//

import AVFoundation
import Combine
import Foundation

final class CicadaBuzzer: ObservableObject {
    @Published var statusText = "音频准备中"

    private var players: [AVAudioPlayer] = []
    private var nextPlayerIndex = 0
    private var isRunning = false
    private var routeObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private let audioStartOffset: TimeInterval = 0

    func start() {
        guard !isRunning else {
            restoreAudioSession()
            return
        }
        isRunning = true

        activateAudioSession()
        installAudioObservers()

        if players.isEmpty,
           let url = Bundle.main.url(forResource: "WawawaUnit", withExtension: "m4a") {
            do {
                players = try (0..<18).map { _ in
                    let audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer.numberOfLoops = 0
                    audioPlayer.enableRate = true
                    audioPlayer.rate = 1
                    audioPlayer.volume = 1
                    audioPlayer.prepareToPlay()
                    return audioPlayer
                }
                prewarmAudioHardware()
                updateStatus(triggered: false)
            } catch {
                statusText = "音频加载失败: \(error.localizedDescription)"
            }
        } else if players.isEmpty {
            statusText = "找不到音频文件"
        }
    }

    func restoreAudioSession() {
        guard isRunning else {
            start()
            return
        }

        activateAudioSession()
        installAudioObservers()
        players.forEach { player in
            player.volume = 1
            player.prepareToPlay()
        }
        updateStatus(triggered: false)
    }

    private func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
            try session.setPreferredSampleRate(44_100)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            statusText = "音频恢复失败: \(error.localizedDescription)"
        }
    }

    private func prewarmAudioHardware() {
        players.forEach { player in
            player.volume = 0
            player.currentTime = 0
            player.play()
            player.stop()
            player.currentTime = 0
            player.volume = 1
            player.prepareToPlay()
        }
    }

    func stop() {
        guard isRunning else { return }
        players.forEach { player in
            player.stop()
            player.currentTime = 0
            player.volume = 1
        }
        nextPlayerIndex = 0
        isRunning = false
        removeAudioObservers()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func playPulse(rate: Double) {
        guard isRunning, let playerIndex = nextAvailablePlayerIndex() else { return }

        let player = players[playerIndex]
        let playbackRate = clampedPlaybackRate(rate)
        player.currentTime = min(audioStartOffset, max(0, player.duration - 0.01))
        player.volume = 1
        player.rate = Float(playbackRate)
        player.play()
        nextPlayerIndex = (playerIndex + 1) % players.count
    }

    func playPulses(count: Int, rate: Double) {
        guard count > 0 else { return }

        for _ in 0..<min(count, 8) {
            playPulse(rate: rate)
        }
    }

    func syncMotion(rate: Double, isMoving: Bool) {
        guard isRunning, !isMoving else { return }
        for player in players {
            if player.isPlaying, player.volume > 0.02 {
                fadeOut(player)
            } else {
                player.stop()
                player.currentTime = 0
                player.volume = 1
            }
        }
    }

    private func fadeOut(_ player: AVAudioPlayer) {
        player.setVolume(0, fadeDuration: 0.018)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak player] in
            guard let player, player.volume <= 0.02 else { return }
            player.stop()
            player.currentTime = 0
            player.volume = 1
        }
    }

    private func nextAvailablePlayerIndex() -> Int? {
        guard !players.isEmpty else { return nil }

        for offset in 0..<players.count {
            let index = (nextPlayerIndex + offset) % players.count
            if !players[index].isPlaying {
                return index
            }
        }
        return nil
    }

    private func clampedPlaybackRate(_ rate: Double) -> Double {
        let multipliedRate = rate * CicadaTuning.audioPlaybackRateMultiplier
        return min(CicadaTuning.maximumAudioPlaybackRate, max(0.5, multipliedRate))
    }

    private func resumeAfterInterruption() {
        restoreAudioSession()
    }

    private func installAudioObservers() {
        guard routeObserver == nil, interruptionObserver == nil else { return }

        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            self?.restoreAudioSession()
        }

        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if typeValue == AVAudioSession.InterruptionType.ended.rawValue {
                self.resumeAfterInterruption()
            } else {
                self.statusText = "音频被系统中断"
            }
        }
    }

    private func removeAudioObservers() {
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        routeObserver = nil
        interruptionObserver = nil
    }

    private func updateStatus(triggered: Bool = false) {
        let route = AVAudioSession.sharedInstance().currentRoute.outputs
            .map { output in
                if output.portName.isEmpty {
                    return output.portType.rawValue
                }
                return output.portName
            }
            .joined(separator: ", ")
        let output = route.isEmpty ? "无输出" : route
        let playing = players.contains { $0.isPlaying } ? "哇声播放中" : "待触发"
        let nextStatus = "\(triggered ? "每半圈一次" : playing) 100% · \(output)"
        if statusText != nextStatus {
            statusText = nextStatus
        }
    }

    deinit {
        removeAudioObservers()
    }
}
