import XCTest
@testable import StrumMeng

final class DeviceSetupReducerTests: XCTestCase {
    func test_linkLookingForTheiPhone_isSearching() {
        XCTAssertEqual(reduce(.connected(latencyMs: 5), .linkStateChanged(.unpaired)), .searching)
        XCTAssertEqual(reduce(.reconnecting, .linkStateChanged(.pairing)), .searching)
        XCTAssertEqual(reduce(.reconnecting, .linkStateChanged(.searching)), .searching)
    }

    func test_linkConnected_showsItsLatency() {
        XCTAssertEqual(reduce(.searching, .linkStateChanged(.connected(latencyMs: 12))),
                       .connected(latencyMs: 12))
    }

    func test_linkReconnecting_isReconnecting() {
        XCTAssertEqual(reduce(.connected(latencyMs: 5), .linkStateChanged(.reconnecting)), .reconnecting)
    }

    func test_linkFailed_isFailed() {
        XCTAssertEqual(reduce(.searching, .linkFailed), .failed)
    }

    func test_theFirstUnpaired_doesNotHideAFailedStart() {
        XCTAssertEqual(reduce(.failed, .linkStateChanged(.unpaired)), .failed)
    }

    func test_aLinkThatComesBack_clearsAFailedStart() {
        XCTAssertEqual(reduce(.failed, .linkStateChanged(.searching)), .searching)
    }

    func test_refresh_whileReconnectingOrFailed_goesBackToSearching() {
        XCTAssertEqual(reduce(.reconnecting, .tapRefresh), .searching)
        XCTAssertEqual(reduce(.failed, .tapRefresh), .searching)
    }

    func test_refresh_whileSearchingOrConnected_isIgnored() {
        XCTAssertEqual(reduce(.searching, .tapRefresh), .searching)
        XCTAssertEqual(reduce(.connected(latencyMs: 5), .tapRefresh), .connected(latencyMs: 5))
    }

    func test_doneAndBack_leaveTheStateAlone() {
        XCTAssertEqual(reduce(.connected(latencyMs: 5), .tapDone), .connected(latencyMs: 5))
        XCTAssertEqual(reduce(.searching, .tapBack), .searching)
    }
}
