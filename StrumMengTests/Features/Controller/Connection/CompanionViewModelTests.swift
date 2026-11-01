import XCTest
@testable import StrumMeng

@MainActor
final class CompanionViewModelTests: XCTestCase {
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<1_000 where !condition() { await Task.yield() }
    }

    private func makeViewModel(
        state: CompanionState = .connected,
        saved: PairCode? = nil,
        now: @escaping () -> TimeInterval = { 100 }
    ) -> (CompanionViewModel, MockControllerClient, MockPairCodeStore) {
        let client = MockControllerClient()
        let store = MockPairCodeStore(enteredPairCode: saved)
        return (CompanionViewModel(client: client, pairCodes: store, state: state, now: now), client, store)
    }

    // MARK: Swipes

    func test_swipeRight_sendsADownStrum() async {
        let (viewModel, client, _) = makeViewModel()

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)
        await waitUntil { !client.sentStrums.isEmpty }

        XCTAssertEqual(viewModel.lastStrum, .down)
        XCTAssertEqual(viewModel.strumCount, 1)
        XCTAssertEqual(client.sentStrums.map(\.direction), [.down])
    }

    func test_swipeLeft_sendsAnUpStrum() async {
        let (viewModel, client, _) = makeViewModel()

        viewModel.swipe(dx: -CompanionViewModel.swipeThreshold)
        await waitUntil { !client.sentStrums.isEmpty }

        XCTAssertEqual(viewModel.lastStrum, .up)
        XCTAssertEqual(client.sentStrums.map(\.direction), [.up])
    }

    func test_aStrum_keepsTheTimeOfItsTouchEvent() async throws {
        let (viewModel, client, _) = makeViewModel()

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold, eventDate: Date().addingTimeInterval(-0.05))
        await waitUntil { !client.sentStrums.isEmpty }

        let time = try XCTUnwrap(client.sentStrums.first?.touchTime)
        XCTAssertEqual(time, 99.95, accuracy: 0.02)
    }

    func test_anUnbelievableTouchDelay_isIgnored() async throws {
        let (viewModel, client, _) = makeViewModel()

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold, eventDate: Date().addingTimeInterval(-5))
        await waitUntil { !client.sentStrums.isEmpty }

        XCTAssertEqual(try XCTUnwrap(client.sentStrums.first?.touchTime), 100)
    }

    func test_swipeBelowTheThreshold_isNotAStrum() async {
        let (viewModel, client, _) = makeViewModel()

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold / 2)
        for _ in 0..<50 { await Task.yield() }

        XCTAssertNil(viewModel.lastStrum)
        XCTAssertTrue(client.sentStrums.isEmpty)
    }

    func test_swipeWhileNotConnected_isIgnored() async {
        for state in [CompanionState.enteringCode(""), .reconnecting] {
            let (viewModel, client, _) = makeViewModel(state: state)

            viewModel.swipe(dx: CompanionViewModel.swipeThreshold)
            for _ in 0..<50 { await Task.yield() }

            XCTAssertEqual(viewModel.strumCount, 0)
            XCTAssertTrue(client.sentStrums.isEmpty)
        }
    }

    // MARK: Pairing

    func test_sixDigits_connectWithThatCode() async throws {
        let (viewModel, client, _) = makeViewModel(state: .enteringCode("48291"))

        viewModel.send(.typeDigit(3))
        await waitUntil { !client.connectedCodes.isEmpty }

        XCTAssertEqual(viewModel.state, .connecting("482913"))
        XCTAssertEqual(client.connectedCodes, [try XCTUnwrap(PairCode("482913"))])
    }

    func test_theCode_isSavedOnlyOnceConnected() async throws {
        let (viewModel, client, store) = makeViewModel(state: .enteringCode("48291"))
        viewModel.appear()

        viewModel.send(.typeDigit(3))
        XCTAssertNil(store.enteredPairCode)

        client.emit(.connected(latencyMs: 5))
        await waitUntil { viewModel.state == .connected }

        XCTAssertEqual(store.enteredPairCode, try XCTUnwrap(PairCode("482913")))
        viewModel.stop()
    }

    func test_appear_reconnectsWithTheSavedCode() async throws {
        let saved = try XCTUnwrap(PairCode("482913"))
        let (viewModel, client, _) = makeViewModel(state: .enteringCode(""), saved: saved)

        viewModel.appear()
        await waitUntil { !client.connectedCodes.isEmpty }

        XCTAssertEqual(viewModel.state, .connecting("482913"))
        XCTAssertEqual(client.connectedCodes, [saved])
        viewModel.stop()
    }

    func test_appear_withNoSavedCode_waitsForTyping() async {
        let (viewModel, client, _) = makeViewModel(state: .enteringCode(""))

        viewModel.appear()
        for _ in 0..<50 { await Task.yield() }

        XCTAssertEqual(viewModel.state, .enteringCode(""))
        XCTAssertTrue(client.connectedCodes.isEmpty)
        viewModel.stop()
    }

    func test_aLostLink_reconnects_andComesBack() async {
        let (viewModel, client, _) = makeViewModel()
        viewModel.appear()

        client.emit(.reconnecting)
        await waitUntil { viewModel.state == .reconnecting }
        XCTAssertEqual(viewModel.state, .reconnecting)

        client.emit(.connected(latencyMs: 5))
        await waitUntil { viewModel.state == .connected }
        XCTAssertEqual(viewModel.state, .connected)
        viewModel.stop()
    }

    // MARK: Leaving

    func test_unpair_disconnects_andForgetsTheCode() async throws {
        let (viewModel, client, store) = makeViewModel(saved: try XCTUnwrap(PairCode("482913")))
        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)

        viewModel.send(.disconnect)
        await waitUntil { client.disconnectCount == 1 }

        XCTAssertEqual(client.disconnectCount, 1)
        XCTAssertNil(store.enteredPairCode)
        XCTAssertNil(viewModel.lastStrum)
        XCTAssertEqual(viewModel.state, .enteringCode(""))
    }

    func test_stop_disconnects_butKeepsTheCode() async throws {
        let saved = try XCTUnwrap(PairCode("482913"))
        let (viewModel, client, store) = makeViewModel(saved: saved)

        viewModel.stop()
        await waitUntil { client.disconnectCount == 1 }

        XCTAssertEqual(client.disconnectCount, 1)
        XCTAssertEqual(store.enteredPairCode, saved)
    }
}
