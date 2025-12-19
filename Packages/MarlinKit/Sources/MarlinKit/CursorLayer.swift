import QuartzCore

class CursorLayer: CALayer {
    override init() {
        super.init()
        
#if os(macOS)
        backgroundColor = PlatformColor.controlAccentColor.cgColor
#elseif os(iOS)
        backgroundColor = PlatformColor.tintColor.cgColor
#endif
        zPosition = AdornmentLayerPriority.cursor
        anchorPoint = .init(x: 0, y: 0)
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
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
