#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

import QuartzCore
import Marlin

class WaveformLayer: CATiledLayer {
    let channel: SampleChannel
    var strokeColor: PlatformColor
    
    class override func fadeDuration() -> CFTimeInterval {
        .zero
    }
    
    var framesPerPixel: UInt {
        didSet {
            needsDisplay()
        }
    }
    
    init(channel: SampleChannel,
         initialFramesPerPixel: UInt,
         strokeColor: PlatformColor) {
        self.channel = channel
        self.framesPerPixel = initialFramesPerPixel
        self.strokeColor = strokeColor
        
        super.init()
        
        needsDisplayOnBoundsChange = true
    }
    
    override init(layer: Any) {
        if let sampleLayer = layer as? Self {
            self.channel = sampleLayer.channel
            self.strokeColor = sampleLayer.strokeColor
            self.framesPerPixel = sampleLayer.framesPerPixel
        } else {
            fatalError()
        }
        
        super.init(layer: layer)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func action(forKey event: String) -> (any CAAction)? {
        nil
    }
    
    override func draw(in ctx: CGContext) {
        let clipRect = ctx.boundingBoxOfClipPath
        
        let minMaxPath = PlatformBezierPath()
        let rmsPath = PlatformBezierPath()

//        ctx.clear(clipRect)
        
//        ctx.setFillColor(NSColor.purple.cgColor)
//        ctx.fill(clipRect)
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
