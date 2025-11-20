import Foundation
import OSLog

extension Logger {
    static let fileSampleBlock = Logger(subsystem: "com.falsevictories.FieldWork", category: "FileSampleBlock")
}

enum FileSampleBlockError: Error {
    case outOfBounds
}

class FileSampleBlock: SampleBlock {
    let dataRegion: MappedRegion<Float>
    let cachePointRegion: MappedRegion<SampleChannel.CachePoint>
    
    let dataRegionOffset: off_t // In frames
    let dataRegionLength: size_t // in frames
    let cacheRegionOffset: off_t // in CachePoints
    let cacheRegionLength: size_t // in CachePoines
    
    convenience init(data: UnsafeBufferPointer<Float>,
                     dataCacheFile: CacheFile<Float>,
                     cachePointFile: CacheFile<SampleChannel.CachePoint>) throws {
        let cachePointData = try Self.createCachePointData(fromBlockData: data)
        let dataRegion = try dataCacheFile.createMappedRegion(with: data)
        let cachePointRegion = try cachePointFile.createMappedRegion(with: cachePointData)
        
        self.init(dataRegion: dataRegion,
                  dataRegionOffset: 0,
                  dataRegionLength: data.count,
                  cachePointRegion: cachePointRegion,
                  cachePointRegionOffset: 0,
                  cachePointRegionLength: cachePointData.count)
    }
    
    init(dataRegion: MappedRegion<Float>,
         dataRegionOffset: off_t,
         dataRegionLength: size_t,
         cachePointRegion: MappedRegion<SampleChannel.CachePoint>,
         cachePointRegionOffset: off_t,
         cachePointRegionLength: size_t) {
        self.dataRegion = dataRegion
        self.cachePointRegion = cachePointRegion
        
        self.dataRegionOffset = dataRegionOffset
        self.dataRegionLength = dataRegionLength
        
        self.cacheRegionOffset = cachePointRegionOffset
        self.cacheRegionLength = cachePointRegionLength
        
        super.init()
        
        numberOfFrames = UInt64(dataRegionLength)
    }

    override func data(at frame: UInt64) -> Float {
        guard frame < numberOfFrames else {
            Logger.fileSampleBlock.error("Out of bounds request: \(frame) is bigger than \(self.numberOfFrames)")
            return 0.0
        }
        
        guard let data = dataRegion.mappedData else {
            Logger.fileSampleBlock.error("Data region is not mapped")
            return 0.0
        }
        
        // Need to use offset - mappedData is whole region on disk
        // block may just be a small part of that region
        return data[Int(frame + UInt64(dataRegionOffset))]
    }
    
    override func cachePoint(at cachePoint: UInt64) -> SampleChannel.CachePoint {
        guard let data = cachePointRegion.mappedData else {
            Logger.fileSampleBlock.error("Cachepoint region is not mapped")
            return .init(minValue: 0, maxValue: 0, avgMinValue: 0, avgMaxValue: 0)
        }
        
        return data[Int(cachePoint + UInt64(cacheRegionOffset))]
    }
}

extension FileSampleBlock {
    static private func createCachePointData(fromBlockData data: UnsafeBufferPointer<Float>) throws -> UnsafeBufferPointer<SampleChannel.CachePoint> {
        Logger.fileSampleBlock.debug("Calculating cachepoints for \(data.count) samples")
        var numberOfCachePoints = data.count / SampleChannel.CachePoint.samplesPerCachePoint
        
        if data.count % SampleChannel.CachePoint.samplesPerCachePoint != 0 {
            numberOfCachePoints += 1
        }
        
        let cachePointsBuffer = UnsafeMutableBufferPointer<SampleChannel.CachePoint>.allocate(capacity: numberOfCachePoints)
        
        var samplesRemaining = data.count
        var samplePositionInBuffer = 0
        var positionInCachePointBuffer = 0
        
        while samplesRemaining > 0 {
            var minValue: Float = 0.0, maxValue: Float = 0.0
            var sumBelowZero: Float = 0.0, sumAboveZero: Float = 0.0
            var aboveCount = 0, belowCount = 0
            
            var i = 0
            while i < SampleChannel.CachePoint.samplesPerCachePoint &&
                    samplePositionInBuffer < data.count {
                let value = data[samplePositionInBuffer]
                
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
                samplePositionInBuffer += 1
                samplesRemaining -= 1
            }
            
            let cp = SampleChannel.CachePoint(minValue: minValue,
                                              maxValue: maxValue,
                                              avgMinValue: belowCount == 0 ? 0.0 : sumBelowZero / Float(belowCount),
                                              avgMaxValue: aboveCount == 0 ? 0.0 : sumAboveZero / Float(aboveCount))
            cachePointsBuffer[positionInCachePointBuffer] = cp
            
            positionInCachePointBuffer += 1
        }
        
        return .init(cachePointsBuffer)
    }
}
