//
//  PreviewPlayer.swift
//  SoundScapeSocial
//
//  Created by Enzo Arantes on 4/25/25.

import Foundation
import AVFoundation

class PreviewPlayer {
    static let shared = PreviewPlayer()
    private var player: AVPlayer?

    private init() {

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session setup failed: \(error)")
        }
    }

    func play(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("⚠️ Invalid preview URL: \(urlString)")
            return
        }
        stop()

        player = AVPlayer(url: url)
        player?.play()
        print("▶️ Playing preview: \(urlString)")
    }

    func stop() {
        player?.pause()
        player = nil
    }
}

