import XCTest
@testable import StrumMeng

final class HitAnimationTests: XCTestCase {
    private let perfect = PlayJudgement(feedback: .perfect, time: 10)
    private let tooEarly = PlayJudgement(feedback: .tooEarly, time: 10)
    private let miss = PlayJudgement(feedback: .miss, time: 10)

    // MARK: Node

    func test_beforeTheJudgement_theNodeIsAtRest() {
        XCTAssertEqual(HitAnimation.node(judgement: perfect, songTime: 9.9), .resting)
        XCTAssertEqual(HitAnimation.node(judgement: nil, songTime: 12), .resting)
    }

    func test_hit_staysInTheRing_growsAndFadesOverPointThreeSeconds() {
        let look = HitAnimation.node(judgement: perfect, songTime: 10.15)
        XCTAssertTrue(look.snapsToRing)
        XCTAssertEqual(look.scale, 1.18, accuracy: 1e-9)
        XCTAssertEqual(look.opacity, 0.5, accuracy: 1e-9)
        XCTAssertEqual(HitAnimation.node(judgement: perfect, songTime: 10.31).opacity, 0, accuracy: 1e-9)
    }

    func test_tooEarly_isAlsoCaughtInTheRing() {
        XCTAssertTrue(HitAnimation.node(judgement: tooEarly, songTime: 10.1).snapsToRing)
    }

    func test_miss_turnsGreyAndKeepsMoving() {
        let look = HitAnimation.node(judgement: miss, songTime: 11)
        XCTAssertTrue(look.greyedOut)
        XCTAssertFalse(look.snapsToRing)
        XCTAssertEqual(look.opacity, 0.45)
    }

    // MARK: Ring

    func test_ring_holdsTheResultColourForPointTwoSeconds() {
        XCTAssertEqual(HitAnimation.ringStrength(judgement: perfect, songTime: 10.19), 1)
        XCTAssertEqual(HitAnimation.ringStrength(judgement: perfect, songTime: 10.21), 0)
        XCTAssertEqual(HitAnimation.ringStrength(judgement: perfect, songTime: 9.9), 0)
        XCTAssertEqual(HitAnimation.ringStrength(judgement: nil, songTime: 10), 0)
    }

    func test_ring_thickensForAMomentAfterEverySwipe() {
        XCTAssertGreaterThan(HitAnimation.ringLineScale(lastStrumTime: 10, songTime: 10.05), 1)
        XCTAssertEqual(HitAnimation.ringLineScale(lastStrumTime: 10, songTime: 10.13), 1)
        XCTAssertEqual(HitAnimation.ringLineScale(lastStrumTime: 10, songTime: 9.9), 1)
        XCTAssertEqual(HitAnimation.ringLineScale(lastStrumTime: nil, songTime: 10), 1)
    }

    // MARK: Wave

    func test_wave_spreadsAfterAHit_andEnds() {
        let start = HitAnimation.wave(judgement: perfect, songTime: 10)
        let later = HitAnimation.wave(judgement: tooEarly, songTime: 10.2)
        XCTAssertEqual(start?.opacity ?? 0, 1, accuracy: 1e-9)
        XCTAssertGreaterThan(later?.scale ?? 0, start?.scale ?? 0)
        XCTAssertNil(HitAnimation.wave(judgement: perfect, songTime: 10.36))
    }

    func test_wave_neverPlaysOnAMiss() {
        XCTAssertNil(HitAnimation.wave(judgement: miss, songTime: 10.1))
    }
}
