import Foundation
import Testing
@testable import Marlin

@MainActor
func makeTestSample(numberOfBlocks: Int = 1) throws -> Sample {
    let sample = Sample()
    let channel = SampleChannel(withSampleBlockFactory: DefaultSampleBlockFactory())
    
    for _ in 0..<numberOfBlocks {
        let data = UnsafeMutableBufferPointer<Float>.allocate(capacity: 44100)
        for i in 0..<44100 {
            data[i] = sin(Float(i) * Float.pi / 180)
        }
        
        try channel.appendData(UnsafeBufferPointer(data))
    }
    sample.channels.append(channel)
    return sample
}

func cachePointsFromBlock(_ block: SampleBlock) -> [SampleChannel.CachePoint] {
    var cachePoints: [SampleChannel.CachePoint] = []
    
    // This is the algorithm from FileSampleBlock and needs to be kept in sync
    var samplePositionInBlock: UInt64 = 0
    var samplesRemaining = block.numberOfFrames
    while samplesRemaining > 0 {
        var minValue: Float = 0.0, maxValue: Float = 0.0
        var sumBelowZero: Float = 0.0, sumAboveZero: Float = 0.0
        var aboveCount = 0, belowCount = 0
        
        var i = 0
        while i < SampleChannel.CachePoint.samplesPerCachePoint &&
                samplePositionInBlock < block.numberOfFrames {
            let value = block.data(at: samplePositionInBlock)
            
            minValue = min(minValue, value)
            maxValue = max(maxValue, value)
            if value < 0.0 {
                sumBelowZero += value
                belowCount += 1
            } else {
                sumAboveZero += value
                aboveCount += 1
            }
            
            i += 1
            samplePositionInBlock += 1
            samplesRemaining -= 1
        }
        
        let cp = SampleChannel.CachePoint(minValue: minValue,
                                          maxValue: maxValue,
                                          avgMinValue: belowCount == 0 ? 0.0 : sumBelowZero / Float(belowCount),
                                          avgMaxValue: aboveCount == 0 ? 0.0 : sumAboveZero / Float(aboveCount))
        cachePoints.append(cp)
    }
    
    return cachePoints
}

class FakeAudioLoader: AudioLoader {
    func importSample(from url: URL,
                      operation: Marlin.SampleOperation,
                      channelBuilder: @Sendable () throws -> Marlin.SampleChannel) async throws -> Marlin.AudioLoaderResult? {
        print("importing")
        let channel = try channelBuilder()
        
        let data = UnsafeMutableBufferPointer<Float>.allocate(capacity: 44100)
        for i in 0..<44100 {
            data[i] = sin(Float(i) * Float.pi / 180)
        }
        
        try channel.appendData(UnsafeBufferPointer(data))
        
        print("Returning")
        return .init(bitDepth: 16, sampleRate: 44100, channels: [channel])
    }
}

@MainActor
@Test func testEmptySample() {
    let testSample = Sample()
    #expect(testSample.numberOfFrames == 0)
    #expect(testSample.channels.isEmpty)
}

@MainActor
@Test func testSampleLoader() async throws {
    let testSample = Sample()
    testSample.loadSample(from: URL(string: "file://nothing.wav")!, withAudioLoader: FakeAudioLoader())
    
    try await Task.sleep(nanoseconds: 1_000_000_000)
    
    #expect(testSample.numberOfFrames == 44100)
    #expect(testSample.channels.count == 1)
}

@MainActor
@Test func testAVAudioLoader() async throws {
    let testSample = Sample()
    let url = Bundle.module.url(forResource: "example-right-channel-stereo.wav", withExtension: nil, subdirectory: "Resources")!
    testSample.loadSample(from: url, withAudioLoader: AVAudioLoader())
    
    try await Task.sleep(nanoseconds: 2_000_000_000)
    
    #expect(testSample.numberOfFrames == 96_000)
    #expect(testSample.channels.count == 2)
    #expect(testSample.bitDepth == 24)
}

@MainActor
@Test func testSampleDataFrameAccess() throws {
    let testSample = try makeTestSample()
    #expect(testSample.numberOfFrames == 44100)
    #expect(testSample.channels.count == 1)
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    if let block {
        for i in 0..<block.numberOfFrames {
            #expect(block.data(at: UInt64(i)) == sin(Float(i) * Float.pi / 180))
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
            #expect(block.data(at: UInt64(i)) == sin(Float(block.numberOfFrames - 1 - i) * Float.pi / 180))
        }
    }
}

@MainActor
@Test func testSampleDataOutOfBounds() throws {
    let testSample = try makeTestSample()
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    if let block {
        #expect(block.data(at: 88_392) == 0)
    }
}

@MainActor
@Test func testSampleCachePointAccess() throws {
    let testSample = try makeTestSample()
    
    guard let block = testSample.channels[0].firstBlock else {
        fatalError()
    }
    
    let cachePoints = cachePointsFromBlock(block)
    
    for i in 0..<block.numberOfFrames {
        let cachePointIndex = i / UInt64(SampleChannel.CachePoint.samplesPerCachePoint)
        #expect(block.cachePoint(at: cachePointIndex) == cachePoints[Int(cachePointIndex)])
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
        #expect(block.cachePoint(at: frame) == cachePoints[Int(cachePointIndex)])
    }
}

@MainActor
@Test func testGetSampleBlockForFrame() throws {
    let testSample = try makeTestSample(numberOfBlocks: 3)
    #expect(testSample.numberOfFrames == 44_100 * 3)
    
    let sampleChannel = testSample.channels[0]
    let block1 = sampleChannel.sampleBlockForFrame(1_342)
    let block2 = sampleChannel.sampleBlockForFrame(68_038)
    let block3 = sampleChannel.sampleBlockForFrame(90_000)
    let block4 = sampleChannel.sampleBlockForFrame(1_000_000)
    
    #expect(block1 != nil)
    #expect(block2 != nil)
    #expect(block3 != nil)
    #expect(block4 == nil)
    
    #expect(block1?.startFrame == 0)
    #expect(block2?.startFrame == 44_100)
    #expect(block3?.startFrame == 88_200)
}
