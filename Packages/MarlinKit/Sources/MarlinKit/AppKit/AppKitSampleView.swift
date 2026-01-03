#if os(macOS)
import AppKit

import Marlin

public final class AppKitSampleView: NSView {
    public weak var delegate: (any SampleViewDelegate)?
    
    private let cursorLayer: CALayer
    private var waveformLayers: [WaveformLayer] = []
    
    private var selecting: Bool = false
    private var hasSelection: Bool = false
    
    private var dragEvent: NSEvent?
    private var extending: SelectionExtendingDirection = .end
    
    @Invalidating(.layout)
    var selection: Selection = .zero {
        didSet {
            if selection != oldValue {
                delegate?.selectionChanged(to: selection)
            }
        }
    }
    
    private var selectionBackground: CALayer?
    private var selectionOutline: CALayer?
    
    private var totalMagnification: CGFloat = 0

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
                
                waveformLayers.forEach {
                    $0.framesPerPixel = framesPerPixel
                }
                needsLayout = true
            }
        }
    }
    
    @Invalidating(.layout)
    var cursorFrame: UInt64 = 0 {
        didSet {
            if cursorFrame != oldValue {
                clearSelection()
                delegate?.caretPositionChanged(to: cursorFrame)
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
    
    public override var canBecomeKeyView: Bool {
        true
    }
    
    public override var acceptsFirstResponder: Bool {
        true
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
        
        let channelHeight = (Int(frame.height) - (5 * (channelCount - 1))) / channelCount
        
        for (channelNumber, waveformLayer) in waveformLayers.enumerated() {
            // Flip the channel positions so channel 0 is at the top and channel 1 below
            let channelY = Int(frame.height) - (channelHeight * (channelNumber + 1) + (5 * channelNumber))
            
            waveformLayer.frame = CGRect(x: 0, y: channelY,
                                         width: Int(width), height: channelHeight)
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

// MARK: - Event handling
extension AppKitSampleView {
    // Mouse down starts an event processing loop and handles any
    // subsequent events - move/drag/mouse down/up that happen
    // inside it. If the mouse event leaves the waveform view it can
    // start periodic events to enable scrolling
    public override func mouseDown(with event: NSEvent) {
        let locationInView = convert(event.locationInWindow, from: nil)
        
        var mouseLoc = locationInView
        let startPoint = locationInView
        var lastPoint = locationInView
        
        var insideSelection = false
        
        window?.makeFirstResponder(self)
        
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
                        lastPoint = handleDragEvent(dragEvent,
                                                    withOldLocation: lastPoint,
                                                    insideSelection: insideSelection)

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
                        lastPoint = handleDragEvent(nextEvent,
                                                    withOldLocation: lastPoint,
                                                    insideSelection: insideSelection)
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
                            selectAll(nil)
                            return
                        }
                        
                        clearSelection()
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
    
    private func handleDragEvent(_ event: NSEvent,
                                 withOldLocation lastPoint: CGPoint,
                                 insideSelection: Bool) -> CGPoint {
        let locationInView = convert(event.locationInWindow, from: nil)
        
        if !insideSelection {
            if selection.isEmpty {
                setupSelection()
            }
            
            extendSelection(toFrame: convertPointToFrame(locationInView))
        } else {
            let dx = locationInView.x - lastPoint.x
            moveSelectionByOffset(dx)
        }
        
        return locationInView
    }
    
    public override func magnify(with event: NSEvent) {
        if event.phase == .began {
            totalMagnification = event.magnification
        } else if event.phase == .changed {
            totalMagnification += event.magnification
            
            if abs(totalMagnification) > 0.25 {
                let newFPP = Double(framesPerPixel) * (totalMagnification > 0 ? 0.5 : 2)
                
                notifyFramesPerPixelChanged(UInt(newFPP))
                totalMagnification = 0
            }
        }
    }
    
    public override func keyDown(with event: NSEvent) {
        interpretKeyEvents([event])
    }
    
    public override func moveUp(_ sender: Any?) {
    }
    
    public override func moveDown(_ sender: Any?) {
    }
    
    public override func moveLeft(_ sender: Any?) {
        if selection.isEmpty {
            cursorFrame = UInt64(max(0, Int(cursorFrame) - Int(framesPerPixel)))
            centre(onFrame: cursorFrame)
        } else {
            selection = .init(startFrame: selection.selectedRange.lowerBound - UInt64(framesPerPixel),
                              endFrame: selection.selectedRange.upperBound - UInt64(framesPerPixel))
        }
    }
    
    public override func moveLeftAndModifySelection(_ sender: Any?) {
        if selection.isEmpty {
            let newFrame = UInt64(max(0, Int(cursorFrame) - Int(framesPerPixel)))
            
            setupSelection()
            selection = .init(startFrame: newFrame, endFrame: cursorFrame)

            extending = .start
            centre(onFrame: cursorFrame)
        } else {
            let oldFrame = extending == .start ? selection.selectedRange.lowerBound : selection.selectedRange.upperBound
            let newFrame = UInt64(max(0, Int(oldFrame) - Int(framesPerPixel)))
            extendSelection(toFrame: newFrame)
            
            centre(onFrame: newFrame)
        }
    }
    
    public override func moveRight(_ sender: Any?) {
        guard let sample else {
            return
        }
        
        if selection.isEmpty {
            cursorFrame = UInt64(min(cursorFrame + UInt64(framesPerPixel), sample.numberOfFrames - 1))
            centre(onFrame: cursorFrame)
        } else {
            selection = .init(startFrame: selection.selectedRange.lowerBound + UInt64(framesPerPixel),
                              endFrame: selection.selectedRange.upperBound + UInt64(framesPerPixel))
        }
    }
    
    public override func moveRightAndModifySelection(_ sender: Any?) {
        guard let sample else {
            return
        }
        
        if selection.isEmpty {
            let newFrame = UInt64(min(sample.numberOfFrames - 1, cursorFrame + UInt64(framesPerPixel)))
            
            setupSelection()
            
            extending = .end
            selection = .init(startFrame: cursorFrame, endFrame: newFrame)
            centre(onFrame: newFrame)
        } else {
            let oldFrame = extending == .start ? selection.selectedRange.lowerBound : selection.selectedRange.upperBound

            let newFrame = UInt64(min(sample.numberOfFrames - 1, oldFrame + UInt64(framesPerPixel)))
            extendSelection(toFrame: newFrame)
            centre(onFrame: newFrame)
        }
    }
    
    public override func moveWordRight(_ sender: Any?) {
        // Move to next zero crossing frame
    }
    
    public override func moveWordLeft(_ sender: Any?) {
        // Move to previous zero crossing frame
    }
    
    public override func moveToEndOfParagraph(_ sender: Any?) {
        // Move to next marker
    }
    
    public override func moveToEndOfParagraphAndModifySelection(_ sender: Any?) {
        // Extend selection to next marker
    }
    
    public override func moveToBeginningOfParagraph(_ sender: Any?) {
        // Move to previous marker
    }
    
    public override func moveToBeginningOfParagraphAndModifySelection(_ sender: Any?) {
        // extend selection to previous marker
    }
    
    public override func moveToEndOfDocument(_ sender: Any?) {
        if let sample {
            if selection.isEmpty {
                cursorFrame = sample.numberOfFrames - 1
                centre(onFrame: cursorFrame)
            } else {
                selection = selection.moveSelection(endingOn: sample.numberOfFrames - 1)
                centre(onFrame: selection.selectedRange.upperBound)
            }
        }
    }
    
    public override func moveToEndOfDocumentAndModifySelection(_ sender: Any?) {
        guard let sample else {
            return
        }

        // Extend selection to end of document
        if selection.isEmpty {
            setupSelection()

            selection = .init(startFrame: cursorFrame, endFrame: sample.numberOfFrames - 1)
        } else {
            selection = .init(startFrame: selection.selectedRange.lowerBound,
                              endFrame: sample.numberOfFrames - 1)
        }

        // the last edge moved is the new extending direction
        extending = .end

        centre(onFrame: cursorFrame)
    }
    
    public override func moveToBeginningOfDocument(_ sender: Any?) {
        if selection.isEmpty {
            cursorFrame = 0
            centre(onFrame: cursorFrame)
        } else {
            selection = selection.moveSelection(startingOn: 0)
            centre(onFrame: 0)
        }
    }
    
    public override func moveToBeginningOfDocumentAndModifySelection(_ sender: Any?) {
        if selection.isEmpty {
            setupSelection()
            selection = .init(startFrame: 0, endFrame: cursorFrame)
        } else {
            selection = .init(startFrame: 0, endFrame: selection.selectedRange.upperBound)
        }

        // the last edge moved is the new extending direction
        extending = .start

        centre(onFrame: 0)
    }
    
    public override func selectAll(_ sender: Any?) {
        if let sample {
            if selection.isEmpty {
                setupSelection()
            }
            selection = .init(startFrame: 0, endFrame: sample.numberOfFrames - 1)
        }
    }
    
    public override func centerSelectionInVisibleArea(_ sender: Any?) {
        if selection.isEmpty {
            return
        }
        
        let middleFrame = selection.selectedRange.lowerBound + UInt64(selection.selectedRange.count / 2)
        centre(onFrame: middleFrame)
    }
}

// MARK: - Public API
extension AppKitSampleView {
    public func setFramesPerPixel(_ fpp: UInt) {
        if fpp < 1 {
            framesPerPixel = 1
        } else if fpp > 2048 {
            framesPerPixel = 2048
        } else {
            framesPerPixel = fpp
        }
    }
}

private extension AppKitSampleView {
    func setupWaveformLayers() {
        guard let sample else {
            return
        }
        
        waveformLayers = []
        
        for channel in sample.channels {
            let channelLayer = WaveformLayer(channel: channel,
                                             initialFramesPerPixel: framesPerPixel)
            
            channelLayer.zPosition = AdornmentLayerPriority.waveform
            layer?.addSublayer(channelLayer)
            
            waveformLayers.append(channelLayer)
        }
    }
    
    func centre(onFrame frame: UInt64) {
        let framePoint = convertFrameToPoint(frame)
        let scrollPoint = CGPoint(x: framePoint.x - visibleRect.width / 2, y: framePoint.y)
        scroll(scrollPoint)
    }
    
    func notifyFramesPerPixelChanged(_ framesPerPixel: UInt) {
        delegate?.framesPerPixelChanged(to: framesPerPixel)
    }
}

// - MARK: Selection
private extension AppKitSampleView {
    private func setupSelection() {
        selectionBackground?.removeFromSuperlayer()
        selectionOutline?.removeFromSuperlayer()
        
        // Started a new selection, so create selection layers
        // and turn off the caret
        createSelectionLayers()
        cursorLayer.isHidden = true
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
        
        layer?.addSublayer(selectionBackground)
        layer?.addSublayer(selectionOutline)
        
        self.selectionBackground = selectionBackground
        self.selectionOutline = selectionOutline
    }
    
    func clearSelection() {
        selectionBackground?.removeFromSuperlayer()
        selectionOutline?.removeFromSuperlayer()
        
        selectionBackground = nil
        selectionOutline = nil
        
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

    func moveSelectionByOffset(_ offset: CGFloat) {
        guard let sample else {
            return
        }
        
        let offsetFrames = Int(offset) * Int(framesPerPixel)

        // Can't drag to shrink the selection by going outside of
        // valid range
        let newStartFrame: Int64 = Int64(selection.selectedRange.lowerBound) + Int64(offsetFrames)
        if newStartFrame < 0 {
            return
        }
        
        let newEndFrame = Int64(selection.selectedRange.upperBound) + Int64(offsetFrames)
        if newEndFrame >= sample.numberOfFrames {
            return
        }
        
        selection = .init(startFrame: UInt64(newStartFrame), endFrame: UInt64(newEndFrame))
    }
    
    func selectRegionContainingFrame(_ frame: UInt64) {
        
    }
}

// - MARK: Helpers
private extension AppKitSampleView {
    func convertPointToFrame(_ point: NSPoint) -> UInt64 {
        let scaledPoint = point
        return (scaledPoint.x < 0) ? 0 : UInt64(scaledPoint.x) * UInt64(framesPerPixel)
    }
    
    func convertFrameToPoint(_ frame: UInt64) -> CGPoint {
        let scaledPoint = CGPoint(x: Double(frame / UInt64(framesPerPixel)), y: 0)
        return scaledPoint
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
