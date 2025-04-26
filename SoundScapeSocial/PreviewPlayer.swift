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
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session setup failed: \(error)")
        }
    }

    /// Play a 30-second preview from the given URL string
    func play(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("⚠️ Invalid preview URL: \(urlString)")
            return
        }
        // Stop any current playback
        stop()

        // Create and start the AVPlayer
        player = AVPlayer(url: url)
        player?.play()
        print("▶️ Playing preview: \(urlString)")
    }

    /// Stop playback and release resources
    func stop() {
        player?.pause()
        player = nil
    }
}

