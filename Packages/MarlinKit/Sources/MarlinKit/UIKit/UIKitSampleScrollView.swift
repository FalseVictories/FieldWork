#if os(iOS)
import UIKit

public final class UIKitSampleScrollView: UIScrollView {
    let sampleView: UIKitSampleView
    
    public override init(frame: CGRect) {
        sampleView = UIKitSampleView()
        
        super.init(frame: frame)
        
        addSubview(sampleView)
        
        translatesAutoresizingMaskIntoConstraints = false
        sampleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: sampleView.leadingAnchor),
            trailingAnchor.constraint(equalTo: sampleView.trailingAnchor),
            topAnchor.constraint(equalTo: sampleView.topAnchor),
            bottomAnchor.constraint(equalTo: sampleView.bottomAnchor),
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // FIXME: Is this the only way to correctly size a scrollview content where
    // height is noIntrinsicMetric?
    override public var frame: CGRect {
        didSet {
            sampleView.height = frame.size.height
        }
    }
}
#endif // os(iOS)
