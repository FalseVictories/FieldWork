import SwiftUI
import Marlin

public struct OverviewBar: PlatformViewControllerRepresentable {
    public let sample: Sample
    @Binding public var selection: Selection
    
    public init(sample: Sample,
                selection: Binding<Selection>) {
        self.sample = sample
        self._selection = selection
    }
    
    #if os(macOS)
    public func makeNSView(context: Context) -> AppKitOverviewBar {
        return makeOverviewBar(context: context)
    }
    
    public func updateNSView(_ view: AppKitOverviewBar,
                             context: Context) {
        updateOverviewBar(view, context: context)
    }
    
    #elseif os(iOS)
    public func makeUIView(context: Context) -> UIKitOverviewBar {
        makeOverviewBar(context: context)
    }
    
    public func updateUIView(_ uiView: UIKitOverviewBar,
                             context: Context) {
        updateOverviewBar(uiView, context: context)
    }
    #endif
    
    /*
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
     */
}

private extension OverviewBar {
    func makeOverviewBar(context: Context) -> PlatformOverviewBar {
        let overviewBar = PlatformOverviewBar()
        overviewBar.sample = sample
        
        return overviewBar
    }
    
    func updateOverviewBar(_ view: PlatformOverviewBar,
                           context: Context) {
        view.setSelection(newSelection: selection)
    }
}
