import SwiftUI

struct ContentView: View {
    @StateObject private var audioPlayerViewModel = AudioPlayerViewModel()
    let sounds: [String] = ["WhiteNoise1", "Falls1"]
    @State private var selectedSound: String
    @State private var volume: Float = UserDefaults.standard.float(forKey: "MNVolume") != 0 
        ? UserDefaults.standard.float(forKey: "MNVolume") : 0.5

    
    init() {
        selectedSound = UserDefaults.standard.string(forKey: "MNSelectedSound") ?? sounds[0]
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Picker("Select Sound", selection: $selectedSound) {
                ForEach(sounds, id: \.self) {
                    Text($0).tag($0)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedSound) {
                UserDefaults.standard.set(selectedSound, forKey: "MNSelectedSound")
                updateSound()
            }
            
            Button(action: togglePlayback) {
                Image(systemName: audioPlayerViewModel.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
            }
            
            Slider(value: $volume, in: 0...1, step: 0.01)
                .onChange(of: volume) {
                    audioPlayerViewModel.setVolume((powf(100.0, volume)-1.0)/99.0)
                    UserDefaults.standard.set((powf(100.0, volume)-1.0)/99.0, forKey: "MNVolume") // Save the volume
                }
        }
        .padding()
        .onAppear {
            if audioPlayerViewModel.isPlaying {
                audioPlayerViewModel.stopAudio()
            }
            audioPlayerViewModel.setAudioFile(selectedSound)
            audioPlayerViewModel.playAudio()
        }
    }

    private func togglePlayback() {
        if audioPlayerViewModel.isPlaying {
            audioPlayerViewModel.stopAudio()
        } else {
            audioPlayerViewModel.playAudio()
        }
    }
    
    private func updateSound() {
        audioPlayerViewModel.setAudioFile(selectedSound)
        if audioPlayerViewModel.isPlaying {
            audioPlayerViewModel.stopAudio()
            audioPlayerViewModel.playAudio()
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
