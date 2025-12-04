import AppKit
import Marlin

public class AppKitSampleView: NSView {
    var sample: Sample? {
        didSet {
            guard let sample else {
                return
            }
            
            if sample.isLoaded {
                invalidateIntrinsicContentSize()
                needsDisplay = true
            } else {
                // FIXME - observe isLoaded changing
            }
        }
    }
    
    var framesPerPixel: UInt = 256 {
        didSet {
            if framesPerPixel != oldValue {
                invalidateIntrinsicContentSize()
                needsDisplay = true
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
    }
    
    init(withSample sample: Sample) {
        self.sample = sample
        super.init(frame: .zero)
    }
    
    var width: CGFloat {
        guard let sample = sample else {
            return NSView.noIntrinsicMetric
        }
        
        return ceil(CGFloat(sample.numberOfFrames) / CGFloat(framesPerPixel))
    }
    
    public override var intrinsicContentSize: NSSize {
        .init(width: self.width, height: NSView.noIntrinsicMetric)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AppKitSampleView {
    public override func draw(_ dirtyRect: NSRect) {
        guard let sample = sample else {
            drawBrokenSample(dirtyRect)
            return
        }
        
        if !sample.isLoaded {
            return
        }

        let channelHeight = Int(frame.height) / sample.channels.count
        let fpp = framesPerPixel
        for (index, channel) in sample.channels.enumerated() {
            let yOffset = CGFloat(channelHeight) / 2
            let rect = CGRect(x: 0,
                              y: CGFloat(channelHeight) * CGFloat(index) + yOffset,
                              width: width,
                              height: CGFloat(channelHeight))
            
            var drawRect = NSIntersectionRect(rect, dirtyRect)
            drawRect.origin.y = rect.origin.y
            drawRect.size.height = CGFloat(channelHeight)
            
            drawChannel(channel,
                        inRect: drawRect,
                        framesPerPixel: fpp,
                        strokeColor: index == 0 ? NSColor.systemRed : NSColor.systemBlue)
        }
    }
    
    private func drawBrokenSample(_ dirtyRect: NSRect) {
        NSColor.systemRed.setFill()
        NSBezierPath.fill(dirtyRect)
    }
    
    private func drawChannel(_ channel: SampleChannel,
                             inRect rect: NSRect,
                             framesPerPixel fpp: UInt,
                             strokeColor: NSColor) {
        guard let sample = sample else {
            return
        }
        
        let minMaxPath = NSBezierPath()
        let rmsPath = NSBezierPath()

        sample.draw(channel,
                    inRect: rect,
                    framesPerPixel: fpp,
                    minMaxPath:minMaxPath, rmsPath:rmsPath)
        
        strokeColor.withAlphaComponent(0.5).set()
        minMaxPath.stroke()
        
        strokeColor.set()
        rmsPath.stroke()
    }
}

private extension AppKitSampleView {
    func convertPointToFrame(_ point: NSPoint) -> UInt64 {
        let scaledPoint = convertToBacking(point)
        
        return (scaledPoint.x < 0) ? 0 : UInt64(scaledPoint.x) * UInt64(framesPerPixel)
    }
    
    func convertFrameToPoint(_ frame: UInt64) -> NSPoint {
        let scaledPoint = NSPoint(x: Double(frame / UInt64(framesPerPixel)), y: 0.0)
        return convertFromBacking(scaledPoint)
    }
}
