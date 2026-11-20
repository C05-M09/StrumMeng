import Foundation

/// The 6-digit code that pairs an iPhone with an iPad over regular Wi-Fi. Both sides derive the
/// same encryption key from it, so only an iPhone that knows the code can connect.
nonisolated struct PairCode: Codable, Sendable, Equatable, CustomStringConvertible {
    static let length = 6

    let value: String

    /// nil unless the text is exactly six ASCII digits.
    init?(_ text: String) {
        guard text.count == Self.length, text.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        value = text
    }

    private init(number: Int) {
        value = String(format: "%06d", number)
    }

    static func random() -> PairCode {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    static func random<G: RandomNumberGenerator>(using generator: inout G) -> PairCode {
        PairCode(number: Int.random(in: 0...999_999, using: &generator))
    }

    var description: String { value }
}
