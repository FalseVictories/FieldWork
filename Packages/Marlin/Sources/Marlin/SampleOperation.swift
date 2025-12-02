import Foundation
import SwiftUI

@MainActor
@Observable
final public class SampleOperation: Sendable {
    public var title: String?
    public var description: String?
    public var progress: Float = 0.0
    
    init(title: String? = nil, description: String? = nil) {
        self.title = title
        self.description = description
    }
}
