//
//  AudioService.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import Foundation
import AVFoundation

final class AudioService {
    static let shared = AudioService()

    private let queue = DispatchQueue(label: "SimpleTabata.AudioService")
    private var isSessionConfigured = false
    private var soundDataCache: [String: Data] = [:]
    private var activePlayers: [AVAudioPlayer] = []
    private var volume: Float = 1
    private var duckOtherAudio = false

    private init() {
        preloadSounds()
    }
    
    func setVolume(_ value: Double) {
        let v = Float(min(1, max(0, value)))
        queue.async { [weak self] in
            guard let self else { return }
            self.volume = v
            self.activePlayers.forEach { $0.volume = v }
        }
    }
    
    func setDuckOtherAudio(_ enabled: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            self.duckOtherAudio = enabled
            self.reconfigureAudioSession()
        }
    }

    func playAlarm(title: String) {
        queue.async { [weak self] in
            guard let self else { return }
            guard let player = self.makePlayer(for: title) else { return }
            self.cleanupInactivePlayers()
            self.activePlayers.append(player)
            player.play()
        }
    }

    func playBeep() {
        playAlarm(title: "beep")
    }

    func playStart() {
        playAlarm(title: "start")
    }
    
    func playBell() {
        playAlarm(title: "bell")
    }
    
    func playTimeFinish() {
        playAlarm(title: "timeFin")
    }

    func stopSound() {
        queue.async { [weak self] in
            guard let self else { return }
            self.activePlayers.forEach { $0.stop() }
            self.activePlayers.removeAll()
        }
    }
    
    private func preloadSounds() {
        queue.async { [weak self] in
            guard let self else { return }
            _ = self.loadSoundData(for: "beep")
            _ = self.loadSoundData(for: "start")
            _ = self.loadSoundData(for: "bell")
            _ = self.loadSoundData(for: "timeFin")
        }
    }
    
    private func configureAudioSessionIfNeeded() {
        guard !isSessionConfigured else { return }
        reconfigureAudioSession()
    }
    
    private func reconfigureAudioSession() {
        do {
            let options: AVAudioSession.CategoryOptions = duckOtherAudio ? [.mixWithOthers, .duckOthers] : [.mixWithOthers]
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: options)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            isSessionConfigured = true
        } catch {
            print("Audio session error: \(error.localizedDescription)")
        }
    }
    
    private func loadSoundData(for title: String) -> Data? {
        if let cached = soundDataCache[title] {
            return cached
        }
        guard let url = Bundle.main.url(forResource: title, withExtension: "mp3") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            soundDataCache[title] = data
            return data
        } catch {
            print("Sound load error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func makePlayer(for title: String) -> AVAudioPlayer? {
        configureAudioSessionIfNeeded()
        guard let data = loadSoundData(for: title) else { return nil }
        do {
            let player = try AVAudioPlayer(data: data)
            player.volume = volume
            player.prepareToPlay()
            return player
        } catch {
            print("Sound player error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func cleanupInactivePlayers() {
        activePlayers.removeAll { !$0.isPlaying }
    }
}
