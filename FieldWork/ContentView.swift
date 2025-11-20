import Marlin
import SwiftUI

struct ContentView: View {
    static let sampleUrl = URL(filePath: "/Users/iain/Music/Logic/Bounces/example-right-channel-stereo.wav")
    @State var sample: Sample
    
    init() {
        if let s = Sample() {
            _sample = .init(initialValue: s)
        } else {
            fatalError()
        }
    }
    
    var body: some View {
        VStack {
            Button("Load Sample") {
                print("Loading sample")
                sample.loadSample(from: Self.sampleUrl,
                                  withAudioLoader: AVAudioLoader())
                print("Sample loaded")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
