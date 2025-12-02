import Foundation
import OSLog

extension Logger {
    static let mappedRegion = Logger(subsystem: "com.falsevictories.FieldWork", category: "mappedRegion")
}

enum MappedRegionError: Error {
    case noData
    case writeFailed(error: Int32)
    case paddingError(error: Int32)
    case alreadyMapped
    case notMapped
    case mappingFailed(error: Int32)
    case unmappingFailed(error: Int32)
}

class MappedRegion<T> {
    var mappedData: UnsafeBufferPointer<T>?
    
    let cacheFile: CacheFile<T>
    private let fileOffset: off_t
    private let byteLength: size_t
  
    init(cacheFile: CacheFile<T>,
         fileOffset: off_t,
         byteLength: size_t) {
        self.cacheFile = cacheFile
        self.fileOffset = fileOffset
        self.byteLength = byteLength
    }
    
    deinit {
        if mappedData != nil {
            do {
                try unmapData()
            } catch {
                Logger.mappedRegion.error("Failed to deinit: \(error)")
            }
        }
    }
}

extension MappedRegion {
    func mapData() throws {
        guard mappedData == nil else {
            throw MappedRegionError.alreadyMapped
        }
        
        let rawData = mmap(nil, byteLength,
                           PROT_READ | PROT_WRITE,
                           MAP_SHARED, cacheFile.fd.rawValue, fileOffset)
        if rawData == MAP_FAILED {
            throw MappedRegionError.mappingFailed(error: errno)
        }
        
        mappedData = UnsafeBufferPointer<T>(start: UnsafePointer(rawData?.assumingMemoryBound(to: T.self)), count: Int(byteLength) / MemoryLayout<T>.stride)
    }
    
    func unmapData() throws {
        guard mappedData != nil else {
            throw MappedRegionError.notMapped
        }
        
        if let baseAddress = mappedData?.baseAddress {
            let rawData = UnsafeMutableRawPointer(mutating: baseAddress)
            if munmap(rawData, byteLength) < 0 {
                mappedData = nil
                throw MappedRegionError.unmappingFailed(error: errno)
            }
        }
        mappedData = nil
    }
}
