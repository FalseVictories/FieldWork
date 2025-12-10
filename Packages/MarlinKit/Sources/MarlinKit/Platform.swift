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
