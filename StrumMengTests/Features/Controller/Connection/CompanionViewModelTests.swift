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

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold, touchAge: 0.05)
        await waitUntil { !client.sentStrums.isEmpty }

        XCTAssertEqual(try XCTUnwrap(client.sentStrums.first?.touchTime), 99.95, accuracy: 0.0001)
    }

    func test_anUnbelievableTouchAge_isIgnored() async throws {
        for age: TimeInterval in [5, -1] {
            let (viewModel, client, _) = makeViewModel()

            viewModel.swipe(dx: CompanionViewModel.swipeThreshold, touchAge: age)
            await waitUntil { !client.sentStrums.isEmpty }

            XCTAssertEqual(try XCTUnwrap(client.sentStrums.first?.touchTime), 100)
        }
    }

    func test_coalescedMovement_strumsAtTheEventThatCrossedTheThreshold() async throws {
        let (viewModel, client, _) = makeViewModel()

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold / 2, touchAge: 0.016)
        viewModel.swipe(dx: CompanionViewModel.swipeThreshold / 2, touchAge: 0.008)
        await waitUntil { !client.sentStrums.isEmpty }

        XCTAssertEqual(client.sentStrums.count, 1)
        XCTAssertEqual(try XCTUnwrap(client.sentStrums.first?.touchTime), 99.992, accuracy: 0.0001)
    }

    func test_swipeBelowTheThreshold_isNotAStrum() async {
        let (viewModel, client, _) = makeViewModel()

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold / 2)
        for _ in 0..<50 { await Task.yield() }

        XCTAssertNil(viewModel.lastStrum)
        XCTAssertTrue(client.sentStrums.isEmpty)
    }

    func test_swipeBeforeConnecting_isIgnored() async {
        let guitar = MockGuitarSound()
        let client = MockControllerClient()
        let viewModel = CompanionViewModel(client: client, pairCodes: MockPairCodeStore(),
                                           state: .enteringCode(""), makeGuitar: { guitar })
        viewModel.appear()

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)
        for _ in 0..<50 { await Task.yield() }

        XCTAssertEqual(viewModel.strumCount, 0)
        XCTAssertTrue(client.sentStrums.isEmpty)
        XCTAssertTrue(guitar.strums.isEmpty)
        viewModel.stop()
    }

    // MARK: Sound

    private func makeSoundingViewModel(
        state: CompanionState = .connected
    ) -> (CompanionViewModel, MockControllerClient, MockGuitarSound) {
        let guitar = MockGuitarSound()
        let client = MockControllerClient()
        let viewModel = CompanionViewModel(client: client, pairCodes: MockPairCodeStore(), state: state,
                                           now: { 100 }, makeGuitar: { guitar })
        viewModel.appear()
        return (viewModel, client, guitar)
    }

    func test_outsideASession_aSwipeSoundsOnTheiPhone_inItsDirection() {
        let (viewModel, _, guitar) = makeSoundingViewModel()

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)
        viewModel.swipe(dx: -CompanionViewModel.swipeThreshold)

        XCTAssertEqual(guitar.strums.map(\.direction), [.down, .up])
        viewModel.stop()
    }

    func test_duringASession_theiPhoneIsSilent_andCutsWhatIsRinging() async {
        let (viewModel, client, guitar) = makeSoundingViewModel()

        client.emitSessionActive(true)
        await waitUntil { guitar.stopStrumsCount == 1 }
        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)
        await waitUntil { !client.sentStrums.isEmpty }

        XCTAssertEqual(guitar.stopStrumsCount, 1)
        XCTAssertTrue(guitar.strums.isEmpty)
        XCTAssertEqual(client.sentStrums.map(\.direction), [.down])
        viewModel.stop()
    }

    func test_afterASession_theiPhoneSoundsAgain() async {
        let (viewModel, client, guitar) = makeSoundingViewModel()
        client.emitSessionActive(true)
        await waitUntil { guitar.stopStrumsCount == 1 }

        client.emitSessionActive(false)
        for _ in 0..<50 { await Task.yield() }
        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)

        XCTAssertEqual(guitar.strums.map(\.direction), [.down])
        viewModel.stop()
    }

    func test_whileReconnecting_aSwipeSounds_butIsNotSent() async {
        let (viewModel, client, guitar) = makeSoundingViewModel(state: .reconnecting)

        viewModel.swipe(dx: CompanionViewModel.swipeThreshold)
        for _ in 0..<50 { await Task.yield() }

        XCTAssertEqual(guitar.strums.count, 1)
        XCTAssertTrue(client.sentStrums.isEmpty)
        viewModel.stop()
    }

    func test_theGuitar_isMadeOnceOnAppear_andPrepared() async {
        var made = 0
        let guitar = MockGuitarSound()
        let viewModel = CompanionViewModel(client: MockControllerClient(), pairCodes: MockPairCodeStore(),
                                           makeGuitar: { made += 1; return guitar })
        XCTAssertEqual(made, 0)

        viewModel.appear()
        viewModel.appear()
        await waitUntil { guitar.prepareCount == 1 }

        XCTAssertEqual(made, 1)
        XCTAssertEqual(guitar.prepareCount, 1)
        viewModel.stop()
    }

    // MARK: Pairing

    func test_sixDigits_connectWithThatCode() async throws {
        let (viewModel, client, _) = makeViewModel(state: .enteringCode("48291"))

        viewModel.send(.typeDigit(3))
        viewModel.send(.confirmCode)
        await waitUntil { !client.connectedCodes.isEmpty }

        XCTAssertEqual(viewModel.state, .connecting("482913"))
        XCTAssertEqual(client.connectedCodes, [try XCTUnwrap(PairCode("482913"))])
    }

    func test_sixDigits_waitForTheCheckKey() async {
        let (viewModel, client, _) = makeViewModel(state: .enteringCode("48291"))

        viewModel.send(.typeDigit(3))
        for _ in 0..<50 { await Task.yield() }

        XCTAssertEqual(viewModel.state, .enteringCode("482913"))
        XCTAssertTrue(client.connectedCodes.isEmpty)
    }

    func test_retryAfterNotFound_looksAgain_withATimeout() async throws {
        let (viewModel, client, _) = makeTimingOutViewModel()
        viewModel.send(.typeDigit(3))
        viewModel.send(.confirmCode)
        await waitUntil { viewModel.state == .notFound("482913") }

        viewModel.send(.confirmCode)
        await waitUntil { client.connectedCodes.count == 2 && viewModel.state == .notFound("482913") }

        XCTAssertEqual(client.connectedCodes.count, 2)
        XCTAssertEqual(viewModel.state, .notFound("482913"))
    }

    func test_theCode_isSavedOnlyOnceConnected() async throws {
        let (viewModel, client, store) = makeViewModel(state: .enteringCode("48291"))
        viewModel.appear()

        viewModel.send(.typeDigit(3))
        viewModel.send(.confirmCode)
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

    // MARK: Not finding the iPad

    private func makeTimingOutViewModel(
        saved: PairCode? = nil
    ) -> (CompanionViewModel, MockControllerClient, MockPairCodeStore) {
        let client = MockControllerClient()
        let store = MockPairCodeStore(enteredPairCode: saved)
        let viewModel = CompanionViewModel(client: client, pairCodes: store, state: .enteringCode("48291"),
                                           connectTimeout: .zero)
        return (viewModel, client, store)
    }

    func test_aTypedCodeThatFindsNoiPad_showsNotFound_andStopsLooking() async {
        let (viewModel, client, store) = makeTimingOutViewModel()

        viewModel.send(.typeDigit(3))
        viewModel.send(.confirmCode)
        await waitUntil { viewModel.state == .notFound("482913") && client.disconnectCount == 1 }

        XCTAssertEqual(viewModel.state, .notFound("482913"))
        XCTAssertEqual(client.disconnectCount, 1)
        XCTAssertNil(store.enteredPairCode)
    }

    func test_connectingInTime_cancelsTheTimeout() async throws {
        let client = MockControllerClient()
        let viewModel = CompanionViewModel(client: client, pairCodes: MockPairCodeStore(),
                                           state: .enteringCode("48291"), connectTimeout: .milliseconds(10))

        viewModel.send(.typeDigit(3))
        viewModel.send(.confirmCode)
        viewModel.send(.linkConnected)
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.state, .connected)
    }

    func test_aSavedCode_keepsLookingWithNoTimeout() async throws {
        let saved = try XCTUnwrap(PairCode("482913"))
        let client = MockControllerClient()
        let viewModel = CompanionViewModel(client: client, pairCodes: MockPairCodeStore(enteredPairCode: saved),
                                           state: .enteringCode(""), connectTimeout: .milliseconds(10))

        viewModel.appear()
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.state, .connecting("482913"))
        viewModel.stop()
    }

    func test_cancel_whileLookingWithASavedCode_forgetsIt() async throws {
        let saved = try XCTUnwrap(PairCode("482913"))
        let (viewModel, client, store) = makeViewModel(state: .enteringCode(""), saved: saved)
        viewModel.appear()

        viewModel.send(.disconnect)
        await waitUntil { client.disconnectCount == 1 }

        XCTAssertEqual(viewModel.state, .enteringCode(""))
        XCTAssertNil(store.enteredPairCode)
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
