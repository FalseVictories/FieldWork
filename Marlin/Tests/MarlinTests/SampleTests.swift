import Foundation
import Testing
@testable import Marlin

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
    try await testSample.loadSample(from: URL(string: "file://nothing.wav")!, withAudioLoader: FakeAudioLoader())
    
    #expect(testSample.numberOfFrames == 44100)
    #expect(testSample.channels.count == 1)
}

@MainActor
@Test func testAVAudioLoader() async throws {
    let testSample = Sample()
    let url = Bundle.module.url(forResource: "example-right-channel-stereo.wav", withExtension: nil, subdirectory: "Resources")!
    try await testSample.loadSample(from: url, withAudioLoader: AVAudioLoader())
    
    #expect(testSample.numberOfFrames == 96_000)
    #expect(testSample.channels.count == 2)
    #expect(testSample.bitDepth == 24)
}
