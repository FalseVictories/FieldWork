import SwiftUI
import Marlin

public struct SampleView: NSViewRepresentable {
    public let sample: Sample
    
    public init(sample: Sample) {
        self.sample = sample
    }
    
    public func makeNSView(context: Context) -> AppKitSampleView {
        AppKitSampleView(withSample: sample)
    }
    
    public func updateNSView(_ nsView: AppKitSampleView, context: Context) {
    }
}
