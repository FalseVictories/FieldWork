import Foundation
import OSLog

extension Logger {
    static let audioLoader = Logger(subsystem: "com.falsevictories.fieldwork", category: "AudioLoader")
}

public protocol AudioLoader {
    func importSample(from url: URL) async throws -> [SampleChannel]
}
