import Foundation

enum SelectionType {
    case none, left, right, both, single
}

public struct Selection : Equatable, Sendable {
    public let selectedRange: CountableClosedRange<UInt64>
    let type: SelectionType
    let channel: UInt = 0
    
    public static let zero = Selection(type: .none)
    
    public init(_ range: CountableClosedRange<UInt64>) {
        selectedRange = range
        type = .both
    }
    
    public init(startFrame: UInt64, endFrame: UInt64) {
        selectedRange = startFrame...endFrame
        type = .both
    }
    
    init(type: SelectionType) {
        selectedRange = 0...0
        self.type = type
    }
    
    public var isEmpty: Bool {
        return type == .none
    }
        
    public static func ==(lhs: Selection, rhs: Selection) -> Bool{
        return lhs.type == rhs.type && lhs.channel == rhs.channel && lhs.selectedRange == rhs.selectedRange
    }
}

extension Selection {
    public func frameIsInsideSelection(_ frame: UInt64) -> Bool {
        return selectedRange.contains(frame)
    }

    public func moveSelection(endingOn endFrame: UInt64) -> Self {
        .init(startFrame: endFrame - UInt64(selectedRange.count) + 1, endFrame: endFrame)
    }
    
    public func moveSelection(startingOn startFrame: UInt64) -> Self {
        .init(startFrame: startFrame, endFrame: startFrame + UInt64(selectedRange.count) - 1)
    }
}
