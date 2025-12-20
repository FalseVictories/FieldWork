import Marlin
import MarlinKit
import SwiftUI

struct ContentView: View {
    static let sampleUrl = Bundle.main.url(forResource: "new-cascadia", withExtension: "flac")!
    @State var sample: Sample
    @State var text: String = ""
    @State var framesPerPixel: UInt = 256
    
    init() {
        let s = Sample()
        _sample = .init(initialValue: s)
    }
    
    var body: some View {
        VStack {
            if !sample.isLoaded && sample.currentOperation == nil {
                Button("Load Sample") {
                    Task {
                        try await sample.loadSample(from: Self.sampleUrl,
                                                    withAudioLoader: AVAudioLoader())
                    }
                }
            }
            
            if let operation = sample.currentOperation {
                ProgressView(operation.title ?? "",
                             value: operation.progress, total: 1.0)
            }
            
            if sample.isLoaded {
                ScrollView(.horizontal) {
                    SampleView(sample: sample, framesPerPixel: $framesPerPixel)
                }
                
                HStack {
                    Button("Zoom In") {
                        framesPerPixel /= 2
                    }
                    
                    Button("Zoom Out") {
                        framesPerPixel *= 2
                    }
                }
                
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

//#Preview {
//    ContentView()
//}
