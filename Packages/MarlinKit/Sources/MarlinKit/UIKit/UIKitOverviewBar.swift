#if os(iOS)
import UIKit
import Marlin

public final class UIKitOverviewBar : UIView {
    private var waveformLayers: [WaveformLayer] = []
    private var selectionBackground: CALayer?
    private var selectionOutline: CALayer?

    private var framesPerPixel: UInt = 256 {
        didSet {
            if oldValue != framesPerPixel {
                waveformLayers.forEach {
                    $0.framesPerPixel = framesPerPixel
                }
            }
        }
    }

    @Invalidating(.layout)
    var selection = Selection.zero
    func setSelection(newSelection: Selection) {
        if selection != newSelection {
            if selection == .zero {
                createSelectionLayers()
            }

            selection = newSelection
            
            if selection == .zero {
                selectionBackground?.removeFromSuperlayer()
                selectionOutline?.removeFromSuperlayer()
                selectionBackground = nil
                selectionOutline = nil
            }
        }
    }
    
    var sampleLoadedObserver: NSObjectProtocol?
    var sample: Sample? {
        didSet {
            guard let sample else {
                return
            }
            
            if sample.isLoaded {
                invalidateIntrinsicContentSize()
                setupWaveformLayers()
            } else {
//                sampleLoadedObserver = NotificationCenter.default
//                    .addObserver(forName: .sampleDidLoadNotification, object: sample,
//                                 queue: OperationQueue.main) { note in
//                        self.invalidateIntrinsicContentSize()
//                        self.needsDisplay = true
//                    }
            }
        }
    }

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.required, for: .vertical)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 64)
    }
    
    public override var frame: CGRect {
        didSet {
            guard let sample, frame.size.width > 0 else {
                return
            }
            
            framesPerPixel = UInt(sample.numberOfFrames / UInt64(frame.size.width))
        }
    }

    public override func layoutSublayers(of layer: CALayer) {
        guard let sample, !sample.channels.isEmpty else {
            return
        }
        
        let channelCount = sample.channels.count
        
        let channelHeight = (Int(frame.height) - (5 * (channelCount - 1))) / channelCount
        
        for (channelNumber, waveformLayer) in waveformLayers.enumerated() {
            // Flip the channel positions so channel 0 is at the top and channel 1 below
            let channelY = Int(frame.height) - (channelHeight * (channelNumber + 1) + (5 * channelNumber))
            
            waveformLayer.frame = CGRect(x: 0, y: channelY,
                                         width: Int(bounds.width), height: channelHeight)
        }
        
        if let selectionBackground, let selectionOutline {
            let startPoint = convertFrameToPoint(selection.selectedRange.lowerBound)
            let endPoint = convertFrameToPoint(selection.selectedRange.upperBound)
            
            let selectionFrame = CGRect(x: startPoint.x, y: 0,
                                        width: endPoint.x - startPoint.x,
                                        height: frame.height)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            selectionBackground.frame = selectionFrame
            selectionOutline.frame = selectionFrame
            
            CATransaction.commit()
        }
    }
}

extension UIKitOverviewBar {
    func setupWaveformLayers() {
        guard let sample else {
            return
        }
        
        waveformLayers = []
        
        for channel in sample.channels {
            let channelLayer = WaveformLayer(channel: channel,
                                             initialFramesPerPixel: framesPerPixel)
            
            channelLayer.zPosition = AdornmentLayerPriority.waveform
            layer.addSublayer(channelLayer)
            
            waveformLayers.append(channelLayer)
        }
    }
    
    func createSelectionLayers() {
        let selectionBackground = CALayer()
        selectionBackground.backgroundColor = knownCGColor(.selectionBackground)
        selectionBackground.cornerRadius = 6
        selectionBackground.zPosition = AdornmentLayerPriority.selectionBackground
        
        let selectionOutline = CALayer()
        selectionOutline.borderColor = knownCGColor(.selectionOutline)
        selectionOutline.cornerRadius = 6
        selectionOutline.borderWidth = 2
        selectionOutline.zPosition = AdornmentLayerPriority.selection
        
        layer.addSublayer(selectionBackground)
        layer.addSublayer(selectionOutline)
        
        self.selectionBackground = selectionBackground
        self.selectionOutline = selectionOutline
    }
    
    func convertFrameToPoint(_ frame: UInt64) -> CGPoint {
        let scaledPoint = CGPoint(x: Double(frame / UInt64(framesPerPixel)), y: 0)
        return scaledPoint
    }
}
#endif // os(iOS)
