import SwiftUI

struct ContentView: View {
    @StateObject private var audioPlayerViewModel = AudioPlayerViewModel()
    @State private var selectedSound: String = UserDefaults.standard.string(forKey: "MNSelectedSound") ?? "WhiteNoise1"

    var body: some View {
        VStack(spacing: 40) {
            Picker("Select Sound", selection: $selectedSound) {
                Text("WhiteNoise1").tag("WhiteNoise1")
                Text("Falls1").tag("Falls1")
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
