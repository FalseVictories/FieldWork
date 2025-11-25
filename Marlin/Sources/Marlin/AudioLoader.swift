import Foundation
import OSLog

extension Logger {
    static let audioLoader = Logger(subsystem: "com.falsevictories.fieldwork", category: "AudioLoader")
}

public struct AudioLoaderResult {
    let bitDepth: Int
    let sampleRate: Double
    let channels: [SampleChannel]
}

public protocol AudioLoader {
    typealias ChannelBuilder = @Sendable () throws -> SampleChannel
    
    nonisolated(nonsending)
    func importSample(from url: URL,
                      operation: SampleOperation,
                      channelBuilder: ChannelBuilder) async throws -> AudioLoaderResult?
}
