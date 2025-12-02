import Foundation
import OSLog

extension Logger {
    static let channelIter = Logger(subsystem: "com.falsevictories.FieldWork", category: "ChannelIter")
}

public struct SampleChannelIterator {
    var currentBlock: SampleBlock?
    var frameInBlock: UInt64 = 0
    var cachePointInBlock: UInt64 = 0
    
    public init?(atFrame frame: UInt64, inChannel channel: SampleChannel) {
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
    
    mutating func frameAndAdvance() -> Float? {
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
    
    func peekFrame() -> Float {
        currentBlock?.data(atFrame: frameInBlock) ?? 0
    }
    
    func peekNextFrame() -> Float {
        guard let currentBlock else {
            return 0
        }
        
        let nextFrameInBlock = frameInBlock + 1
        if nextFrameInBlock < UInt64(currentBlock.numberOfFrames) - 1 {
            return currentBlock.data(atFrame: nextFrameInBlock)
        }
        
        return currentBlock.nextBlock?.data(atFrame: 0) ?? 0
    }
    
    mutating func pixelCachePointAndAdvance(forFramesPerPixel fpp: UInt) -> SampleChannel.CachePoint? {
        guard let currentBlock else {
            return nil
        }
        
        if fpp < SampleChannel.CachePoint.samplesPerCachePoint {
            return generateCachePoint(fromFramesPerPixel: fpp)
        } else {
            let cachePointsPerPixel = fpp / UInt(SampleChannel.CachePoint.samplesPerCachePoint)
            return generateCachePoint(fromCachePointsPerPixel: cachePointsPerPixel)
        }
    }
}

private extension SampleChannelIterator {
    private mutating func generateCachePoint(fromFramesPerPixel fpp: UInt) -> SampleChannel.CachePoint {
        var framesReadAbove: UInt = 0
        var framesReadBelow: UInt = 0
        var totalAbove: Float = 0
        var totalBelow: Float = 0
        var maxValue: Float = 0
        var minValue: Float = 0
        
        var i: UInt = 0
        while i < fpp {
            guard let value = frameAndAdvance() else {
                break
            }
            
            maxValue = max(value, maxValue)
            minValue = min(value, minValue)
            
            if value > 0 {
                totalAbove += value
                framesReadAbove += 1
            } else if value < 0 {
                totalBelow += value
                framesReadBelow += 1
            }
            
            i += 1
        }
        
        var avgAbove: Float = 0
        var avgBelow: Float = 0
        
        if i != 0 {
            avgAbove = framesReadAbove == 0 ? 0 : totalAbove / Float(framesReadAbove)
            avgBelow = framesReadBelow == 0 ? 0 : totalBelow / Float(framesReadBelow)
        }

        return .init(minValue: minValue, maxValue: maxValue,
                     avgMinValue: avgBelow, avgMaxValue: avgAbove)
    }
    
    private mutating func generateCachePoint(fromCachePointsPerPixel cppp: UInt) -> SampleChannel.CachePoint {
        var maxValue: Float = 0
        var minValue: Float = 0
        var totalAbove: Float = 0
        var totalBelow: Float = 0
        
        var i: UInt = 0
        while i < cppp {
            guard let cp = nextCachePointAndAdvance() else {
                break
            }
            
            maxValue = max(cp.maxValue, maxValue)
            minValue = min(cp.minValue, minValue)
            totalAbove += cp.avgMaxValue
            totalBelow += cp.avgMinValue
            
            i += 1
        }

        return i == 0 ? .zero : .init(minValue: minValue,
                                      maxValue: maxValue,
                                      avgMinValue: totalBelow / Float(i),
                                      avgMaxValue: totalAbove / Float(i))
    }
}
