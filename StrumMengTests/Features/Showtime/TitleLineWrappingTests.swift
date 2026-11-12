import XCTest
@testable import StrumMeng

final class TitleLineWrappingTests: XCTestCase {
    func test_longTitleBreaksAtWordsAndShortTitleKeepsOneLine() {
        XCTAssertEqual(TitleLineWrapping.lines(for: "Twinkle Twinkle Little Star"), ["Twinkle Twinkle", "Little Star"])
        XCTAssertEqual(TitleLineWrapping.lines(for: "Jingle Bells"), ["Jingle Bells"])
    }
    func test_explicitLineBreakAndEmptyTitleAreSafe() {
        XCTAssertEqual(TitleLineWrapping.lines(for: "Twinkle\nLittle Star"), ["Twinkle", "Little Star"])
        XCTAssertEqual(TitleLineWrapping.lines(for: ""), [""])
    }
}
