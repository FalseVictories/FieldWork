import Foundation
import OSLog

extension Logger {
    static let sampleChannel = Logger(subsystem: "com.falsevictories.FieldWork", category: "SampleChannel")
}

enum SampleChannelError: Error {
    case invalidLastBlock
}

public class SampleChannel {
    public struct CachePoint {
        static let samplesPerCachePoint: Int = 256
        
        public let minValue: Float
        public let maxValue: Float
        public let avgMinValue: Float
        public let avgMaxValue: Float
    }
    
    public var channelName: String = ""
    
    var firstBlock: SampleBlock?
    var lastBlock: SampleBlock?
    var blockCount: UInt32 = 0
    var numberOfFrames: UInt64 = 0
    
    // Factory used when creating a block from data
    let blockFactory: any SampleBlockFactory
    
    init(withSampleBlockFactory blockFactory: any SampleBlockFactory) {
        self.blockFactory = blockFactory
    }
}

extension SampleChannel {
    func appendData(_ data: UnsafeBufferPointer<Float>) throws {
        Logger.sampleChannel.debug("Appending \(data.count) samples")
        let block = try blockFactory.createSampleBlock(for: data)
        try appendBlock(block)
    }

    private func appendBlock(_ block: SampleBlock) throws {
        // If this is the very first block, start the list
        if firstBlock == nil {
            firstBlock = block
            lastBlock = block
            blockCount = 1
            numberOfFrames = block.numberOfFrames
            block.startFrame = 0
            
            return
        }
        
        guard let lastBlock else {
            throw SampleChannelError.invalidLastBlock
        }
        
        lastBlock.appendBlock(block)
        self.lastBlock = block
        block.startFrame = numberOfFrames
        numberOfFrames += block.numberOfFrames
    }
}
