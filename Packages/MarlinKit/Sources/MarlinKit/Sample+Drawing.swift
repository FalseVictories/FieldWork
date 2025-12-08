import Foundation
import AppKit

import Marlin

extension SampleChannel {
    nonisolated
    func draw(inRect rect: CGRect,
              framesPerPixel fpp: UInt,
              minMaxPath: NSBezierPath,
              rmsPath: NSBezierPath) {
        let firstFrame = UInt64(rect.origin.x) * UInt64(fpp)
        
        guard var iter = SampleChannelIterator(atFrame: firstFrame, inChannel: self) else {
            return
        }
        
        // floor the width and add 1 to make up for X not being on an integer boundary
        // Consider drawing from 0.5 with width 3, we need to draw the 0, 1, 2, and 3 pixels
        // which is 4 frames
        let numberOfPixels = floor(rect.size.width) + 1
        
        if (fpp == 1) {
            for x in 0..<Int(numberOfPixels) {
                let value: Float = iter.frameAndAdvance() ?? 0
                
                let y = (CGFloat(value / 2) * rect.size.height) + rect.origin.y
                let point = NSPoint(x: CGFloat(x) + rect.origin.x, y: y)
                if x == 0 {
                    minMaxPath.move(to: point)
                } else {
                    minMaxPath.line(to: point)
                }
            }
        } else {
            for x in 0..<Int(numberOfPixels) {
                let cachePoint = iter.pixelCachePointAndAdvance(forFramesPerPixel: fpp) ?? .zero
                
                let maxY = (CGFloat(cachePoint.maxValue / 2) * rect.size.height) + rect.origin.y
                let minY = (CGFloat(cachePoint.minValue / 2) * rect.size.height) + rect.origin.y
                let rmsMax = (CGFloat(cachePoint.avgMaxValue / 2) * rect.size.height) + rect.origin.y
                let rmsMin = (CGFloat(cachePoint.avgMinValue / 2) * rect.size.height) + rect.origin.y
                
                minMaxPath.move(to: NSPoint(x: CGFloat(x) + rect.origin.x, y: maxY))
                minMaxPath.line(to: NSPoint(x: CGFloat(x) + rect.origin.x, y: minY))
                
                rmsPath.move(to: NSPoint(x: CGFloat(x) + rect.origin.x, y: rmsMax))
                rmsPath.line(to: NSPoint(x: CGFloat(x) + rect.origin.x, y: rmsMin))
            }
        }
    }
}
