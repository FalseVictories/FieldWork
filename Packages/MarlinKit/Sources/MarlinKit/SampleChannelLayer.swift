import AppKit
import QuartzCore
import Marlin

class SampleChannelLayer: CATiledLayer {
    let channel: SampleChannel
    var strokeColor: NSColor
    
    class override func fadeDuration() -> CFTimeInterval {
        .zero
    }
    
    var framesPerPixel: UInt = 256 {
        didSet {
            needsDisplay()
        }
    }
    
    init(channel: SampleChannel,
         strokeColor: NSColor) {
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
        
        let minMaxPath = NSBezierPath()
        let rmsPath = NSBezierPath()

        // Add an offset to centre the waveform
//        let offsetBounds = CGRect(x: bounds.minX,
//                                  y: bounds.minY + bounds.height / 2,
//                                  width: bounds.width,
//                                  height: bounds.height)
        
        let offsetBounds = CGRect(x: clipRect.minX,
                                  y: clipRect.minY + clipRect.height / 2,
                                  width: clipRect.width,
                                  height: clipRect.height)
        
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
