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


/// Free function that returns the known color
/// - Parameter color: the known color
/// - Returns: the color as either a UIColor or NSColor
func knownColor(_ color: KnownColors) -> PlatformColor {
    guard color.rawValue < platformColors.count else {
        return .systemPurple
    }

    return platformColors[color.rawValue]
}

/// Free function that returns the known color as a CGColor.
/// For use with CALayer
/// - Parameter color: the known color
/// - Returns: the color as a CGColor
func knownCGColor(_ color: KnownColors) -> CGColor {
    guard color.rawValue < platformColors.count else {
        return PlatformColor.systemPurple.cgColor
    }

    return platformColors[color.rawValue].cgColor
}

// The different colors used on the two platforms. Keep in sync
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
