import XCTest
@testable import StrumMeng

final class HostMessageHandlerTests: XCTestCase {
    private func playingHandler() -> HostMessageHandler {
        var handler = HostMessageHandler()
        handler.sessionActive = true
        return handler
    }

    func test_ping_isAnsweredWithAPongCarryingArrivalAndSessionState() {
        var handler = playingHandler()
        let output = handler.receive(.ping(sentAt: 5, latencyMs: nil), arrivedAt: 100)
        XCTAssertEqual(output, .reply(.pong(sentAt: 5, receivedAt: 100, sessionActive: true)))
    }

    func test_ping_recordsTheLatencyTheIPhoneMeasured() {
        var handler = HostMessageHandler()
        _ = handler.receive(.ping(sentAt: 5, latencyMs: 12), arrivedAt: 100)
        _ = handler.receive(.ping(sentAt: 6, latencyMs: nil), arrivedAt: 101)
        XCTAssertEqual(handler.latencyMs, 12)
    }

    func test_strumDuringASession_becomesAStrumEventAtItsTouchTime() {
        var handler = playingHandler()
        let id = UUID()
        let output = handler.receive(.strum(id: id, direction: .up, hostTime: 99.98), arrivedAt: 100)
        XCTAssertEqual(output, .strum(StrumEvent(id: id, direction: .up, time: 99.98)))
    }

    func test_unsyncedStrum_usesTheArrivalTime() {
        var handler = playingHandler()
        let id = UUID()
        let output = handler.receive(.strum(id: id, direction: .down, hostTime: nil), arrivedAt: 100)
        XCTAssertEqual(output, .strum(StrumEvent(id: id, direction: .down, time: 100)))
    }

    func test_redundantCopiesOfAStrum_produceOneEvent() {
        var handler = playingHandler()
        let strum = ControllerMessage.strum(id: UUID(), direction: .down, hostTime: 99.99)
        XCTAssertNotEqual(handler.receive(strum, arrivedAt: 100), .ignore)
        XCTAssertEqual(handler.receive(strum, arrivedAt: 100.003), .ignore)
        XCTAssertEqual(handler.receive(strum, arrivedAt: 100.008), .ignore)
    }

    func test_strumOutsideASession_isIgnored() {
        var handler = HostMessageHandler()
        let output = handler.receive(.strum(id: UUID(), direction: .down, hostTime: 99.99), arrivedAt: 100)
        XCTAssertEqual(output, .ignore)
    }

    func test_copiesOfAStrumIgnoredBeforeTheSession_stayIgnoredAfterItStarts() {
        var handler = HostMessageHandler()
        let strum = ControllerMessage.strum(id: UUID(), direction: .down, hostTime: 99.99)
        _ = handler.receive(strum, arrivedAt: 100)
        handler.sessionActive = true
        XCTAssertEqual(handler.receive(strum, arrivedAt: 100.005), .ignore)
    }

    func test_hello_remembersTheControllerName() {
        var handler = HostMessageHandler()
        XCTAssertEqual(handler.receive(.hello(deviceName: "Axel's iPhone"), arrivedAt: 1), .ignore)
        XCTAssertEqual(handler.controllerName, "Axel's iPhone")
    }

    func test_iPadOnlyMessages_areIgnored() {
        var handler = playingHandler()
        XCTAssertEqual(handler.receive(.startSession, arrivedAt: 1), .ignore)
        XCTAssertEqual(handler.receive(.stopSession, arrivedAt: 1), .ignore)
        XCTAssertEqual(handler.receive(.pong(sentAt: 0, receivedAt: 0, sessionActive: true), arrivedAt: 1), .ignore)
    }

    func test_withNoConnection_isNotAlive() {
        XCTAssertFalse(HostMessageHandler().isAlive(now: 100))
    }

    func test_staysAlive_untilTheTimeoutPassesWithoutAMessage() {
        var handler = HostMessageHandler()
        handler.connectionOpened(at: 100)
        XCTAssertTrue(handler.isAlive(now: 100 + HostMessageHandler.livenessTimeout - 0.1))
        XCTAssertFalse(handler.isAlive(now: 100 + HostMessageHandler.livenessTimeout))
    }

    func test_anyMessage_keepsTheConnectionAlive() {
        var handler = HostMessageHandler()
        handler.connectionOpened(at: 100)
        _ = handler.receive(.ping(sentAt: 0, latencyMs: nil), arrivedAt: 104)
        XCTAssertTrue(handler.isAlive(now: 108))
    }

    func test_newConnection_forgetsTheOldControllerButKeepsTheSessionState() {
        var handler = playingHandler()
        _ = handler.receive(.hello(deviceName: "Old iPhone"), arrivedAt: 1)
        _ = handler.receive(.ping(sentAt: 0, latencyMs: 20), arrivedAt: 1)
        handler.connectionOpened(at: 50)
        XCTAssertNil(handler.controllerName)
        XCTAssertNil(handler.latencyMs)
        XCTAssertTrue(handler.sessionActive)
    }
}
