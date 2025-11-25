import Foundation

class SampleBlock {
    protocol Methods: AnyObject {
        func getData(at frame: UInt64) -> Float
        func getCachePoint(at frame: UInt64) -> SampleChannel.CachePoint
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
    func data(at frame: UInt64) -> Float {
        guard let methods else {
            preconditionFailure("methods not set")
        }
        
        return methods.getData(at: reversed ? reversedFrame(frame) : frame)
    }
    
    func cachePoint(at frame: UInt64) -> SampleChannel.CachePoint {
        guard let methods else {
            preconditionFailure("methods not set")
        }

        return methods.getCachePoint(at: reversed ? reversedCachePointIndex(frame) : frame)
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
