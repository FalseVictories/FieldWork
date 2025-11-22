import Foundation

class SampleBlock {
    var previousBlock: SampleBlock?
    var nextBlock: SampleBlock?
    var numberOfFrames: UInt64 = 0
    var startFrame: UInt64 = 0
    var lastFrame: UInt64 {
        startFrame + numberOfFrames - 1
    }
    
    var reversed: Bool = false

    func data(at frame: UInt64) -> Float {
        preconditionFailure("data(at:) not implemented")
    }
    
    func cachePoint(at frame: UInt64) -> SampleChannel.CachePoint {
        preconditionFailure("cachePoint(at:) not implemented")
    }
}

extension SampleBlock {
    func appendBlock(_ block: SampleBlock) {
        nextBlock = block
        block.previousBlock = self
    }
}
