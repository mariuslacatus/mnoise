import SwiftUI

struct VerticalSlider: View {
    @Binding var gains:[Float]
    @ObservedObject var audioPlayerViewModel: AudioPlayerViewModel
    var band:Int
    var sliderHeight:CGFloat

    var body: some View {
        Slider(value: Binding(
            get: { self.gains[band] },
            set: { newValue in
                gains[band] = newValue
                audioPlayerViewModel.setGain(forBand: band, gain: newValue)
                UserDefaults.standard.set(gains, forKey: "MNEqCurve")
            }
        ), in: -24...24).rotationEffect(.degrees(-90.0), anchor: .topLeading)
        .frame(width: sliderHeight)
        .offset(y: sliderHeight)
        .onTapGesture(count:2) {
            handleDoubleTap(band: band)
        }

    }
    func handleDoubleTap(band: Int) {
        gains[band] = 0
        audioPlayerViewModel.setGain(forBand: band, gain: gains[band])
        UserDefaults.standard.set(gains, forKey: "MNEqCurve")
    }
}

struct VerticalBar: View {
    @Binding var gains:[Float]
    @ObservedObject var audioPlayerViewModel: AudioPlayerViewModel
    var band:Int

    var body: some View {
        VStack {
            GeometryReader { geo in
                VerticalSlider(
                    gains: self.$gains,
                    audioPlayerViewModel: self.audioPlayerViewModel,
                    band: self.band,
                    sliderHeight: geo.size.height
                )
            }
            Text(getBandName(band: band))
                .font(.system(size: 8))
                .frame(height: 10)
                .padding(.bottom)
            
        }
    }
    
    private func getBandName(band: Int) -> String {
        let bandFrequency: Int = Int(audioPlayerViewModel.freqs[band])
        if (bandFrequency >= 1000) {
            return String(Float(bandFrequency)/1000)+"K"
        }
        else {
            return String(bandFrequency)
        }
    }
    

}

struct ContentView: View {
    @StateObject private var audioPlayerViewModel = AudioPlayerViewModel()
    let sounds: [String] = ["WhiteNoise1", "Falls1"]
    @State private var selectedSound: String
    @State private var volume: Float
    @State var gains: [Float] = UserDefaults.standard.object(forKey: "MNEqCurve") as? [Float] ?? Array(repeating: 0.0, count: 10)
    
    init() {
        selectedSound = UserDefaults.standard.string(forKey: "MNSelectedSound") ?? sounds[0]
        let v = UserDefaults.standard.float(forKey: "MNVolume")
        volume = v != 0 ? v : 0.5
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
            
            HStack() {
                ForEach(0..<10, id: \.self) { band in
                    VerticalBar(gains:self.$gains, audioPlayerViewModel: audioPlayerViewModel, band: band)
                }
            }
            Slider(value: $volume, in: 0...1, step: 0.01)
                .onChange(of: volume) {
                    audioPlayerViewModel.setVolume(volume)
                    UserDefaults.standard.set(volume, forKey: "MNVolume") // Save the volume
                }
        }
        .padding()
        .onAppear {
            if audioPlayerViewModel.isPlaying {
                audioPlayerViewModel.stopAudio()
            }
            audioPlayerViewModel.setAudioFile(selectedSound)
            audioPlayerViewModel.setVolume(volume)
            audioPlayerViewModel.initEqCurve(gains: gains)
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
        audioPlayerViewModel.setVolume(volume)
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
