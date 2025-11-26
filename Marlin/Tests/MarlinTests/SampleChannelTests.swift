import Foundation
import Testing
@testable import Marlin

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
