import Foundation
import SwiftUI

@MainActor
@Observable
public class SampleOperation {
    var title: String?
    var description: String?
    var progress: Float = 0.0
    
    init(title: String? = nil, description: String? = nil) {
        self.title = title
        self.description = description
    }
}
