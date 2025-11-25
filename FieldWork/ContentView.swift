import Marlin
import SwiftUI

struct ContentView: View {
    static let sampleUrl = URL(filePath: "/Users/iain/Music/hidden.flac")
    @State var sample: Sample
    @State var text: String = ""
    
    init() {
        let s = Sample()
        _sample = .init(initialValue: s)
    }
    
    var body: some View {
        VStack {
            Button("Load Sample") {
                Task {
                    try await sample.loadSample(from: Self.sampleUrl,
                                                withAudioLoader: AVAudioLoader())
                }
            }
            
            if let operation = sample.currentOperation {
                ProgressView(operation.title ?? "",
                             value: operation.progress, total: 1.0)
            }
            
            if sample.numberOfFrames > 0 {
                Text("Filename: \(Self.sampleUrl.lastPathComponent)")
                Text("Channels: \(sample.channels.count == 1 ? "Mono" : "Stereo")")
                Text("Number of Frames: \(sample.numberOfFrames)")
                Text("Sample Rate: \(Int(sample.sampleRate))")
                Text("Bit Depth: \(sample.bitDepth)")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
