import XCTest
@testable import StrumMeng

final class OptionReducerTests: XCTestCase {
    private let start = OptionState(soundVolume: 0.5, sfxVolume: 0.5)

    func test_changeSoundVolume_updatesOnlySound() {
        let result = reduce(start, .changeSoundVolume(0.8))
        XCTAssertEqual(result, OptionState(soundVolume: 0.8, sfxVolume: 0.5))
    }

    func test_changeSFXVolume_updatesOnlySFX() {
        let result = reduce(start, .changeSFXVolume(0.1))
        XCTAssertEqual(result, OptionState(soundVolume: 0.5, sfxVolume: 0.1))
    }

    func test_changeVolume_clampsToTheRange() {
        XCTAssertEqual(reduce(start, .changeSoundVolume(2)).soundVolume, 1)
        XCTAssertEqual(reduce(start, .changeSFXVolume(-2)).sfxVolume, 0)
    }

    func test_tapBack_leavesTheStateUnchanged() {
        XCTAssertEqual(reduce(start, .tapBack), start)
    }
}
