import Foundation
import OSLog

extension Logger {
    static let sampleChannel = Logger(subsystem: "com.falsevictories.FieldWork", category: "SampleChannel")
}

enum SampleChannelError: Error {
    case invalidLastBlock
}

public class SampleChannel {
    public struct CachePoint: Sendable, Equatable {
        static let samplesPerCachePoint: Int = 256
        public static let zero: CachePoint = .init(minValue: 0, maxValue: 0, avgMinValue: 0, avgMaxValue: 0)
        
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
    
    private var sortedBlocks: [SampleBlock] = []
    
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
    
    func sampleBlockForFrame(_ frame: UInt64) -> SampleBlock? {
        if frame >= numberOfFrames {
            Logger.sampleChannel.error("Requested sample block for frame \(frame), but only \(self.numberOfFrames) available")
            return nil
        }

        guard let firstBlock, let lastBlock else {
            return nil
        }
        
        // Shortcut the binary search as these blocks are probably more popular
        // and binary search would fail to find them quickly
        if firstBlock.contains(frame) {
            return firstBlock
        }
        
        if lastBlock.contains(frame) {
            return lastBlock
        }
        
        // Binary search over sorted blocks
        var left = 0, right = sortedBlocks.count - 1
        
        while right >= left {
            let middle = right - left / 2
            let block = sortedBlocks[middle]
            
            if block.contains(frame) {
                return block
            } else if block.startFrame > frame {
                right = middle - 1
            } else if block.lastFrame < frame {
                left = middle + 1
            }
        }
        
        Logger.sampleChannel.error("Requested sample block for frame \(frame) but couldn't find it")
        fatalError()
    }
}

private extension SampleChannel {
    private func appendBlock(_ block: SampleBlock) throws {
        sortedBlocks.append(block)

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
