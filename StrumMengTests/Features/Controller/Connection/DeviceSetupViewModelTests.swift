import XCTest
@testable import StrumMeng

@MainActor
final class DeviceSetupViewModelTests: XCTestCase {
    private struct StartFailure: Error {}

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<1_000 where !condition() { await Task.yield() }
    }

    func test_pairCode_comesFromTheLink() throws {
        let link = MockControllerLink(pairCode: try XCTUnwrap(PairCode("482913")))

        XCTAssertEqual(DeviceSetupViewModel(link: link, onClose: {}).pairCode, "482913")
    }

    func test_appear_startsTheLink_andFollowsItsState() async {
        let link = MockControllerLink()
        let viewModel = DeviceSetupViewModel(link: link, onClose: {})

        viewModel.appear()
        link.emit(.connected(latencyMs: 12))
        await waitUntil { viewModel.state == .connected(latencyMs: 12) && link.startCount == 1 }

        XCTAssertEqual(viewModel.state, .connected(latencyMs: 12))
        XCTAssertEqual(link.startCount, 1)
        viewModel.disappear()
    }

    func test_aLinkThatCannotStart_isShownAsFailed() async {
        let link = MockControllerLink()
        link.startError = StartFailure()
        let viewModel = DeviceSetupViewModel(link: link, onClose: {})

        viewModel.appear()
        await waitUntil { viewModel.state == .failed }

        XCTAssertEqual(viewModel.state, .failed)
        viewModel.disappear()
    }

    func test_disappear_leavesTheLinkRunning_andStopsFollowingIt() async {
        let link = MockControllerLink()
        let viewModel = DeviceSetupViewModel(link: link, onClose: {})
        viewModel.appear()
        await waitUntil { link.startCount == 1 }

        viewModel.disappear()
        link.emit(.connected(latencyMs: 12))
        for _ in 0..<50 { await Task.yield() }

        XCTAssertEqual(link.stopCount, 0)
        XCTAssertEqual(viewModel.state, .searching)
    }

    func test_back_closesTheScreenInAnyState() {
        var closes = 0
        let viewModel = DeviceSetupViewModel(link: MockControllerLink(), state: .searching,
                                             onClose: { closes += 1 })

        viewModel.send(.tapBack)

        XCTAssertEqual(closes, 1)
    }

    func test_done_doesNothingUntilConnected() {
        var closes = 0
        let viewModel = DeviceSetupViewModel(link: MockControllerLink(), state: .searching,
                                             onClose: { closes += 1 })

        viewModel.send(.tapDone)
        XCTAssertEqual(closes, 0)

        viewModel.send(.linkStateChanged(.connected(latencyMs: 12)))
        viewModel.send(.tapDone)
        XCTAssertEqual(closes, 1)
    }

    func test_canFinish_isTrueOnlyWhenConnected() {
        let link = MockControllerLink()
        XCTAssertFalse(DeviceSetupViewModel(link: link, state: .searching, onClose: {}).canFinish)
        XCTAssertTrue(DeviceSetupViewModel(link: link, state: .connected(latencyMs: 5), onClose: {}).canFinish)
        XCTAssertFalse(DeviceSetupViewModel(link: link, state: .reconnecting, onClose: {}).canFinish)
        XCTAssertFalse(DeviceSetupViewModel(link: link, state: .failed, onClose: {}).canFinish)
    }
}
