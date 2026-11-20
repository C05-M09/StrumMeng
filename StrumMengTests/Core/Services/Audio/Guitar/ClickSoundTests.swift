import XCTest
@testable import StrumMeng

final class ClickSoundTests: XCTestCase {
    func test_click_isShort_andDiesAway() {
        let samples = ClickSound.samples(frequency: ClickSound.accentFrequency, sampleRate: 48_000)
        XCTAssertEqual(samples.count, Int(48_000 * ClickSound.duration))
        let start = samples.prefix(200).map { abs($0) }.max() ?? 0
        let end = samples.suffix(200).map { abs($0) }.max() ?? 0
        XCTAssertGreaterThan(start, 0.1)
        XCTAssertLessThan(end, start * 0.05)
    }

    func test_accentClick_isHigherThanTheBeatClick() {
        XCTAssertGreaterThan(ClickSound.accentFrequency, ClickSound.beatFrequency)
    }
}
