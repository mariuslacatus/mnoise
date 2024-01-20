import Foundation
import AVFoundation
import MediaPlayer

class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine
    private var audioPlayerNode: AVAudioPlayerNode
    private var audioUnitEQ: AVAudioUnitEQ
    var freqs: [Float] = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000]

    init() {
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        audioUnitEQ = AVAudioUnitEQ(numberOfBands: 10) // 10-band EQ
        setupAudioEngine()
        setupAudioPlayer()
        setupNotifications()
    }
    
    private func setupAudioEngine() {
        // Initialize and attach nodes
        audioEngine.attach(audioPlayerNode)
        audioEngine.attach(audioUnitEQ)

        // Connect nodes
        audioEngine.connect(audioPlayerNode, to: audioUnitEQ, format: nil)
        audioEngine.connect(audioUnitEQ, to: audioEngine.mainMixerNode, format: nil)

        // Configure EQ bands
        for i in 0..<audioUnitEQ.bands.count {
            let band = audioUnitEQ.bands[i]
            band.filterType = .parametric // Set as required
            band.frequency = freqs[i]
            band.bandwidth = 1 // Example value
            band.gain = 0 // Neutral gain
            band.bypass = false
        }

        // Start the engine
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine didn't start")
        }
    }
    
    // Method to set the gain for a specific band
    func setGain(forBand band: Int, gain: Float) {
        guard band < audioUnitEQ.bands.count else { return }
        audioUnitEQ.bands[band].gain = gain
    }
    
    func initEqCurve(gains: [Float]) {
        guard gains.count == audioUnitEQ.bands.count else { return }
        
        for i in 0..<audioUnitEQ.bands.count {
            audioUnitEQ.bands[i].gain = gains[i]
        }
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
        audioPlayerNode.play()
        isPlaying = true
        setupNowPlayingInfo() // Setup Now Playing Info when audio starts
    }

    func stopAudio() {
        audioPlayerNode.pause()
        isPlaying = false
    }
    
    func setVolume(_ volume: Float) {
        audioPlayerNode.volume = (powf(100.0, volume)-1.0)/99.0
    }
    
    // Add a method to set the audio file
    func setAudioFile(_ fileName: String) {
        currentFileName = fileName // Set the current file name
        
        if let path = Bundle.main.path(forResource: fileName, ofType: "wav") {
            let url = URL(fileURLWithPath: path)

            do {
                let audioFile = try AVAudioFile(forReading: url)
                let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: UInt32(audioFile.length))!
                try! audioFile.read(into: audioFileBuffer)
                
                audioPlayerNode.stop()
                audioPlayerNode.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: nil)
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
