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
                setupLayers()

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
        self.wantsLayer = true
    }
    
    init(withSample sample: Sample) {
        self.sample = sample
        super.init(frame: .zero)
        self.wantsLayer = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    public override func layout() {
        super.layout()
        
        guard let sample, !sample.channels.isEmpty else {
            return
        }
        
        let channelCount = sample.channels.count
        
        var channelNumber = 0
        if let sublayers = layer?.sublayers {
            let channelHeight = (Int(frame.height) - (5 * (channelCount - 1))) / channelCount
            
            for sublayer in sublayers {
                // Flip the channel positions so channel 0 is at the top and channel 1 below
                let channelY = Int(frame.height) - (channelHeight * (channelNumber + 1) + (5 * channelNumber))
                
                sublayer.frame = CGRect(x: 0, y: channelY,
                                         width: Int(width), height: channelHeight)
                channelNumber += 1
            }
        }
    }
}

private extension AppKitSampleView {
    static var channelColors: [NSColor] = [.systemRed, .systemBlue, .systemGreen]
    func setupLayers() {
        guard let sample else {
            return
        }
        
        var channelNumber = 0
        for channel in sample.channels {
            let channelLayer = SampleChannelLayer(channel: channel, strokeColor: Self.channelColors[channelNumber % Self.channelColors.count])
            
            channelLayer.backgroundColor = NSColor.systemGray.withAlphaComponent(0.3).cgColor
            channelLayer.cornerRadius = 6
            layer?.addSublayer(channelLayer)
            channelNumber += 1
        }
    }

    func convertPointToFrame(_ point: NSPoint) -> UInt64 {
        let scaledPoint = convertToBacking(point)
        
        return (scaledPoint.x < 0) ? 0 : UInt64(scaledPoint.x) * UInt64(framesPerPixel)
    }
    
    func convertFrameToPoint(_ frame: UInt64) -> NSPoint {
        let scaledPoint = NSPoint(x: Double(frame / UInt64(framesPerPixel)), y: 0.0)
        return convertFromBacking(scaledPoint)
    }
}
