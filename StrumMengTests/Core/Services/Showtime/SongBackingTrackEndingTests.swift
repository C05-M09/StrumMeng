import XCTest
@testable import StrumMeng

final class SongBackingTrackEndingTests: XCTestCase {
    private let step: TimeInterval = 0.3          // 100 BPM

    /// Two bars of the Driving Pop pattern, D - D U D - D -: the last node is "4" of bar 2.
    private let driving: [Stroke] = Array(repeating: [.down, .rest, .down, .up, .down, .rest, .down, .rest],
                                          count: 2).flatMap { $0 }

    func test_fadesOverTheBarOfTheLastNode_andEndsOnIt() throws {
        let ending = try XCTUnwrap(SongBackingTrackEnding.forChart(strokes: driving, stepInterval: step))
        XCTAssertEqual(ending.fadeStart, 8 * step, accuracy: 1e-9)    // "1" of the last bar
        XCTAssertEqual(ending.end, 14 * step, accuracy: 1e-9)         // its "4", the last node
    }

    func test_lastNodeOnTheBarsFirstStep_fadesOverTheBarBefore() throws {
        let strokes: [Stroke] = Array(repeating: .down, count: 9) + Array(repeating: .rest, count: 7)
        let ending = try XCTUnwrap(SongBackingTrackEnding.forChart(strokes: strokes, stepInterval: step))
        XCTAssertEqual(ending.fadeStart, 0, accuracy: 1e-9)
        XCTAssertEqual(ending.end, 8 * step, accuracy: 1e-9)
    }

    func test_chartWithoutNodes_hasNoEnding() {
        XCTAssertNil(SongBackingTrackEnding.forChart(strokes: Array(repeating: .rest, count: 8), stepInterval: step))
        XCTAssertNil(SongBackingTrackEnding.forChart(strokes: [], stepInterval: step))
    }

    func test_gain_isFullBeforeTheFade_easesDown_andIsSilentFromTheLastNode() {
        let ending = SongBackingTrackEnding(fadeStart: 10, end: 12)
        XCTAssertEqual(ending.gain(atSongTime: 5), 1)
        XCTAssertEqual(ending.gain(atSongTime: 10), 1)
        XCTAssertEqual(ending.gain(atSongTime: 11), 0.25, accuracy: 1e-9)   // halfway, eased
        XCTAssertEqual(ending.gain(atSongTime: 12), 0)
        XCTAssertEqual(ending.gain(atSongTime: 20), 0)
    }

    func test_gain_keepsFallingThroughTheFade() {
        let ending = SongBackingTrackEnding(fadeStart: 10, end: 12)
        let levels = stride(from: 10.0, through: 12.0, by: 0.25).map { ending.gain(atSongTime: $0) }
        XCTAssertEqual(levels, levels.sorted(by: >))
    }
}
