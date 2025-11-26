import Foundation
import Testing
@testable import Marlin

@MainActor
@Test func testSampleDataFrameAccess() throws {
    let testSample = try makeTestSample()
    #expect(testSample.numberOfFrames == 44100)
    #expect(testSample.channels.count == 1)
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    if let block {
        for i in 0..<block.numberOfFrames {
            #expect(block.data(atFrame: UInt64(i)) == sin(Float(i) * Float.pi / 180))
        }
    }
}

@MainActor
@Test func testSampleDataFrameAccessReversed() throws {
    let testSample = try makeTestSample()
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    if let block {
        block.reversed = true
        for i in 0..<block.numberOfFrames {
            #expect(block.data(atFrame: UInt64(i)) == sin(Float(block.numberOfFrames - 1 - i) * Float.pi / 180))
        }
    }
}

@MainActor
@Test func testSampleDataOutOfBounds() throws {
    let testSample = try makeTestSample()
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    if let block {
        #expect(block.data(atFrame: 88_392) == 0)
        #expect(block.cachePoint(atFrame: 88_392) == .init(minValue: 0, maxValue: 0, avgMinValue: 0, avgMaxValue: 0))
    }
}

@MainActor
@Test func testSampleCachePointAccess() throws {
    let testSample = try makeTestSample()
    
    guard let block = testSample.channels[0].firstBlock else {
        fatalError()
    }
    
    let cachePoints = cachePointsFromBlock(block)
    
    for frame in 0..<block.numberOfFrames {
        let cachePointIndex = frame / UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
        #expect(block.cachePoint(atFrame: frame) == cachePoints[Int(cachePointIndex)])
    }
}

@MainActor
@Test func testSampleCachePointAccessReversed() throws {
    let testSample = try makeTestSample()
    
    guard let block = testSample.channels[0].firstBlock else {
        fatalError()
    }
    
    let cachePoints = cachePointsFromBlock(block)
    block.reversed = true
    
    let extraFrames = block.numberOfFrames % UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
    for frame in 0..<block.numberOfFrames {
        let cachePointIndex: UInt64
        if frame < extraFrames {
            cachePointIndex = block.numberOfFrames / UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
        } else {
            cachePointIndex = ((block.numberOfFrames - 1) - frame) / UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
        }
        #expect(block.cachePoint(atFrame: frame) == cachePoints[Int(cachePointIndex)])
    }
}
