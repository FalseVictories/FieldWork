import Foundation
import Testing
@testable import Marlin

@MainActor
@Test func testMoreData() throws {
    let testSample = try makeTestSample()
    
    let iter = SampleChannelIterator(atFrame: 0, inChannel: testSample.channels[0])
    #expect(iter != nil)
    
    if let iter {
        #expect(iter.hasMoreData)
    }
    
    let iter2 = SampleChannelIterator(atFrame: 44099, inChannel: testSample.channels[0])
    #expect(iter2 != nil)
    
    if var iter2 {
        #expect(iter2.hasMoreData)
        
        _ = iter2.frameAndAdvance()
        
        #expect(!iter2.hasMoreData)
        
        #expect(iter2.frameAndAdvance() == nil)
    }
    
    let iter3 = SampleChannelIterator(atFrame: 44100, inChannel: testSample.channels[0])
    #expect(iter3 == nil)
    
    let iter4 = SampleChannelIterator(atFrame: 44099, inChannel: testSample.channels[0])
    #expect(iter4 != nil)
    
    if var iter4 {
        #expect(iter4.hasMoreData)
        
        _ = iter4.cachePointAndAdvance()
        
        #expect(!iter4.hasMoreData)
        
        #expect(iter4.cachePointAndAdvance() == nil)
    }
}

@MainActor
@Test func testAdvanceIter() throws {
    let testSample = try makeTestSample()
    
    let iter = SampleChannelIterator(atFrame: 0, inChannel: testSample.channels[0])
    #expect(iter != nil)
    
    if var iter, let block = testSample.channels[0].firstBlock {
        for frame in 0..<block.numberOfFrames {
            let value = iter.frameAndAdvance()
            #expect(value != nil)
            #expect(value! == block.data(atFrame: frame))
        }
    }
}

@MainActor
@Test func testAdvanceIterCachePoint() throws {
    let testSample = try makeTestSample()
    
    let iter = SampleChannelIterator(atFrame: 0, inChannel: testSample.channels[0])
    #expect(iter != nil)
    
    if var iter, let block = testSample.channels[0].firstBlock {
        for cachePoint in 0..<(block.numberOfFrames / UInt64(SampleChannel.CachePoint.samplesPerCachePoint)) {
            let value = iter.cachePointAndAdvance()
            #expect(value != nil)
            #expect(value! == block.cachePoint(atFrame: cachePoint * UInt64(SampleChannel.CachePoint.samplesPerCachePoint)))
        }
    }
}

@MainActor
@Test func testMultipleBlocks() throws {
    let testSample = try makeTestSample(numberOfBlocks: 3)
    let iter = SampleChannelIterator(atFrame: 0, inChannel: testSample.channels[0])
    #expect(iter != nil)
    
    if var iter {
        var count = 0
        while let _ = iter.frameAndAdvance() {
            count += 1
        }
        #expect(count == testSample.numberOfFrames)
    }
}

@MainActor
@Test func testPeekFrame() throws {
    let testSample = try makeTestSample()
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    let iter = SampleChannelIterator(atFrame: 0, inChannel: testSample.channels[0])
    #expect(iter != nil)
    
    if let iter, let firstBlockData = block?.data(atFrame: 0) {
        let peekedValue = iter.peekFrame()
        #expect(peekedValue == firstBlockData)
    }
    
    let iter2 = SampleChannelIterator(atFrame: 44099, inChannel: testSample.channels[0])
    #expect(iter2 != nil)
    
    if var iter2 {
        _ = iter2.frameAndAdvance()
        #expect(iter2.peekFrame() == 0)
    }
}

@MainActor
@Test func testPeekNextFrame() throws {
    let testSample = try makeTestSample()
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    let iter = SampleChannelIterator(atFrame: 0, inChannel: testSample.channels[0])
    #expect(iter != nil)
    
    if let iter, let firstBlockData = block?.data(atFrame: 1) {
        let peekedValue = iter.peekNextFrame()
        #expect(peekedValue == firstBlockData)
    }
    
    let iter2 = SampleChannelIterator(atFrame: 44099, inChannel: testSample.channels[0])
    #expect(iter2 != nil)
    
    if var iter2 {
        #expect(iter2.peekNextFrame() == 0)
        let _ = iter2.frameAndAdvance()
        #expect(iter2.peekNextFrame() == 0)
    }
}

@MainActor
@Test func testPeekNextFrameAtEndOfBlock() throws {
    let testSample = try makeTestSample(numberOfBlocks: 2)
    
    let block = testSample.channels[0].firstBlock?.nextBlock
    #expect(block != nil)
    
    let iter = SampleChannelIterator(atFrame: 44099, inChannel: testSample.channels[0])
    #expect(iter != nil)
    
    if let iter, let block {
        let result = iter.peekNextFrame()
        #expect(result == block.data(atFrame: 0))
    }
}

@MainActor
@Test func testCachePointAndAdvance() throws {
    let testSample = try makeTestSample()
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    let iter = SampleChannelIterator(atFrame: 0, inChannel: testSample.channels[0])
    #expect(iter != nil)
    
    if var iter, let block {
        var maxValue: Float = 0
        var minValue: Float = 0
        var totalAbove: Double = 0
        var totalBelow: Double = 0
        var numberFramesAbove: Int = 0
        var numberFramesBelow: Int = 0
        
        for i in 0..<4 {
            let value = block.data(atFrame: UInt64(i))

            maxValue = max(value, maxValue)
            minValue = min(value, minValue)
            if value > 0 {
                totalAbove += Double(value)
                numberFramesAbove += 1
            } else if value < 0 {
                totalBelow += Double(value)
                numberFramesBelow += 1
            }
        }
        
        let result = SampleChannel.CachePoint(minValue: Double(minValue),
                                              maxValue: Double(maxValue),
                                              avgMinValue: numberFramesBelow == 0 ? 0 : totalBelow / Double(numberFramesBelow),
                                              avgMaxValue: numberFramesAbove == 0 ? 0 : totalAbove / Double(numberFramesAbove))
        #expect(iter.pixelCachePointAndAdvance(forFramesPerPixel: 4) == result)
    }
}

@MainActor
@Test func testLargeCachePointAndAdvance() throws {
    let testSample = try makeTestSample()
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    let iter = SampleChannelIterator(atFrame: 0, inChannel: testSample.channels[0])
    #expect(iter != nil)
    
    if var iter, let block {
        let cachePoints = cachePointsFromBlock(block)
        var minValue: Double = 0
        var maxValue: Double = 0
        var totalAvgBelow: Double = 0
        var totalAvgAbove: Double = 0
        
        for i in 0..<4 {
            let cp = cachePoints[i]
            minValue = min(cp.minValue, minValue)
            maxValue = max(cp.maxValue, maxValue)
            totalAvgAbove += cp.avgMaxValue
            totalAvgBelow += cp.avgMinValue
        }
        
        let result = SampleChannel.CachePoint(minValue: minValue,
                                              maxValue: maxValue,
                                              avgMinValue: totalAvgBelow / Double(4),
                                              avgMaxValue: totalAvgAbove / Double(4))
            
        let iterResult = iter.pixelCachePointAndAdvance(forFramesPerPixel: 1024)
        #expect(iterResult != nil)
        #expect(iterResult == result)
    }
}
