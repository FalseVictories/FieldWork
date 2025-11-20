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
    
    public init() {
    }
}

extension Sample {
    public func loadSample(from url: URL, withAudioLoader audioLoader: some AudioLoader) {
        currentOperation = SampleOperation(title: "Loading Sample")
        Task { [weak self] in
            guard let self else {
                return
            }
            
            let newChannels = try await audioLoader.importSample(from: url)
            self.channels = newChannels
        }
    }
}
