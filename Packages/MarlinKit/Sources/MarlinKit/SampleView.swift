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
    @Binding public var caretPosition: UInt64
    
    public init(sample: Sample,
                framesPerPixel: Binding<UInt>,
                caretPosition: Binding<UInt64>) {
        self.sample = sample
        self._framesPerPixel = framesPerPixel
        self._caretPosition = caretPosition
    }
    
    #if os(macOS)
    public func makeNSView(context: Context) -> AppKitSampleScrollView {
        let scrollView = AppKitSampleScrollView()
        scrollView.sampleView.sample = sample
        scrollView.sampleView.delegate = context.coordinator
        
        return scrollView
    }
    
    public func updateNSView(_ view: AppKitSampleScrollView,
                             context: Context) {
        let sampleView = view.sampleView
        sampleView.setFramesPerPixel(framesPerPixel)
        sampleView.cursorFrame = caretPosition
    }
    
    #elseif os(iOS)
    public func makeUIView(context: Context) -> UIKitSampleScrollView {
        let scrollView = UIKitSampleScrollView(frame: .zero)
        scrollView.sampleView.sample = sample
        scrollView.sampleView.delegate = context.coordinator

        return scrollView
    }
    
    public func updateUIView(_ uiView: UIKitSampleScrollView,
                             context: Context) {
        let sampleView = uiView.sampleView
        sampleView.setFramesPerPixel(framesPerPixel)
        sampleView.cursorFrame = caretPosition
    }
    #endif
    
    public class Coordinator : NSObject, SampleViewDelegate {
        var parent: SampleView
        
        init(_ parent: SampleView) {
            self.parent = parent
        }
        
        public func framesPerPixelChanged(to framesPerPixel: UInt) {
            parent.framesPerPixel = framesPerPixel
        }
        
        public func caretPositionChanged(to caretPosition: UInt64) {
            parent.caretPosition = caretPosition
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
