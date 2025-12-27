import Marlin
import MarlinKit
import SwiftUI

struct ContentView: View {
    static let sampleUrl = Bundle.main.url(forResource: "new-cascadia", withExtension: "flac")!
    @State var sample: Sample?
    @State var text: String = ""
    @State var framesPerPixel: UInt = 256
    @State var caretPosition: UInt64 = 0
    
    @FocusState var sampleViewFocus
    
    init() {
        let s = Sample()
        _sample = .init(initialValue: s)
    }
    
    var body: some View {
        VStack {
            if let sample, !sample.isLoaded && sample.currentOperation == nil {
                Button("Load Sample") {
                    Task {
                        try await sample.loadSample(from: Self.sampleUrl,
                                                    withAudioLoader: AVAudioLoader())
                    }
                }
            }
            
            if let operation = sample?.currentOperation {
                ProgressView(operation.title ?? "",
                             value: operation.progress, total: 1.0)
            }
            
            if let sample, sample.isLoaded {
                SampleView(sample: sample,
                           framesPerPixel: $framesPerPixel,
                           caretPosition: $caretPosition)
                    .focused($sampleViewFocus)
                    .onAppear {
                        sampleViewFocus = true
                    }
                
                HStack {
                    Button("Zoom In") {
                        let newFramesPerPixel = framesPerPixel / 2
                        framesPerPixel = newFramesPerPixel < 1 ? 1 : newFramesPerPixel
                    }
                    
                    Button("Zoom Out") {
                        framesPerPixel *= 2
                    }
                    
                    Spacer()
                    Text("\(caretPosition) - Frames Per Pixel: \(framesPerPixel)")
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
