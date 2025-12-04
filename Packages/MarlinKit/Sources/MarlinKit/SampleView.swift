import SwiftUI
import Marlin

public struct SampleView: NSViewRepresentable {
    public let sample: Sample
    
    public init(sample: Sample) {
        self.sample = sample
    }
    
    public func makeNSView(context: Context) -> AppKitSampleView {
        AppKitSampleView()
    }
    
    public func updateNSView(_ view: AppKitSampleView,
                             context: Context) {
        view.sample = sample
    }
}
