//
//  CicadaBuzzer.swift
//  Bamboo Cicada
//

import AVFoundation
import Combine
import Foundation

enum AudioSelection: String, CaseIterable, Identifiable {
    case wawawa1
    case wawawa2

    static let storageKey = "audioSelection"

    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .wawawa1: "WawawaUnit1"
        case .wawawa2: "WawawaUnit2"
        }
    }
}

final class CicadaBuzzer: ObservableObject {
    @Published var statusText = "音频准备中"

    private static var lastPreviewPlayer: AVAudioPlayer?

    private var players: [AVAudioPlayer] = []
    private let audioQueue = DispatchQueue(label: "Bamboo Cicada Audio", qos: .userInitiated)
    private var nextPlayerIndex = 0
    private var isRunning = false
    private var hasSyncedIdle = true
    private var hasPrewarmedAudioHardware = false
    private var routeObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private let audioStartOffset: TimeInterval = 0
    private let playerPoolSize = 12
    private let coalesceQueue = DispatchQueue(label: "Bamboo Cicada Coalesce", qos: .userInitiated)
    private var pendingRate: Double = 0
    private var pendingCount: Int = 0
    private var isCoalesceScheduled = false
    private var coalesceGeneration = 0
    private var currentAudioSelection: AudioSelection {
        if let raw = UserDefaults.standard.string(forKey: AudioSelection.storageKey),
           let selection = AudioSelection(rawValue: raw) {
            return selection
        }
        return .wawawa1
    }

    static func preview(_ selection: AudioSelection) {
        guard let url = Bundle.main.url(forResource: selection.assetName, withExtension: "m4a") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.enableRate = true
            player.rate = 1.0
            player.volume = 0.8
            player.play()
            lastPreviewPlayer = player
        } catch {
            print("预览失败: \(error.localizedDescription)")
        }
    }

    func start() {
        guard !isRunning else {
            restoreAudioSession()
            return
        }
        isRunning = true

        activateAudioSession()
        installAudioObservers()

        if players.isEmpty,
           let url = Bundle.main.url(forResource: currentAudioSelection.assetName, withExtension: "m4a") {
            loadPlayers(from: url)
        } else if players.isEmpty {
            statusText = "找不到音频文件"
        }
    }

    func reload(with selection: AudioSelection) {
        let wasRunning = isRunning
        guard let url = Bundle.main.url(forResource: selection.assetName, withExtension: "m4a") else {
            statusText = "找不到音频文件"
            return
        }
        guard wasRunning else { return }
        cancelCoalescedPulses()
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.players.forEach { player in
                player.stop()
                player.currentTime = 0
            }
            self.players.removeAll()
            self.nextPlayerIndex = 0
            self.hasSyncedIdle = true
            self.hasPrewarmedAudioHardware = false
            self.loadPlayers(from: url)
            self.prewarmAudioHardware()
            self.updateStatus(triggered: false)
        }
    }

    private func loadPlayers(from url: URL) {
        do {
            players = try (0..<playerPoolSize).map { _ in
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
        hasSyncedIdle = true
        prewarmAudioHardware()
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
        guard isRunning, !hasPrewarmedAudioHardware else { return }
        hasPrewarmedAudioHardware = true

        let warmCount = CicadaTuning.audioPrewarmPlayerCount
        audioQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            for player in self.players.prefix(warmCount) {
                player.stop()
                player.currentTime = 0
                player.volume = 1
                player.prepareToPlay()
            }
        }
    }

    func ensureAudioIsWarm() {
        prewarmAudioHardware()
    }

    func stop() {
        guard isRunning else { return }
        cancelCoalescedPulses()
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.players.forEach { player in
                player.stop()
                player.currentTime = 0
                player.volume = 1
            }
        }
        nextPlayerIndex = 0
        hasSyncedIdle = true
        isRunning = false
        hasPrewarmedAudioHardware = false
        removeAudioObservers()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func pauseForPresentation() {
        guard isRunning else { return }
        hasSyncedIdle = true

        audioQueue.async { [weak self] in
            guard let self else { return }
            self.players.forEach { player in
                if player.isPlaying, player.volume > 0.02 {
                    self.fadeOut(player)
                } else {
                    player.stop()
                    player.currentTime = 0
                    player.volume = 1
                }
            }
        }
    }

    func playPulse(rate: Double) {
        scheduleCoalescedPulse(rate: rate, count: 1)
    }

    func playPulses(count: Int, rate: Double) {
        guard count > 0 else { return }
        scheduleCoalescedPulse(rate: rate, count: count)
    }

    private func scheduleCoalescedPulse(rate: Double, count: Int) {
        let normalizedRate = min(1.0, max(0.0, rate * CicadaTuning.audioPlaybackRateMultiplier))
        guard normalizedRate > 0 else { return }

        coalesceQueue.async { [weak self] in
            guard let self else { return }
            self.pendingRate = max(self.pendingRate, normalizedRate)
            self.pendingCount = max(self.pendingCount, count)
            guard !self.isCoalesceScheduled else { return }

            self.isCoalesceScheduled = true
            let captureGen = self.coalesceGeneration
            let window = CicadaTuning.audioPulseCoalesceWindow
            self.coalesceQueue.asyncAfter(deadline: .now() + window) { [weak self] in
                guard let self, captureGen == self.coalesceGeneration else { return }
                let rate = self.pendingRate
                let count = self.pendingCount
                self.pendingRate = 0
                self.pendingCount = 0
                self.isCoalesceScheduled = false
                self.audioQueue.async {
                    self.playCoalescedPulse(rate: rate, count: count)
                }
            }
        }
    }

    private func playCoalescedPulse(rate: Double, count: Int) {
        guard isRunning else { return }
        let (playbackRate, targetVolume) = clampedPlaybackRate(rate)
        let pulseCount = min(count, 8)
        for _ in 0..<pulseCount {
            guard let idx = nextAvailablePlayerIndex() else { break }
            let player = players[idx]
            player.currentTime = min(audioStartOffset, max(0, player.duration - 0.01))
            player.volume = 0
            player.rate = Float(playbackRate)
            player.play()
            player.setVolume(Float(targetVolume), fadeDuration: CicadaTuning.audioPulseFadeDuration)
            nextPlayerIndex = (idx + 1) % players.count
        }
    }

    func syncMotion(rate: Double, isMoving: Bool) {
        guard isRunning else { return }
        if isMoving {
            hasSyncedIdle = false
            return
        }
        guard !hasSyncedIdle else { return }
        hasSyncedIdle = true

        audioQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            for player in self.players {
                if player.isPlaying, player.volume > 0.02 {
                    self.fadeOut(player)
                } else {
                    player.stop()
                    player.currentTime = 0
                    player.volume = 1
                }
            }
        }
    }

    private func fadeOut(_ player: AVAudioPlayer) {
        player.setVolume(0, fadeDuration: 0.018)
        audioQueue.asyncAfter(deadline: .now() + 0.02) { [weak player] in
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

    /// 将归一化角速度 [0, 1] 映射为播放速率和音量。
    /// 曲线：log1p(curve * x) / log1p(curve)，与触感相同，保证声音和震动同步自然。
    /// 返回 (播放速率, 目标音量 0…1)
    private func clampedPlaybackRate(_ rate: Double) -> (rate: Double, volume: Double) {
        let normalized = min(1.0, max(0.0, rate * CicadaTuning.audioPlaybackRateMultiplier))
        let curve = CicadaTuning.audioLogarithmicCurve
        let mapped = log1p(curve * normalized) / log1p(curve)

        let minRate = CicadaTuning.audioMinimumPlaybackRate
        let maxRate = CicadaTuning.maximumAudioPlaybackRate
        let playbackRate = minRate + (maxRate - minRate) * mapped

        let minVol = CicadaTuning.audioMinimumVolume
        let volume = minVol + (1.0 - minVol) * mapped

        return (rate: playbackRate, volume: volume)
    }

    private func cancelCoalescedPulses() {
        coalesceGeneration += 1
        coalesceQueue.async { [weak self] in
            guard let self else { return }
            self.pendingRate = 0
            self.pendingCount = 0
            self.isCoalesceScheduled = false
        }
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
