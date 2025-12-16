#if os(iOS)
import UIKit

import Marlin

public class UIKitSampleView: UIView {
    private let cursorLayer: CALayer
    private var waveformLayers: [CALayer] = []
    
    var sample: Sample? {
        didSet {
            guard let sample else {
                return
            }
            
            if sample.isLoaded {
                invalidateIntrinsicContentSize()
                setupLayers()

                setNeedsDisplay()
            } else {
                // FIXME - observe isLoaded changing
            }
        }
    }

    var framesPerPixel: UInt = 256 {
        didSet {
            if framesPerPixel != oldValue {
                invalidateIntrinsicContentSize()
                setNeedsDisplay()
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
        
        layer.addSublayer(cursorLayer)
        
        setupGestureRecognisers()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var width: CGFloat {
        guard let sample = sample else {
            return UIView.noIntrinsicMetric
        }
        
        return ceil(CGFloat(sample.numberOfFrames) / CGFloat(framesPerPixel))
    }
    
    public override var intrinsicContentSize: CGSize {
        return .init(width: width, height: UIView.noIntrinsicMetric)
    }
    
    public override func layoutSublayers(of layer: CALayer) {
        guard let sample, !sample.channels.isEmpty else {
            return
        }
        
        let channelCount = sample.channels.count
        
        var channelNumber = 0
        let channelHeight = (Int(frame.height) - (5 * (channelCount - 1))) / channelCount
        
        for waveformLayer in waveformLayers {
            // Flip the channel positions so channel 0 is at the top and channel 1 below
            let channelY = (channelNumber * (channelHeight + 5))
            waveformLayer.frame = CGRect(x: 0, y: channelY,
                                         width: Int(width), height: channelHeight)
            channelNumber += 1
        }
        
        let cursorPoint = convertFrameToPoint(cursorFrame)
        cursorLayer.frame = CGRect(x: cursorPoint.x, y: 0, width: 1, height: frame.height)
    }
}

private extension UIKitSampleView {
    static var channelColors: [PlatformColor] = [.systemRed, .systemBlue, .systemGreen]
    func setupLayers() {
        guard let sample else {
            return
        }
        
        var channelNumber = 0
        for channel in sample.channels {
            let waveformLayer = SampleChannelLayer(channel: channel, strokeColor: Self.channelColors[channelNumber % Self.channelColors.count])
            
            waveformLayer.backgroundColor = PlatformColor.systemGray.withAlphaComponent(0.3).cgColor
            waveformLayer.zPosition = AdornmentLayerPriority.waveform
            waveformLayer.cornerRadius = 6
            waveformLayer.setNeedsDisplay()
            waveformLayers.append(waveformLayer)
            
            layer.addSublayer(waveformLayer)
            
            channelNumber += 1
        }
    }
    
    func setupGestureRecognisers() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(handleTapGesture))
        addGestureRecognizer(tapGesture)
    }

    @objc
    func handleTapGesture(recogniser: UITapGestureRecognizer) {
        guard recogniser.view != nil else {
            return
        }
        
        if recogniser.state == .ended {
            let locationInView = recogniser.location(in: self)
            cursorFrame = convertPointToFrame(locationInView)
        }
    }
    
    func convertPointToFrame(_ point: CGPoint) -> UInt64 {
        let scaledX = point.x * contentScaleFactor
        
        return (scaledX < 0) ? 0 : UInt64(scaledX) * UInt64(framesPerPixel)
    }
    
    func convertFrameToPoint(_ frame: UInt64) -> CGPoint {
        let x = Double(frame / UInt64(framesPerPixel))
        return CGPoint(x: x / contentScaleFactor, y: 0)
    }
}
#endif
