import Foundation
import OSLog

extension Logger {
    static let channelIter = Logger(subsystem: "com.falsevictories.FieldWork", category: "ChannelIter")
}

public struct SampleChannelIterator {
    var currentBlock: SampleBlock?
    var frameInBlock: UInt64 = 0
    var cachePointInBlock: UInt64 = 0
    
    init?(atFrame frame: UInt64, inChannel channel: SampleChannel) {
        guard let currentBlock = channel.sampleBlockForFrame(frame) else {
            Logger.channelIter.error("no block for \(frame)")
            return nil
        }
        
        self.currentBlock = currentBlock
        frameInBlock = frame - currentBlock.startFrame
        cachePointInBlock = frameInBlock / UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
    }
}

public extension SampleChannelIterator {
    var hasMoreData: Bool {
        currentBlock != nil
    }
    
    mutating func nextFrameAndAdvance() -> Float? {
        guard let currentBlock else {
            return nil
        }
        
        let value = currentBlock.data(atFrame: frameInBlock)
        frameInBlock += 1
        cachePointInBlock = frameInBlock / UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
        
        if frameInBlock >= UInt64(currentBlock.numberOfFrames) {
            self.currentBlock = currentBlock.nextBlock
            frameInBlock = 0
            cachePointInBlock = 0
        }
        return value
    }
    
    mutating func nextCachePointAndAdvance() -> SampleChannel.CachePoint? {
        guard let currentBlock else {
            return nil
        }
        
        let value = currentBlock.cachePoint(atFrame: frameInBlock)
        cachePointInBlock += 1
        frameInBlock = cachePointInBlock * UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
        
        if frameInBlock >= UInt64(currentBlock.numberOfFrames) {
            self.currentBlock = currentBlock.nextBlock
            frameInBlock = 0
            cachePointInBlock = 0
        }
        
        return value
    }
}
