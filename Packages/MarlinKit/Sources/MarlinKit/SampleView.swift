import SwiftUI
import Marlin

#if os(macOS)
public typealias PlatformViewControllerRepresentable = NSViewRepresentable
#elseif os(iOS)
public typealias PlatformViewControllerRepresentable = UIViewRepresentable
#endif

public struct SampleView: PlatformViewControllerRepresentable {
    public let sample: Sample
    
    public init(sample: Sample) {
        self.sample = sample
    }
    #if os(macOS)
    public func makeNSView(context: Context) -> AppKitSampleView {
        AppKitSampleView()
    }
    
    public func updateNSView(_ viewController: AppKitSampleView,
                                       context: Context) {
        viewController.sample = sample
    }
    #elseif os(iOS)
    public func makeUIView(context: Context) -> UIKitSampleView {
        UIKitSampleView()
    }
    
    public func updateUIView(_ uiViewController: UIKitSampleView,
                                       context: Context) {
        uiViewController.sample = sample
    }
    #endif
}
