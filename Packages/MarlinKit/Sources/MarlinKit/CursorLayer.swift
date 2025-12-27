import QuartzCore
import SwiftUI

final class CursorLayer: CALayer {
    override var position: CGPoint {
        didSet {
            restartFade()
        }
    }
    
    override init() {
        super.init()
        
#if os(macOS)
        backgroundColor = PlatformColor.controlAccentColor.cgColor
#elseif os(iOS)
        backgroundColor = PlatformColor.tintColor.cgColor
#endif
        zPosition = AdornmentLayerPriority.cursor
        
        // Position the X anchor in the middle of the cursor so the
        // pulse animation expands in both directions from the centre
        anchorPoint = .init(x: 0.5, y: 0)
  
        setupBlinkAnimation()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)

        if let cursorLayer = layer as? CALayer {
#if os(macOS)
            cursorLayer.backgroundColor = PlatformColor.controlAccentColor.cgColor
#elseif os(iOS)
            cursorLayer.backgroundColor = PlatformColor.tintColor.cgColor
#endif
            cursorLayer.zPosition = AdornmentLayerPriority.cursor
            cursorLayer.anchorPoint = .init(x: 0.5, y: 0)
        }
        setupBlinkAnimation()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CursorLayer {
    public func restartFade() {
        removeAllAnimations()
        setupBlinkAnimation()
    }
    
#if os(iOS)
    // scale the cursor up and back down to pulse it
    // not really useful for the mac I don't think
    public func pulseCursor() {
        removeAllAnimations()
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            guard let self else {
                return
            }
            
            self.restartFade()
        }
        
        let pulseAnimation = CAKeyframeAnimation(keyPath: "transform.scale.xy")
        pulseAnimation.duration = 0.3
        pulseAnimation.values = [1, 3, 1]
        pulseAnimation.keyTimes = [0, 0.5, 1]
        
        add(pulseAnimation, forKey:"pulse")
        
        CATransaction.commit()
    }
#endif // os(iOS)
}

private extension CursorLayer {
    /// Setup the animation to blink the cursor
    func setupBlinkAnimation() {
        let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
        fadeAnimation.values = [1, 0, 0, 1]
        fadeAnimation.keyTimes = [0.3, 0.40, 0.6, 0.7]
        fadeAnimation.duration = 1.2
        
        // Repeat forever
        fadeAnimation.repeatCount = .greatestFiniteMagnitude
        fadeAnimation.isRemovedOnCompletion = false
        
        add(fadeAnimation, forKey: "opacity")
    }
}

#if DEBUG && os(macOS)
private class CursorPreviewView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        wantsLayer = true
        
        let cursor = CursorLayer()
        cursor.frame = .init(x: 10, y: 10, width: 1, height: 100)
        layer?.addSublayer(cursor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    CursorPreviewView(frame:.init(x: 0, y: 0, width: 200, height: 200))
}
#endif // DEBUG && os(macOS)
