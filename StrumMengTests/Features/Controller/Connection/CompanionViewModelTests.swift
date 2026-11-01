import XCTest
@testable import StrumMeng

@MainActor
final class CompanionViewModelTests: XCTestCase {
    func test_swipeRight_isADownStrum() {
        let viewModel = CompanionViewModel(state: .connected)

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)

        XCTAssertEqual(viewModel.lastStrum, .down)
        XCTAssertEqual(viewModel.strumCount, 1)
    }

    func test_swipeLeft_isAnUpStrum() {
        let viewModel = CompanionViewModel(state: .connected)

        viewModel.swipe(dx: -CompanionViewModel.swipeThreshold)

        XCTAssertEqual(viewModel.lastStrum, .up)
    }

    func test_swipeBelowTheThreshold_isNotAStrum() {
        let viewModel = CompanionViewModel(state: .connected)

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold / 2)

        XCTAssertNil(viewModel.lastStrum)
        XCTAssertEqual(viewModel.strumCount, 0)
    }

    func test_swipeBeforeConnecting_isIgnored() {
        let viewModel = CompanionViewModel(state: .enteringCode(""))

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)

        XCTAssertEqual(viewModel.strumCount, 0)
    }

    func test_sixDigits_connectAfterTheDelay() async {
        let viewModel = CompanionViewModel(state: .enteringCode("48291"), connectDelay: .zero)

        viewModel.send(.typeDigit(3))
        XCTAssertEqual(viewModel.state, .connecting("482913"))

        while viewModel.state != .connected { await Task.yield() }
        XCTAssertEqual(viewModel.state, .connected)
    }

    func test_stop_cancelsAConnectionInProgress() async throws {
        let viewModel = CompanionViewModel(state: .enteringCode("48291"), connectDelay: .milliseconds(10))

        viewModel.send(.typeDigit(3))
        viewModel.stop()
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.state, .connecting("482913"))
    }

    func test_disconnect_clearsTheLastStrum() {
        let viewModel = CompanionViewModel(state: .connected)
        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)

        viewModel.send(.disconnect)

        XCTAssertNil(viewModel.lastStrum)
        XCTAssertEqual(viewModel.state, .enteringCode(""))
    }
}
