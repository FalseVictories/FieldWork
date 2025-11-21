import AVFoundation
import Foundation
import OSLog

final public class AVAudioLoader {
    static let BUFFER_SIZE: AVAudioFrameCount = 1024 * 1024 // 1mb buffer - about 6 seconds of audio
    
    public init() {}
}

extension AVAudioLoader: AudioLoader {
    public func importSample(from url: URL,
                             channelBuilder: ChannelBuilder) async throws -> AudioLoaderResult? {
        let sourceFile: AVAudioFile
        let format: AVAudioFormat
        let fileFormat: AVAudioFormat
        
        Logger.audioLoader.info("Loading: \(url.path(percentEncoded: true))")
        
        do {
            sourceFile = try AVAudioFile(forReading: url)
            format = sourceFile.processingFormat
            fileFormat = sourceFile.fileFormat
        } catch {
            Logger.audioLoader.error("Unable to open for reading: \(error.localizedDescription)")
            return nil
        }
        
        Logger.audioLoader.info("Format: \(format)")
        Logger.audioLoader.info("Frames: \(sourceFile.length)")
        
        let newChannels = try (0..<format.channelCount).compactMap { _ in try channelBuilder() }
        
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        // Need to use the synchronous version of this because
        // the await never completes.
        player.scheduleFile(sourceFile, at: nil) {}

        do {
            let maxFrames: AVAudioFrameCount = Self.BUFFER_SIZE
            try engine.enableManualRenderingMode(.offline, format: format,
                                                 maximumFrameCount: maxFrames)
        } catch {
            Logger.audioLoader.error("Unable to enable manual rendering mode: \(error)")
            return nil
        }
        
        do {
            try engine.start()
            player.play()
        } catch {
            Logger.audioLoader.error("Unable to start audio engine: \(error)")
            return nil
        }
        
        let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat,
                                      frameCapacity: engine.manualRenderingMaximumFrameCount)!
        
        var totalFrameCount: UInt64 = 0
        
        while engine.manualRenderingSampleTime < sourceFile.length {
            do {
                let frameCount = sourceFile.length - engine.manualRenderingSampleTime
                let framesToRender = min(AVAudioFrameCount(frameCount), buffer.frameCapacity)
                
                let status = try engine.renderOffline(framesToRender, to: buffer)
                
                Logger.audioLoader.debug("Read \(buffer.frameLength) frames")
                switch status {
                case .success:
                    // The data rendered successfully. Write it to the output file.
                    //            try outputFile.write(from: buffer)
                    totalFrameCount += UInt64(buffer.frameLength)
                    guard let channelData = buffer.floatChannelData else {
                        throw SampleError.noChannelData
                    }
                    
                    for i in 0..<buffer.format.channelCount {
                        let dataBuffer = UnsafeBufferPointer(start: channelData[Int(i)],
                                                             count: Int(buffer.frameLength))
                        try newChannels[Int(i)].appendData(dataBuffer)
                    }
                    
                case .insufficientDataFromInputNode:
                    // Applicable only when using the input node as one of the sources.
                    break
                    
                case .cannotDoInCurrentContext:
                    // The engine couldn't render in the current render call.
                    // Retry in the next iteration.
                    break
                    
                case .error:
                    Logger.audioLoader.error("Error rendering audio")
                    return nil
                    
                @unknown default:
                    fatalError()
                }
            } catch {
                Logger.audioLoader.error("Rendering failed: \(error)")
                return nil
            }
            
            await Task.yield()
        }
        
        // Stop the player node and engine.
        player.stop()
        engine.stop()
        
        Logger.audioLoader.info("Frames: \(totalFrameCount)")
        Logger.audioLoader.info("Loading completed")
        
        Logger.audioLoader.debug("Format: \(format)")
        Logger.audioLoader.debug("\(format.settings)")
        Logger.audioLoader.debug("File format: \(fileFormat)")
        Logger.audioLoader.debug("\(fileFormat.settings)")
        
        return .init(bitDepth: fileFormat.settings[AVLinearPCMBitDepthKey] as? Int ?? 0,
                     sampleRate: format.sampleRate,
                     channels: newChannels)
    }
}
