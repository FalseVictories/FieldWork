import Foundation
import OSLog
import System

extension Logger {
    static let cacheFile = Logger(subsystem: "com.falsevictories.FieldWork", category: "CacheFile")
}

enum CacheFileError: Error {
    case couldNotCreateFile
}

fileprivate let pageSize: Int32 = {
    getpagesize()
}()

fileprivate let BUFFER_SIZE = 64 * 1024
fileprivate let cachesUrl: URL = {
    Logger.cacheFile.debug("Creating caches directory")
    
    let fm = FileManager.default
    let baseUrl = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let cacheUrl = baseUrl.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.falsevictories.FieldWork",
                                                  isDirectory: true)
    do {
        Logger.cacheFile.debug("\(cacheUrl.path())")
        try fm.createDirectory(at: cacheUrl, withIntermediateDirectories: true)
    } catch {
        Logger.cacheFile.error("Error creating cachedir: \(error)")
        fatalError("Error creating cachedir: \(error)")
    }
    
    return cacheUrl
}()

final class CacheFile<T>: Sendable {
    class func createCacheFile(withExtension ext: String) throws -> CacheFile {
        let uniqueFilename = "FieldWork-\(ProcessInfo().globallyUniqueString).\(ext)"
        let url = cachesUrl.appending(path: uniqueFilename)
        
        let fd = try FileDescriptor.open(FilePath(url.path(percentEncoded: true)),
                                         .readWrite,
                                         options: .create,
                                         permissions: [.ownerReadWrite, .groupReadWrite, .otherRead])
        Logger.cacheFile.debug("Created \(url.path()) for data cache")
        
        return CacheFile(url: url, fd: fd)
    }
    
    let url: URL
    let fd: FileDescriptor
    
    init(url: URL, fd: FileDescriptor) {
        self.url = url
        self.fd = fd
    }
}

extension CacheFile {
    func createMappedRegion(with data: UnsafeBufferPointer<T>) throws -> MappedRegion<T> {
        let fileOffset = try writeData(UnsafeRawBufferPointer(data))
        
        let region = MappedRegion(cacheFile: self, fileOffset: fileOffset, byteLength: data.count)
        try region.mapData()
        
        return region
    }
    
    private func writeData(_ data: UnsafeRawBufferPointer) throws -> Int64 {
        let fileOffset = try fd.seek(offset: 0, from: .current)
        
        let bytesWritten = try fd.write(data, retryOnInterrupt: true)
        Logger.mappedRegion.debug("Wrote \(bytesWritten)")
        
        // mmap only works on page alignments so pad the data
        var paddingBytes = (Int32(data.count) % pageSize)
        if paddingBytes > 0 {
            paddingBytes = pageSize - paddingBytes
            Logger.mappedRegion.debug("Need to pad by \(paddingBytes) bytes (\(data.count) % \(pageSize)")
            
            let paddingOffset = try fd.seek(offset: Int64(paddingBytes), from: .end)
            if paddingOffset == -1 {
                throw MappedRegionError.paddingError(error: errno)
            }
            if paddingOffset % off_t(pageSize) != 0 {
                Logger.mappedRegion.warning("Padded offset is not a multiple of the page size")
                throw MappedRegionError.paddingError(error: EINVAL)
            }
        }
        
        return fileOffset
    }
}
