import XCTest
@testable import StrumMeng

final class ReplayCueTests: XCTestCase {
    private let step = 0.375                                        // eighth note at 80 BPM

    private func result(_ events: [BeatEvent]) -> SessionResult {
        SessionResultBuilder.build(id: UUID(), patternID: "subdivision", bpm: 80,
                                   beatEvents: events, createdAt: Date(timeIntervalSince1970: 0))
    }

    private func cues(_ events: [BeatEvent], totalSteps: Int = 16) -> [ReplayCue] {
        ReplayCue.cues(for: result(events), pattern: PatternCatalog.all[1], stepInterval: step, totalSteps: totalSteps)
    }

    func test_metronome_clicksEveryQuarterNote_accentingEachBar() {
        let clicks = cues([]).filter { if case .click = $0.sound { true } else { false } }

        XCTAssertEqual(clicks.map(\.time), [0, 2, 4, 6, 8, 10, 12, 14].map { Double($0) * step })
        XCTAssertEqual(clicks.map(\.sound), [true, false, false, false, true, false, false, false]
            .map { ReplayCue.Sound.click(accent: $0) })
    }

    func test_playerStrums_replayAtTheirRecordedTime_inTheNotesDirection() {
        let strums = cues([
            BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 20),
            BeatEvent(stepIndex: 1, result: .tooEarly, offsetMs: -90),
        ]).filter { if case .strum = $0.sound { true } else { false } }

        XCTAssertEqual(strums, [
            ReplayCue(time: 0.020, sound: .strum(.down)),
            ReplayCue(time: step - 0.090, sound: .strum(.up)),
        ])
    }

    func test_miss_playsWrongStrumDirection() {
        // Step 0 pattern note is .down, so a miss plays the wrong direction: .up
        let strumsWithoutOffset = cues([BeatEvent(stepIndex: 0, result: .miss, offsetMs: nil)])
            .filter { if case .strum = $0.sound { true } else { false } }

        XCTAssertEqual(strumsWithoutOffset, [
            ReplayCue(time: 0, sound: .strum(.up))
        ])

        // Step 1 pattern note is .up, so a miss plays .down
        let strumsWithOffset = cues([BeatEvent(stepIndex: 1, result: .miss, offsetMs: -30)])
            .filter { if case .strum = $0.sound { true } else { false } }

        XCTAssertEqual(strumsWithOffset, [
            ReplayCue(time: step - 0.030, sound: .strum(.down))
        ])
    }

    func test_cuesAreSortedByTime() {
        let times = cues([BeatEvent(stepIndex: 3, result: .tooEarly, offsetMs: -100),
                          BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 0)]).map(\.time)

        XCTAssertEqual(times, times.sorted())
    }
}
