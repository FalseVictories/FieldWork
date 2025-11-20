import Foundation

protocol SampleBlockFactory: Sendable {
    func createSampleBlock(for data: UnsafeBufferPointer<Float>) throws -> SampleBlock
}

final class DefaultSampleBlockFactory: SampleBlockFactory {
    private let dataFile: CacheFile<Float>
    private let cachePointFile: CacheFile<SampleChannel.CachePoint>

    init() throws {
        dataFile = try CacheFile<Float>.createCacheFile(withExtension: "data")
        cachePointFile = try CacheFile<SampleChannel.CachePoint>.createCacheFile(withExtension: "cache")
    }
    
    func createSampleBlock(for data: UnsafeBufferPointer<Float>) throws -> SampleBlock {
        return try FileSampleBlock(data: data,
                                   dataCacheFile: dataFile,
                                   cachePointFile: cachePointFile)
    }
}
