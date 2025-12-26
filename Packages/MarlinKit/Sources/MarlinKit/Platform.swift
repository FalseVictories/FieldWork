#if os(macOS)
import AppKit

typealias PlatformColor = NSColor
public typealias PlatformViewController = NSViewController
typealias PlatformSampleView = AppKitSampleView
#elseif os(iOS)
import UIKit

typealias PlatformColor = UIColor
public typealias PlatformViewController = UIViewController
typealias PlatformSampleView = UIKitSampleView
#endif

enum KnownColors: Int {
    case selectionBackground = 0
    case selectionOutline = 1
    case waveformBackground = 2
    case waveform = 3
}

#if os(macOS)
private let platformColors: [PlatformColor] = [
    .tertiarySystemFill,
    .selectedTextBackgroundColor,
    .clear,
    .systemRed
]
#elseif os(iOS)
private let platformColors: [PlatformColor] = [
    .tertiarySystemFill,
    .tintColor,
    .clear,
    .systemRed
]
#endif

func knownColor(_ color: KnownColors) -> PlatformColor {
    platformColors[color.rawValue]
}

func knownCGColor(_ color: KnownColors) -> CGColor {
    platformColors[color.rawValue].cgColor
}
