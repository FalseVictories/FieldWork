import AppKit
import Marlin

final class AppKitSampleViewController: NSViewController {
    let sampleView: AppKitSampleView = .init()

    override func viewDidLoad() {
        view.addSubview(sampleView)
        sampleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: sampleView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: sampleView.trailingAnchor),
            view.topAnchor.constraint(equalTo: sampleView.topAnchor),
            view.bottomAnchor.constraint(equalTo: sampleView.bottomAnchor)
        ])
    }
    
    override var representedObject: Any? {
        didSet {
            sampleView.sample = representedObject as? Sample
        }
    }
}
