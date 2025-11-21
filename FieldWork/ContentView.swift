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
                sample.loadSample(from: Self.sampleUrl,
                                  withAudioLoader: AVAudioLoader())
            }
            
            if let operation = sample.currentOperation {
                ProgressView(operation.title ?? "",
                             value: operation.progress, total: 1.0)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
