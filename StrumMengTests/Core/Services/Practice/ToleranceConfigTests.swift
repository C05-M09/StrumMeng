import XCTest
@testable import StrumMeng

final class ToleranceConfigTests: XCTestCase {
    func test_windowsAtNormalTempo_areNotScaled() {
        let windows = ToleranceConfig.standard.windows(stepInterval: 0.375)
        XCTAssertEqual(windows.perfect, 0.05, accuracy: 1e-9)
        XCTAssertEqual(windows.early, 0.15, accuracy: 1e-9)
    }

    func test_windowsAtMaxBPM_stillFitInsideOneStep() {
        let step = AudioBeatClock.stepInterval(bpm: PracticeTempoConfig.maximumBPM)
        let windows = ToleranceConfig.standard.windows(stepInterval: step)
        XCTAssertLessThanOrEqual(windows.perfect + windows.early, step * 0.9 + 1e-9)
    }

    func test_windowsWhenTooWide_areScaledDownTogether() {
        let windows = ToleranceConfig.standard.windows(stepInterval: 0.1)
        XCTAssertEqual(windows.perfect + windows.early, 0.09, accuracy: 1e-9)
        XCTAssertEqual(windows.early / windows.perfect, 3, accuracy: 1e-9)
    }
}
