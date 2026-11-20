import XCTest
@testable import StrumMeng

final class MenuMusicPolicyTests: XCTestCase {
    private let sessionID = UUID()

    func test_home_playsMusic() {
        XCTAssertTrue(MenuMusicPolicy.playsMusic(on: nil, isAppActive: true))
    }

    func test_patternList_playsMusic() {
        XCTAssertTrue(MenuMusicPolicy.playsMusic(on: .practiceList, isAppActive: true))
    }

    func test_showtimeList_pausesMenuMusic() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .showtimeList, isAppActive: true))
    }

    func test_deviceSetup_playsMusic() {
        XCTAssertTrue(MenuMusicPolicy.playsMusic(on: .deviceSetup, isAppActive: true))
    }

    func test_listen_pausesMusic() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .listen(patternID: "p", bpm: 80), isAppActive: true))
    }

    func test_play_pausesMusic() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .play(patternID: "p", bpm: 80), isAppActive: true))
    }

    func test_summary_pausesMusic_untilTheSummaryShows() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .summary(sessionID: sessionID), isAppActive: true))
    }

    func test_summary_playsMusic_whileTheSummaryShows() {
        XCTAssertTrue(MenuMusicPolicy.playsMusic(
            on: .summary(sessionID: sessionID), isAppActive: true, isShowingSummary: true
        ))
    }

    func test_showtimeSummary_playsMusic_whileTheSummaryShows() {
        XCTAssertTrue(MenuMusicPolicy.playsMusic(
            on: .showtime(songID: "dummy-twinkle"), isAppActive: true, isShowingSummary: true
        ))
    }

    func test_summary_inactiveApp_pausesMusic() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(
            on: .summary(sessionID: sessionID), isAppActive: false, isShowingSummary: true
        ))
    }

    func test_listenAndPlay_pauseMusic_evenIfASummaryReportedShowing() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(
            on: .listen(patternID: "p", bpm: 80), isAppActive: true, isShowingSummary: true
        ))
        XCTAssertFalse(MenuMusicPolicy.playsMusic(
            on: .play(patternID: "p", bpm: 80), isAppActive: true, isShowingSummary: true
        ))
        XCTAssertFalse(MenuMusicPolicy.playsMusic(
            on: .showtimeList, isAppActive: true, isShowingSummary: true
        ))
    }

    func test_inactiveApp_pausesMusic_evenOnHome() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: nil, isAppActive: false))
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .practiceList, isAppActive: false))
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .deviceSetup, isAppActive: false))
    }

    func test_showtimeSession_pausesMusic() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .showtime(songID: "dummy-twinkle"), isAppActive: true))
    }
}
