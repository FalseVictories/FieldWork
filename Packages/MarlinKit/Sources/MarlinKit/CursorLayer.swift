import QuartzCore
import SwiftUI

class CursorLayer: CALayer {
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
        anchorPoint = .init(x: 0, y: 0)
  
        setupFadeAnimation()
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
            cursorLayer.anchorPoint = .init(x: 0, y: 0)
        }
        setupFadeAnimation()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CursorLayer {
    public func restartFade() {
        removeAllAnimations()
        setupFadeAnimation()
    }
}

private extension CursorLayer {
    func setupFadeAnimation() {
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
