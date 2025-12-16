#if os(macOS)
import AppKit

import Marlin

public class AppKitSampleView: NSView {
    private let cursorLayer: CALayer
    private var waveformLayers: [CALayer] = []
    
    var sample: Sample? {
        didSet {
            guard let sample else {
                return
            }
            
            if sample.isLoaded {
                invalidateIntrinsicContentSize()
                setupWaveformLayers()

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
    
    var cursorFrame: UInt64 = 0 {
        didSet {
            if cursorFrame != oldValue {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                cursorLayer.position = convertFrameToPoint(cursorFrame)
                CATransaction.commit()
            }
        }
    }
        
    init(withSample sample: Sample? = nil) {
        cursorLayer = CursorLayer()
        
        self.sample = sample
        super.init(frame: .zero)
        
        self.wantsLayer = true
        layer?.addSublayer(cursorLayer)
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
        let channelHeight = (Int(frame.height) - (5 * (channelCount - 1))) / channelCount
        
        for waveformLayer in waveformLayers {
            // Flip the channel positions so channel 0 is at the top and channel 1 below
            let channelY = Int(frame.height) - (channelHeight * (channelNumber + 1) + (5 * channelNumber))
            
            waveformLayer.frame = CGRect(x: 0, y: channelY,
                                         width: Int(width), height: channelHeight)
            channelNumber += 1
        }
        
        let cursorPoint = convertFrameToPoint(cursorFrame)
        cursorLayer.frame = CGRect(x: cursorPoint.x, y: 0, width: 1, height: frame.height)
    }
    
    public override func mouseDown(with event: NSEvent) {
        let locationInView = convert(event.locationInWindow, from: nil)
        if event.buttonNumber == 0 {
            cursorFrame = convertPointToFrame(locationInView)
        }
    }
}

private extension AppKitSampleView {
    static var channelColors: [PlatformColor] = [.systemRed, .systemBlue, .systemGreen]
    func setupWaveformLayers() {
        guard let sample else {
            return
        }
        
        waveformLayers = []
        
        var channelNumber = 0
        for channel in sample.channels {
            let channelLayer = SampleChannelLayer(channel: channel, strokeColor: Self.channelColors[channelNumber % Self.channelColors.count])
            
            channelLayer.zPosition = AdornmentLayerPriority.waveform
            channelLayer.backgroundColor = PlatformColor.systemGray.withAlphaComponent(0.3).cgColor
            channelLayer.cornerRadius = 6
            layer?.addSublayer(channelLayer)
            channelNumber += 1
            
            waveformLayers.append(channelLayer)
        }
    }

    func convertPointToFrame(_ point: NSPoint) -> UInt64 {
        let scaledPoint = convertToBacking(point)
        
        return (scaledPoint.x < 0) ? 0 : UInt64(scaledPoint.x) * UInt64(framesPerPixel)
    }
    
    func convertFrameToPoint(_ frame: UInt64) -> CGPoint {
        let scaledPoint = CGPoint(x: Double(frame / UInt64(framesPerPixel)), y: 0)
        return convertFromBacking(scaledPoint)
    }
}
#endif
