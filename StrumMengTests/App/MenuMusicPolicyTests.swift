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

    func test_deviceSetup_playsMusic() {
        XCTAssertTrue(MenuMusicPolicy.playsMusic(on: .deviceSetup, isAppActive: true))
    }

    func test_listen_pausesMusic() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .listen(patternID: "p", bpm: 80), isAppActive: true))
    }

    func test_play_pausesMusic() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .play(patternID: "p", bpm: 80), isAppActive: true))
    }

    func test_summary_pausesMusic() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .summary(sessionID: sessionID), isAppActive: true))
    }

    func test_inactiveApp_pausesMusic_evenOnHome() {
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: nil, isAppActive: false))
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .practiceList, isAppActive: false))
    }
    func test_showtimeListPlaysMusicButSessionPausesIt() {
        XCTAssertTrue(MenuMusicPolicy.playsMusic(on: .showtimeList, isAppActive: true))
        XCTAssertFalse(MenuMusicPolicy.playsMusic(on: .showtime(songID: "dummy-twinkle"), isAppActive: true))
    }

}
