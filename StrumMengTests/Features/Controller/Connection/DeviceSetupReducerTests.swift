import XCTest
@testable import StrumMeng

final class DeviceSetupReducerTests: XCTestCase {
    func test_simulateNextState_cyclesThroughEveryState() {
        XCTAssertEqual(reduce(.searching, .simulateNextState), .connected)
        XCTAssertEqual(reduce(.connected, .simulateNextState), .reconnecting)
        XCTAssertEqual(reduce(.reconnecting, .simulateNextState), .searching)
    }

    func test_doneAndBack_leaveTheStateAlone() {
        XCTAssertEqual(reduce(.connected, .tapDone), .connected)
        XCTAssertEqual(reduce(.searching, .tapBack), .searching)
    }
}
