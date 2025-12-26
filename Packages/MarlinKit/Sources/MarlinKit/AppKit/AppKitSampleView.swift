#if os(macOS)
import AppKit

import Marlin

public final class AppKitSampleView: NSView {
    private let cursorLayer: CALayer
    private var waveformLayers: [WaveformLayer] = []
    
    private var selecting: Bool = false
    private var hasSelection: Bool = false
    
    private var dragEvent: NSEvent?
    private var extending: SelectionExtendingDirection = .end
    
    @Invalidating(.layout)
    var selection: Selection = .zero
    
    private var selectionBackground: CALayer?
    private var selectionOutline: CALayer?
    
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

    private var framesPerPixel: UInt = 256 {
        didSet {
            if framesPerPixel != oldValue {
                invalidateIntrinsicContentSize()
                
                for waveformLayer in waveformLayers {
                    waveformLayer.framesPerPixel = framesPerPixel
                }
                needsLayout = true
            }
        }
    }
    
    public func setFramesPerPixel(_ fpp: UInt) {
        if fpp < 1 {
            framesPerPixel = 1
        } else if fpp > 2048 {
            framesPerPixel = 2048
        } else {
            framesPerPixel = fpp
        }
    }
    
    var cursorFrame: UInt64 = 0 {
        didSet {
            if cursorFrame != oldValue {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                cursorLayer.position = convertFrameToPoint(cursorFrame)
                CATransaction.commit()
                
                clearSelection()
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
    
    /*
    public override func mouseDown(with event: NSEvent) {
        let locationInView = convert(event.locationInWindow, from: nil)
        if event.buttonNumber == 0 {
            cursorFrame = convertPointToFrame(locationInView)
        }
    }
     */
    
    public override func mouseDown(with event: NSEvent) {
        print("Left mouse down")
        let locationInView = convert(event.locationInWindow, from: nil)
        
        var selectionRect = selectionToRect(selection: selection)
        
        var mouseLoc = locationInView
        let startPoint = locationInView
        var lastPoint = locationInView
        
        var insideSelection = false
        
        // Need to handle resizing selection: see marlinx
        
        let possibleStartFrame = convertPointToFrame(startPoint)
        insideSelection = selection.frameIsInsideSelection(possibleStartFrame)
        //        possibleStartFrame = zxFrameFromFrame()
        
        // Grab the mouse and handle everything in a modal event loop
        let eventMask: NSEvent.EventTypeMask = [.leftMouseUp, .leftMouseDragged, .periodic]
        var dragged = false
        var timerOn = false
        
        var nextEvent = window?.nextEvent(matching: eventMask)
        while nextEvent != nil {
            if let nextEvent {
                switch nextEvent.type {
                case .periodic:
                    if let dragEvent {
                        if !insideSelection {
                            let locationInView = convert(nextEvent.locationInWindow, from: nil)
                            extendSelection(toFrame: convertPointToFrame(locationInView))
                        } else {
                            let newMouseLoc = convert(dragEvent.locationInWindow, from:nil)
                            let dx = newMouseLoc.x - lastPoint.x
                            let scaleDX = convertToBacking(NSPoint(x: dx, y: 0))
                            
                            moveSelectionByOffset(scaleDX.x)
                            lastPoint = newMouseLoc
                        }
                        autoscroll(with: dragEvent)
                    }
                    break
                    
                case .leftMouseDragged:
                    if !dragged && /* dragHandle == DragHandleNone && */ !insideSelection {
                        if !selection.isEmpty {
                            clearSelection()
                        }
                    }
                    mouseLoc = convert(nextEvent.locationInWindow, from: nil)
                    if !NSMouseInRect(mouseLoc, visibleRect, false) {
                        // not inside the visible rectangle, we need to enable periodic events
                        // to keep scrolling
                        if !timerOn {
                            NSEvent.startPeriodicEvents(afterDelay: 0.1, withPeriod: 0.1)
                            timerOn = true
                        }
                        
                        dragEvent = nextEvent
                        break
                    } else if timerOn {
                        // Mouse is inside the visible rectangle, so need to stop the timer
                        NSEvent.stopPeriodicEvents()
                        timerOn = false
                        dragEvent = nil
                    }
                    
                    if mouseLoc.x != startPoint.x {
                        dragged = true
                        if !insideSelection {
                            if selection.isEmpty {
                                createSelectionLayers()
                                cursorLayer.isHidden = true
                            }
                            
                            let locationInView = convert(nextEvent.locationInWindow, from: nil)
                            extendSelection(toFrame: convertPointToFrame(locationInView))
                        } else {
                            let dx = mouseLoc.x - lastPoint.x
                            let scaledDX = convertToBacking(NSPoint(x: dx, y: 0))
                            moveSelectionByOffset(scaledDX.x)
                            
                            lastPoint = mouseLoc
                        }
                    }
                    break
                    
                case .leftMouseUp:
                    NSEvent.stopPeriodicEvents()
                    timerOn = false
                    dragEvent = nil
                    
                    mouseLoc = convert(nextEvent.locationInWindow, from: nil)
                    if !insideSelection {
                        // If we weren't inside a selection, then we were in one of the tracking areas.
                        // Work out which one.
                        /*
                         if (mouseLoc.x < startPoint.x) {
                         _dragHandle = DragHandleStart;
                         } else if (mouseLoc.x > startPoint.x) {
                         _dragHandle = DragHandleEnd;
                         }
                         */
                    }
                    
                    if !dragged {
                        if event.clickCount == 2 {
                            selectRegionContainingFrame(possibleStartFrame)
                            return
                        } else if event.clickCount == 3 {
                            selectAll()
                            return
                        }
                        
                        clearSelection()
                        //                    selectionChanged()
                        
                        cursorFrame = possibleStartFrame
                    }
                    return
                    
                default:
                    break
                }
            }
            
            nextEvent = window?.nextEvent(matching: eventMask)
        }
        dragEvent = nil
    }
    
    public override func mouseUp(with event: NSEvent) {
        
    }
    
    public override func mouseMoved(with event: NSEvent) {
        
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
            let channelLayer = WaveformLayer(channel: channel,
                                             initialFramesPerPixel: framesPerPixel,
                                             strokeColor: Self.channelColors[channelNumber % Self.channelColors.count])
            
            channelLayer.zPosition = AdornmentLayerPriority.waveform
            layer?.addSublayer(channelLayer)
            channelNumber += 1
            
            waveformLayers.append(channelLayer)
        }
    }
}

// - MARK: Selection
private extension AppKitSampleView {
    func createSelectionLayers() {
        let selectionBackground = CALayer()
        selectionBackground.backgroundColor = NSColor.tertiarySystemFill.cgColor
        selectionBackground.cornerRadius = 6
        selectionBackground.zPosition = AdornmentLayerPriority.selectionBackground
        
        let selectionOutline = CALayer()
        selectionOutline.borderColor = NSColor.selectedTextBackgroundColor.cgColor
        selectionOutline.cornerRadius = 6
        selectionOutline.borderWidth = 2
        selectionOutline.zPosition = AdornmentLayerPriority.selection
        
        layer?.addSublayer(selectionBackground)
        layer?.addSublayer(selectionOutline)
        
        self.selectionBackground = selectionBackground
        self.selectionOutline = selectionOutline
    }
    
    func clearSelection() {
        selectionBackground?.removeFromSuperlayer()
        selectionOutline?.removeFromSuperlayer()
        selection = .zero
        cursorLayer.isHidden = false
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
    
    /*
    func resizeSelection(_ event: NSEvent) {
        let endPoint = convert(event.locationInWindow, from: nil)
        var tmp = convertPointToFrame(endPoint)
        var otherEnd: UInt64
        
        let oldSelectionRect = selectionToRect(selection: selection)
        
        // tmp = zxFrameForFrame(tmp)
        
        if tmp >= sample!.numberOfFrames {
            tmp = sample!.numberOfFrames - 1
        }
        
        // Handle handles
        if selection.isEmpty {
            otherEnd = tmp
        } else {
            otherEnd = selectionDirection == .left ? selection.selectedRange.upperBound : selection.selectedRange.lowerBound
        }
        
        let newDirection: SelectionDirection = (tmp < otherEnd) ? .left : .right;
        let directionChange = newDirection != selectionDirection
        
        let startFrame: UInt64
        let endFrame: UInt64
        if (otherEnd < tmp) {
            startFrame = otherEnd
            endFrame = tmp
        } else {
            startFrame = tmp
            endFrame = otherEnd
        }
        
        selectionDirection = newDirection
        
        delegate?.selectionChanged(selection: Selection(selectedRange: startFrame...endFrame))
    }
     */
    
    func moveSelectionByOffset(_ offset: CGFloat) {
        /*
         NSUInteger offsetFrames = offset * _framesPerPixel;
         NSRect oldSelectionRect = [self selectionToRect];
         NSUInteger frameCount = _selectionEndFrame - _selectionStartFrame;
         
         _selectionStartFrame += offsetFrames;
         _selectionEndFrame += offsetFrames;
         
         if (((NSInteger)_selectionStartFrame) < 0) {
         _selectionStartFrame = 0;
         _selectionEndFrame = frameCount;
         } else if (_selectionEndFrame >= [_sample numberOfFrames]) {
         _selectionEndFrame = [_sample numberOfFrames] - 1;
         _selectionStartFrame = _selectionEndFrame - frameCount;
         }
         
         _selectionStartFrame = [self zxFrameForFrame:_selectionStartFrame];
         _selectionEndFrame = [self zxFrameForFrame:_selectionEndFrame];
         
         NSRect newSelectionRect = [self selectionToRect];
         
         [self updateSelection:newSelectionRect
         oldSelectionRect:oldSelectionRect];
         */
    }
    
    func selectRegionContainingFrame(_ frame: UInt64) {
        
    }
    
    func selectAll() {
        if let sample = sample {
            selection = Selection(0...sample.numberOfFrames)
        }
    }
}

// - MARK: Helpers
private extension AppKitSampleView {
    func convertPointToFrame(_ point: NSPoint) -> UInt64 {
        let scaledPoint = convertToBacking(point)
        
        return (scaledPoint.x < 0) ? 0 : UInt64(scaledPoint.x) * UInt64(framesPerPixel)
    }
    
    func convertFrameToPoint(_ frame: UInt64) -> CGPoint {
        let scaledPoint = CGPoint(x: Double(frame / UInt64(framesPerPixel)), y: 0)
        return convertFromBacking(scaledPoint)
    }
    
    func selectionToRect(selection: Selection) -> CGRect {
        if selection.isEmpty {
            return .zero
        }
        
        let startPoint = convertFrameToPoint(selection.selectedRange.lowerBound)
        let selectionFrameWidth = selection.selectedRange.upperBound - selection.selectedRange.lowerBound
        let selectionWidth = convertFrameToPoint(selectionFrameWidth)
        
        return CGRect(x: startPoint.x, y: 0,
                      width: selectionWidth.x, height: bounds.size.height)
    }
}
#endif // os(macOS)
