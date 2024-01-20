import Foundation
import AVFoundation
import MediaPlayer

class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?

    init() {
        setupAudioPlayer()
        setupNotifications()
    }
    
    private var currentFileName: String = "" {
        didSet {
            setupNowPlayingInfo()
        }
    }

    private func setupAudioPlayer() {
        do {
            // Set the audio session category to playback
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print("Failed to set audio session category.")
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                  return
              }

        if type == .began {
            // Interruption began, pause audio
            stopAudio()
        } else if type == .ended {
            // Interruption ended, resume audio
            playAudio()
        }
    }

    func playAudio() {
        audioPlayer?.play()
        isPlaying = true
        setupNowPlayingInfo() // Setup Now Playing Info when audio starts
    }

    func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = (powf(100.0, volume)-1.0)/99.0
    }
    
    // Add a method to set the audio file
    func setAudioFile(_ fileName: String) {
        currentFileName = fileName // Set the current file name
        
        if let path = Bundle.main.path(forResource: fileName, ofType: "wav") {
            let url = URL(fileURLWithPath: path)

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
            } catch {
                print("Error loading the audio file: \(fileName)")
            }
        }
    }
    
    // Call this method when audio starts playing
    private func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentFileName

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        // Setup remote command center to respond to play/pause
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [unowned self] event in
            // Handle play command
            playAudio()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            // Handle pause command
            stopAudio()
            return .success
        }
    }
}
