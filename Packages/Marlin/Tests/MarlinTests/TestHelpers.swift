import Foundation
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
            let value = block.data(atFrame: samplePositionInBlock)
            
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
