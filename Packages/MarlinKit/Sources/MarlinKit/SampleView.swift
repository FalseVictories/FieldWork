import SwiftUI
import Marlin

public struct SampleView: NSViewControllerRepresentable {
    public let sample: Sample
    
    public init(sample: Sample) {
        self.sample = sample
    }
    
    public func makeNSViewController(context: Context) -> NSViewController {
        AppKitSampleViewController()
    }
    
    public func updateNSViewController(_ viewController: NSViewController,
                                       context: Context) {
        viewController.representedObject = sample
    }
}
