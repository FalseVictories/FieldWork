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
    public var currentOperation: SampleOperation?
    
    public var channels: [SampleChannel] = []
    public var numberOfFrames: UInt64 {
        channels.first?.numberOfFrames ?? 0
    }
    
    public var bitDepth: Int = 0
    public var sampleRate: Double = 0
    public var isLoaded: Bool { !channels.isEmpty }
    
    let sampleBlockFactory: any SampleBlockFactory
    public convenience init() {
        self.init(withSampleBlockFactory: DefaultSampleBlockFactory())
    }
    
    init(withSampleBlockFactory blockFactory: some SampleBlockFactory) {
        sampleBlockFactory = blockFactory
    }
}

extension Sample {
    public func loadSample(from url: URL, withAudioLoader audioLoader: some AudioLoader) async throws {
        let operation = SampleOperation(title: "Loading Sample")
        currentOperation = operation
        
        if let loadResult = try await (audioLoader.importSample(from: url, operation: operation) {
            SampleChannel(withSampleBlockFactory: self.sampleBlockFactory)
        }) {
            self.channels = loadResult.channels
            self.bitDepth = loadResult.bitDepth
            self.sampleRate = loadResult.sampleRate
            
            currentOperation = nil
        }
    }
}
