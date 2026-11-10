import XCTest
@testable import StrumMeng

final class ToleranceConfigTests: XCTestCase {
    func test_windowsAtNormalTempo_areNotScaled() {
        let config = ToleranceConfig.standard
        let windows = config.windows(stepInterval: 0.375)
        XCTAssertEqual(windows.perfect, config.perfectWindowMs / 1000, accuracy: 1e-9)
        XCTAssertEqual(windows.early, config.earlyWindowMs / 1000, accuracy: 1e-9)
    }

    func test_windowsAtMaxBPM_stillFitInsideOneStep() {
        let step = AudioBeatClock.stepInterval(bpm: PracticeTempoConfig.maximumBPM)
        let windows = ToleranceConfig.standard.windows(stepInterval: step)
        XCTAssertLessThanOrEqual(windows.perfect + windows.early, step * 0.9 + 1e-9)
    }

    func test_windowsWhenTooWide_areScaledDownTogether() {
        let config = ToleranceConfig.standard
        let windows = config.windows(stepInterval: 0.1)
        XCTAssertEqual(windows.perfect + windows.early, 0.09, accuracy: 1e-9)
        XCTAssertEqual(windows.early / windows.perfect, config.earlyWindowMs / config.perfectWindowMs,
                       accuracy: 1e-9)
    }
}
