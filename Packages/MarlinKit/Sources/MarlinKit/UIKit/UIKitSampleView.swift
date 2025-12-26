#if os(iOS)
import UIKit

import Marlin

public class UIKitSampleView: UIView {
    static let autoScrollEdgeToleranceDefault: CGFloat = 80.0;
    static let autoScrollMaxVelocityDefault: CGFloat = 4.0;
    static let autoScrollVelocityDefault: CGFloat = 0.1;

    private let cursorLayer: CursorLayer
    private var waveformLayers: [WaveformLayer] = []
    
    private var summedMagnificationLevel: UInt = 256;
    private var previousPinchScale: CGFloat = 0
    private var currentPinchScale: CGFloat = 0

    private var selecting: Bool = false
    private var hasSelection: Bool = false
    
    private var extending: SelectionExtendingDirection = .end

    @Invalidating(.layout)
    var selection: Selection = .zero

    private var selectionBackground: CALayer?
    private var selectionOutline: CALayer?
    private var selectionScrollTimer: Timer?
    private var lastDragPoint: CGPoint = .zero
    private var lastDragFrame: UInt64 = 0
    
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
    
    private var framesPerPixel: Int = 256 {
        didSet {
            if framesPerPixel != oldValue {
                invalidateIntrinsicContentSize()
                setNeedsDisplay()
                setNeedsLayout()
                
                for waveformLayer in waveformLayers {
                    waveformLayer.framesPerPixel = UInt(framesPerPixel)
                }
            }
        }
    }
    
    func setFramesPerPixel(_ fpp: Int) {
        if fpp < 1 {
            framesPerPixel = 1
        } else if fpp > 2048 {
            framesPerPixel = 2048
        } else {
            framesPerPixel = fpp
        }
    }
  
    @Invalidating(.layout)
    var cursorFrame: UInt64 = 0 {
        didSet {
            if cursorFrame != oldValue {
                cursorLayer.isHidden = false
                
                resetSelection()
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
        guard let sample else {
            return UIView.noIntrinsicMetric
        }

        return ceil((CGFloat(sample.numberOfFrames) / CGFloat(framesPerPixel)) / contentScaleFactor)
    }
    
    @Invalidating(.intrinsicContentSize)
    var height: CGFloat = UIView.noIntrinsicMetric
    
    public override var intrinsicContentSize: CGSize {
        return .init(width: width, height: height)
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
                                         width: Int(width),
                                         height: channelHeight)
            
            channelNumber += 1
        }
        
        let cursorPoint = convertFrameToPoint(cursorFrame)
        cursorLayer.frame = CGRect(x: cursorPoint.x, y: 0, width: 1, height: frame.height)
        
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

private extension UIKitSampleView {
    static var channelColors: [PlatformColor] = [.systemRed, .systemBlue, .systemGreen]
    func setupLayers() {
        guard let sample else {
            return
        }
        
        var channelNumber = 0
        for channel in sample.channels {
            let waveformLayer = WaveformLayer(channel: channel,
                                              initialFramesPerPixel: UInt(framesPerPixel))
            
            waveformLayer.zPosition = AdornmentLayerPriority.waveform
            waveformLayers.append(waveformLayer)
            
            layer.addSublayer(waveformLayer)
            
            channelNumber += 1
        }
    }
}

// - MARK: Gesture recognisers
private extension UIKitSampleView {
    func setupGestureRecognisers() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(handleTapGesture))
        addGestureRecognizer(tapGesture)
        
        let dblTapGesture = UITapGestureRecognizer(target: self,
                                                   action: #selector(handleDoubleTapGesture))
        dblTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(dblTapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self,
                                                    action: #selector(handlePinchGesture))
        addGestureRecognizer(pinchGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self,
                                                            action: #selector(handleLongPressGesture))
        addGestureRecognizer(longPressGesture)
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
    
    @objc
    func handleDoubleTapGesture(recogniser: UITapGestureRecognizer) {
        guard recogniser.view != nil else {
            return
        }
    }
    
    @objc
    func handlePinchGesture(recogniser: UIPinchGestureRecognizer) {
        guard recogniser.view != nil else {
            return
        }
        
        if recogniser.state == .began {
            previousPinchScale = recogniser.scale
        } else if recogniser.state == .changed {
            currentPinchScale += (recogniser.scale - previousPinchScale)
            previousPinchScale = recogniser.scale
            if abs(currentPinchScale) > 0.25 {
                let newFPP = Double(framesPerPixel) * (currentPinchScale > 0 ? 0.5 : 2)
                
                setFramesPerPixel(Int(newFPP))
                currentPinchScale = 0
            }
        }
    }
    
    @objc
    func handleLongPressGesture(recogniser: UILongPressGestureRecognizer) {
        guard recogniser.view != nil, let scrollView = superview as? UIScrollView else {
            return
        }

        switch recogniser.state {
        case .began:
            resetSelection()
            
            selecting = true
            extending = .end
            let startFrame = convertPointToFrame(recogniser.location(in: self))
            selection = .init(startFrame: startFrame, endFrame: startFrame)
            
            // Move cursor to the start frame
            cursorFrame = startFrame
            createSelectionLayers()
            
            layoutIfNeeded() // Force the pending layout so the pulse won't get cancelled
            cursorLayer.pulseCursor()
            
        case .changed:
            let locationInView = recogniser.location(in: self)
            let newSelectionEnd = convertPointToFrame(locationInView)
            extendSelection(toFrame: newSelectionEnd)
            
            cursorLayer.isHidden = true
            
            let locationInScrollview = recogniser.location(in: scrollView)
            
            autoScroll(toLocationInView: locationInView,
                       locationInScrollView: CGPoint(x: locationInScrollview.x - scrollView.contentOffset.x, y: 0),
                       scrollView: scrollView)
            
        case .ended:
            selecting = false
            autoscrollCancelled()
            
        default:
            break
        }
    }
    
    private func autoscrollCancelled() {
        selectionScrollTimer?.invalidate()
        selectionScrollTimer = nil
    }
}

// - MARK: Selection
private extension UIKitSampleView {
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
    
    func resetSelection() {
        selectionBackground?.removeFromSuperlayer()
        selectionOutline?.removeFromSuperlayer()
        selection = .zero
    }
    
    // Extend selection following the value at extending
    // switching the extending direction if necessary
    func extendSelection(toFrame frame: UInt64) {
        guard let sample else {
            return
        }
        
        let frame = min(frame, sample.numberOfFrames - 1)
        
        if selection.isEmpty {
            selection = .init(startFrame: frame, endFrame: frame)
        }
        
        switch extending {
        case .end:
            if frame < selection.selectedRange.lowerBound {
                selection = .init(startFrame: frame, endFrame: selection.selectedRange.lowerBound)
                extending = .start
            } else {
                selection = .init(startFrame: selection.selectedRange.lowerBound, endFrame: frame)
            }
            
        case .start:
            if frame > selection.selectedRange.upperBound {
                selection = .init(startFrame: selection.selectedRange.upperBound, endFrame: frame)
                extending = .end
            } else {
                selection = .init(startFrame: frame, endFrame: selection.selectedRange.upperBound)
            }
        }
    }
}

// - MARK: Drag scroll
private extension UIKitSampleView {
    func autoScroll(toLocationInView locationInView: CGPoint,
                    locationInScrollView: CGPoint,
                    scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset
        
        lastDragPoint = locationInScrollView
        lastDragFrame = convertPointToFrame(locationInView)
        
        extendSelection(toFrame: lastDragFrame)
        
        // If the timer is running then we just need to wait for it to update
        // the selection
        if selectionScrollTimer != nil {
            return
        }
        
        let scrollDelta = dragScrollDelta(locationInScrollView, scrollView: scrollView)
        
        if scrollDelta != .zero {
            let p = CGPoint(x: contentOffset.x + scrollDelta, y: contentOffset.y)
            scrollView.setContentOffset(p, animated: false)
            
            if selectionScrollTimer == nil {
                selectionScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.01,
                                                            repeats: true) { [weak self] _ in
                    guard let self else {
                        return
                    }
                    
                    // Run task on MainActor cos the timer runs on a different thread
                    Task { @MainActor in
                        let scrollDelta = dragScrollDelta(lastDragPoint, scrollView: scrollView)
                        if scrollDelta != .zero {
                            let contentOffset = scrollView.contentOffset
                            let p = CGPoint(x: contentOffset.x + scrollDelta, y: contentOffset.y)

                            scrollView.setContentOffset(p, animated: false)
                            
                            // Add the amount scrolled to the selection
                            let newDragFrame = Int64(lastDragFrame) + Int64(scrollDelta) * Int64(framesPerPixel)
                            
                            lastDragFrame = UInt64(max(newDragFrame, 0))
                            extendSelection(toFrame: lastDragFrame)
                        } else {
                            autoscrollCancelled()
                        }
                    }
                }
            }
        } else {
            autoscrollCancelled()
        }
    }
    
    func dragScrollDelta(_ point: CGPoint, scrollView: UIScrollView) -> CGFloat {
        var deltaX: CGFloat = 0
        
        if point.x < Self.autoScrollEdgeToleranceDefault {
            // Scroll left
            deltaX = -4
        } else if point.x > scrollView.bounds.width - Self.autoScrollEdgeToleranceDefault {
            // scroll right
            deltaX = 4
        } else {
        }
        
        if deltaX != 0.0 {
            if scrollView.contentOffset.x + deltaX < 0.0 {
                deltaX = -scrollView.contentOffset.x;
            } else {
                var maxOffset = scrollView.contentSize.width - scrollView.frame.size.width;
                if maxOffset < 0.0 {
                    maxOffset = 0.0;
                }
                
                if scrollView.contentOffset.x + deltaX > maxOffset {
                    deltaX = maxOffset - scrollView.contentOffset.x;
                }
            }
        }
        
        return deltaX
    }
}

// - MARK: Helpers
private extension UIKitSampleView {
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
