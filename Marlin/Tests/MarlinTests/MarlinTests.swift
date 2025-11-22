import Foundation
import Testing
@testable import Marlin

@MainActor
func makeTestSample(numberOfBlocks: Int = 1) throws -> Sample {
    if let sample = Sample() {
        let channel = SampleChannel(withSampleBlockFactory: try DefaultSampleBlockFactory())
        
        for blockCount in 0..<numberOfBlocks {
            let data = UnsafeMutableBufferPointer<Float>.allocate(capacity: 44100)
            for i in 0..<44100 {
                data[i] = sin(Float(i) * Float.pi / 180)
            }
            
            try channel.appendData(UnsafeBufferPointer(data))
        }
        sample.channels.append(channel)
        return sample
    }
    fatalError()
}

@MainActor
@Test func testSampleDataSmall() async throws {
    let testSample = try makeTestSample()
    #expect(testSample.numberOfFrames == 44100)
    
    let block = testSample.channels[0].firstBlock
    #expect(block != nil)
    
    guard let block else {
        fatalError()
    }
  
    for i in 0..<44100 {
        #expect(block.data(at: UInt64(i)) == sin(Float(i) * Float.pi / 180))
    }
}

@MainActor
@Test func testGetSampleBlockForFrame() throws {
    let testSample = try makeTestSample(numberOfBlocks: 3)
    #expect(testSample.numberOfFrames == 44100 * 3)
    
    let sampleChannel = testSample.channels[0]
    let block1 = sampleChannel.sampleBlockForFrame(1342)
    let block2 = sampleChannel.sampleBlockForFrame(68038)
    let block3 = sampleChannel.sampleBlockForFrame(90000)
    
    #expect(block1 != nil)
    #expect(block2 != nil)
    #expect(block3 != nil)
    
    #expect(block1?.startFrame == 0)
    #expect(block2?.startFrame == 44100)
    #expect(block3?.startFrame == 88200)
}
