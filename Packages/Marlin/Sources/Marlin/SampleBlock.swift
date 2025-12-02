import Foundation

class SampleBlock {
    protocol Methods: AnyObject {
        func getData(atFrame frame: UInt64) -> Float
        func getCachePoint(atCachePoint cachePoint: UInt64) -> SampleChannel.CachePoint
    }
    
    var previousBlock: SampleBlock?
    var nextBlock: SampleBlock?
    var numberOfFrames: UInt64 = 0
    var startFrame: UInt64 = 0
    var lastFrame: UInt64 {
        startFrame + numberOfFrames - 1
    }
    
    var reversed: Bool = false
    
    weak var methods: Methods?
}

extension SampleBlock {
    func contains(_ frame: UInt64) -> Bool {
        frame >= startFrame && frame <= lastFrame
    }
    
    /// Get the data in the block at the frame position
    /// - Parameter frame: the frame position relative to the start of the block
    /// - Returns: the float data at that frame
    func data(atFrame frame: UInt64) -> Float {
        guard let methods else {
            preconditionFailure("methods not set")
        }
        
        return methods.getData(atFrame: reversed ? reversedFrame(frame) : frame)
    }
    
    /// Get the CachePoint data in the block at the frame position
    /// - Parameter frame: the frame position relative to the start of the block
    /// - Returns: the CachePoint data at that frame
    func cachePoint(atFrame frame: UInt64) -> SampleChannel.CachePoint {
        guard let methods else {
            preconditionFailure("methods not set")
        }

        return methods.getCachePoint(atCachePoint: reversed ? reversedCachePointIndex(frame) :
                                        frame / UInt64(SampleChannel.CachePoint.samplesPerCachePoint))
    }
    
    /// Add a block after this block, inserting it if this block isn't the end of the list
    /// - Parameter block: block to be appended
    func appendBlock(_ block: SampleBlock) {
        let oldNextBlock = nextBlock
        
        nextBlock = block
        block.previousBlock = self
        block.nextBlock = oldNextBlock
        if let oldNextBlock {
            oldNextBlock.previousBlock = block
        }
    }
}

private extension SampleBlock {
    func reversedFrame(_ frame: UInt64) -> UInt64 {
        (numberOfFrames - 1) - frame
    }
    
    // 44100 = 173 cache pts: 0...172
    // 68 extra frames
    // 0...67 == 0 => 172
    // 68...44099 => 0...44031 => 171...0
    func reversedCachePointIndex(_ frame: UInt64) -> UInt64 {
        // There will be an extra cachepoint at the end of the buffer if numberOfFrames is not
        // a multiple of samplesPerCachePoint, so first check if the frame is part of that
        // extra cachepoint
        let extraFrames = numberOfFrames % UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
        if frame < extraFrames {
            return numberOfFrames / UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
        }
        
        return ((numberOfFrames - 1) - frame) / UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
    }
}
