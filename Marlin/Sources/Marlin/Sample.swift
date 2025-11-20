import AVFoundation
import Foundation
import OSLog

extension Logger {
    static let sample = Logger(subsystem: "com.falsevictories.FieldWork", category: "Sample")
}

enum SampleError: Error {
    case noChannelData
}

@Observable
@MainActor
final public class Sample {
    var currentOperation: SampleOperation?
    
    var channels: [SampleChannel] = []
    
    let sampleBlockFactory: any SampleBlockFactory
    public init?() {
        do {
            sampleBlockFactory = try DefaultSampleBlockFactory()
        } catch {
            return nil
        }
    }
    
    init(withSampleBlockFactory blockFactory: some SampleBlockFactory) {
        sampleBlockFactory = blockFactory
    }
}

extension Sample {
    public func loadSample(from url: URL, withAudioLoader audioLoader: some AudioLoader) {
        currentOperation = SampleOperation(title: "Loading Sample")
        Task { [weak self] in
            guard let self else {
                return
            }
            
            let newChannels = try await audioLoader.importSample(from: url) {
                SampleChannel(withSampleBlockFactory: self.sampleBlockFactory)
            }
            self.channels = newChannels
        }
    }
}
