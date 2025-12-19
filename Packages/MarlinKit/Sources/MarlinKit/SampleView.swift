import SwiftUI
import Marlin

#if os(macOS)
public typealias PlatformViewControllerRepresentable = NSViewRepresentable
#elseif os(iOS)
public typealias PlatformViewControllerRepresentable = UIViewRepresentable
#endif

public struct SampleView: PlatformViewControllerRepresentable {
    public let sample: Sample
    @Binding public var framesPerPixel: UInt
    
    public init(sample: Sample,
                framesPerPixel: Binding<UInt>) {
        self.sample = sample
        self._framesPerPixel = framesPerPixel
    }
    
    #if os(macOS)
    public func makeNSView(context: Context) -> AppKitSampleView {
        let sampleView = AppKitSampleView()
        sampleView.sample = sample
        return sampleView
    }
    
    public func updateNSView(_ view: AppKitSampleView,
                             context: Context) {
        view.setFramesPerPixel(framesPerPixel)
    }
    
    #elseif os(iOS)
    public func makeUIView(context: Context) -> UIKitSampleView {
        let sampleView = UIKitSampleView()
        sampleView.sample = sample
        return sampleView
    }
    
    public func updateUIView(_ uiView: UIKitSampleView,
                             context: Context) {
        uiView.setFramesPerPixel(Int(framesPerPixel))
    }
    #endif
}
