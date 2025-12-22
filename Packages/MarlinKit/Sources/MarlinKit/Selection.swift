import Foundation

enum SelectionType {
    case none, left, right, both, single
}

struct Selection : Equatable, Sendable {
    var selectedRange: CountableClosedRange<UInt64> = 0...0
    var type: SelectionType = .both
    var channel: UInt = 0
    
    static let zero = Selection(type: .none)
    
    init(_ range: CountableClosedRange<UInt64>) {
        selectedRange = range
    }
    
    init(startFrame: UInt64, endFrame: UInt64) {
        selectedRange = startFrame...endFrame
    }
    
    init(type: SelectionType) {
        self.type = type
    }
    
    var isEmpty: Bool {
        return type == .none || selectedRange.isEmpty
    }
    
    func frameIsInsideSelection(_ frame: UInt64) -> Bool {
        return selectedRange.contains(frame)
    }
    
    public static func ==(lhs: Selection, rhs: Selection) -> Bool{
        return lhs.type == rhs.type && lhs.channel == rhs.channel && lhs.selectedRange == rhs.selectedRange
    }
}
