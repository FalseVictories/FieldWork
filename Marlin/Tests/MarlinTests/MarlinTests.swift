import Foundation
import Testing
@testable import Marlin

@MainActor
func makeTestSample() throws -> Sample {
    if let sample = Sample() {
        let channel = SampleChannel(withSampleBlockFactory: try DefaultSampleBlockFactory())
        
        let data = UnsafeMutableBufferPointer<Float>.allocate(capacity: 44100)
        for i in 0..<44100 {
            data[i] = sin(Float(i) * Float.pi / 180)
        }
        
        try channel.appendData(UnsafeBufferPointer(data))
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
