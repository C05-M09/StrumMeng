import XCTest
@testable import StrumMeng

@MainActor
final class DeviceSetupViewModelTests: XCTestCase {
    func test_back_closesTheScreenInAnyState() {
        var closes = 0
        let viewModel = DeviceSetupViewModel(state: .searching, onClose: { closes += 1 })

        viewModel.send(.tapBack)

        XCTAssertEqual(closes, 1)
    }

    func test_done_doesNothingUntilConnected() {
        var closes = 0
        let viewModel = DeviceSetupViewModel(state: .searching, onClose: { closes += 1 })

        viewModel.send(.tapDone)
        XCTAssertEqual(closes, 0)

        viewModel.send(.simulateNextState)
        viewModel.send(.tapDone)
        XCTAssertEqual(closes, 1)
    }

    func test_canFinish_isTrueOnlyWhenConnected() {
        XCTAssertFalse(DeviceSetupViewModel(state: .searching, onClose: {}).canFinish)
        XCTAssertTrue(DeviceSetupViewModel(state: .connected, onClose: {}).canFinish)
        XCTAssertFalse(DeviceSetupViewModel(state: .reconnecting, onClose: {}).canFinish)
    }
}
