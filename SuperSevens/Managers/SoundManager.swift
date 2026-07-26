import AVFoundation
import UIKit

final class SoundManager {
    static let shared = SoundManager()

    private enum Asset {
        static let audioSubdirectory = "Audio"
        static let backgroundTrack = "background_loop"
        static let selectionTick = "selection_tick"
        static let success = "match_success"
        static let error = "error_buzz"
        static let spawn = "node_spawn"
    }

    private static let mutedKey = "superSevens_audioMuted"

    private var backgroundPlayer: AVAudioPlayer?
    private var effectPlayers: [String: AVAudioPlayer] = [:]
    private let successHaptic = UIImpactFeedbackGenerator(style: .medium)
    private var shouldPlayBackgroundMusic = false

    private(set) var isMuted: Bool = UserDefaults.standard.bool(forKey: Self.mutedKey) {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: Self.mutedKey)
            if isMuted {
                backgroundPlayer?.stop()
            } else if shouldPlayBackgroundMusic {
                startBackgroundPlayback()
            }
        }
    }

    private init() {
        successHaptic.prepare()
    }

    func toggleMute() -> Bool {
        isMuted.toggle()
        return isMuted
    }

    func playSelectionTick() {
        playEffect(named: Asset.selectionTick)
    }

    func playCorrectMatch() {
        playEffect(named: Asset.success)
        successHaptic.impactOccurred()
        successHaptic.prepare()
    }

    func playErrorBuzz() {
        playEffect(named: Asset.error)
    }

    func playNodeSpawn() {
        playEffect(named: Asset.spawn)
    }

    func playBackgroundMusic() {
        shouldPlayBackgroundMusic = true
        guard !isMuted else { return }
        startBackgroundPlayback()
    }

    func stopBackgroundMusic() {
        shouldPlayBackgroundMusic = false
        backgroundPlayer?.stop()
    }

    private func playEffect(named name: String) {
        guard !isMuted else { return }
        let player = effectPlayers[name] ?? createPlayer(named: name, loops: 0)
        effectPlayers[name] = player
        player?.currentTime = 0
        player?.play()
    }

    private func startBackgroundPlayback() {
        let player = backgroundPlayer ?? createPlayer(named: Asset.backgroundTrack, loops: -1)
        backgroundPlayer = player
        guard player?.isPlaying == false else { return }
        player?.currentTime = 0
        player?.play()
    }

    private func createPlayer(named name: String, loops: Int) -> AVAudioPlayer? {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: Asset.audioSubdirectory),
            let player = try? AVAudioPlayer(contentsOf: url)
        else {
            return nil
        }
        player.numberOfLoops = loops
        player.prepareToPlay()
        return player
    }
}
