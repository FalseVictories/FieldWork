import SwiftUI
import Marlin

public struct SampleView: PlatformViewControllerRepresentable {
    public let sample: Sample
    @Binding public var framesPerPixel: UInt
    @Binding public var caretPosition: UInt64
    @Binding public var selection: Selection
    
    public init(sample: Sample,
                framesPerPixel: Binding<UInt>,
                caretPosition: Binding<UInt64>,
                selection: Binding<Selection>) {
        self.sample = sample
        self._framesPerPixel = framesPerPixel
        self._caretPosition = caretPosition
        self._selection = selection
    }
    
    #if os(macOS)
    public func makeNSView(context: Context) -> AppKitSampleScrollView {
        return makeSampleView(context: context)
    }
    
    public func updateNSView(_ view: AppKitSampleScrollView,
                             context: Context) {
        updateSampleView(view, context: context)
    }
    
    #elseif os(iOS)
    public func makeUIView(context: Context) -> UIKitSampleScrollView {
        makeSampleView(context: context)
    }
    
    public func updateUIView(_ uiView: UIKitSampleScrollView,
                             context: Context) {
        updateSampleView(uiView, context: context)
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
        
        public func selectionChanged(to selection: Selection) {
            parent.selection = selection
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

private extension SampleView {
    func makeSampleView(context: Context) -> PlatformScrollView {
        let scrollView = PlatformScrollView()
        scrollView.sampleView.sample = sample
        scrollView.sampleView.delegate = context.coordinator
        
        return scrollView
    }
    
    func updateSampleView(_ view: PlatformScrollView, context: Context) {
        let sampleView = view.sampleView
        sampleView.setFramesPerPixel(framesPerPixel)
        sampleView.cursorFrame = caretPosition
        sampleView.selection = selection
    }
}
