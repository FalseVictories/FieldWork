#if os(macOS)
import AppKit

public final class AppKitSampleScrollView: NSScrollView {
    public let sampleView: AppKitSampleView
    
    override init(frame frameRect: NSRect) {
        sampleView = AppKitSampleView()
        sampleView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: frameRect)
        
        documentView = sampleView
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: sampleView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: sampleView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: sampleView.bottomAnchor)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif // os(macOS)
