#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

import QuartzCore
import Marlin

class SampleChannelLayer: CATiledLayer {
    let channel: SampleChannel
    var strokeColor: PlatformColor
    
    class override func fadeDuration() -> CFTimeInterval {
        .zero
    }
    
    var framesPerPixel: UInt = 256 {
        didSet {
            needsDisplay()
        }
    }
    
    init(channel: SampleChannel,
         strokeColor: PlatformColor) {
        self.channel = channel
        self.strokeColor = strokeColor
        
        super.init()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(in ctx: CGContext) {
        let clipRect = ctx.boundingBoxOfClipPath
        
        let minMaxPath = PlatformBezierPath()
        let rmsPath = PlatformBezierPath()

        // Add an offset to centre the waveform
        let offsetBounds = CGRect(x: clipRect.minX,
                                  y: bounds.minY + (bounds.height / 2),
                                  width: clipRect.width,
                                  height: bounds.height)
        
        channel.draw(inRect: offsetBounds,
                     framesPerPixel: framesPerPixel,
                     minMaxPath:minMaxPath, rmsPath:rmsPath)
        
        ctx.setStrokeColor(strokeColor.withAlphaComponent(0.5).cgColor)
        
        ctx.addPath(minMaxPath.cgPath)
        ctx.strokePath()
        
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.addPath(rmsPath.cgPath)
        ctx.strokePath()
    }
}
