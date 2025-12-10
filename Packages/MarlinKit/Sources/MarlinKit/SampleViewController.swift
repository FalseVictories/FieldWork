#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

import Marlin

public final class SampleViewController: PlatformViewController {
    let sampleView: PlatformSampleView = .init()

    public override func viewDidLoad() {
        view.addSubview(sampleView)
        sampleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: sampleView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: sampleView.trailingAnchor),
            view.topAnchor.constraint(equalTo: sampleView.topAnchor),
            view.bottomAnchor.constraint(equalTo: sampleView.bottomAnchor)
        ])
    }
    
    var sample: Sample? {
        didSet {
            sampleView.sample = sample
        }
    }
}
