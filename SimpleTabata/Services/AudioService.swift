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

    private var audioPlayer: AVAudioPlayer?

    private init() {}

    func playAlarm(title: String) {
        guard let url = Bundle.main.url(forResource: title, withExtension: "mp3") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Sound error: \(error.localizedDescription)")
        }
    }

    func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
