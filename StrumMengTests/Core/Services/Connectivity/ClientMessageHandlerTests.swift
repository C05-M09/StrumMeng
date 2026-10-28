import XCTest
@testable import StrumMeng

final class ClientMessageHandlerTests: XCTestCase {
    func test_newHandler_hasNoSessionAndNoClockSync() {
        let handler = ClientMessageHandler()
        XCTAssertFalse(handler.sessionActive)
        XCTAssertNil(handler.clock.offset)
    }

    func test_pong_syncsTheClock() throws {
        var handler = ClientMessageHandler()
        handler.receive(.pong(sentAt: 1.000, receivedAt: 101.010, sessionActive: false), arrivedAt: 1.020)
        XCTAssertEqual(try XCTUnwrap(handler.clock.offset), 100, accuracy: 0.000_001)
    }

    func test_startAndStopSession_toggleTheSession() {
        var handler = ClientMessageHandler()
        handler.receive(.startSession, arrivedAt: 1)
        XCTAssertTrue(handler.sessionActive)
        handler.receive(.stopSession, arrivedAt: 2)
        XCTAssertFalse(handler.sessionActive)
    }

    func test_pong_correctsALostStartSession() {
        var handler = ClientMessageHandler()
        handler.receive(.pong(sentAt: 1, receivedAt: 101, sessionActive: true), arrivedAt: 1.02)
        XCTAssertTrue(handler.sessionActive)
    }

    func test_strumOutsideASession_isNotSent() {
        let handler = ClientMessageHandler()
        XCTAssertNil(handler.strumMessage(id: UUID(), direction: .down, touchTime: 5))
    }

    func test_strumDuringASession_carriesTheTouchTimeOnTheIPadClock() {
        var handler = ClientMessageHandler()
        handler.receive(.pong(sentAt: 1.000, receivedAt: 101.010, sessionActive: true), arrivedAt: 1.020)
        let id = UUID()
        guard case let .strum(sentID, direction, hostTime)? = handler.strumMessage(id: id, direction: .up, touchTime: 7.5) else {
            return XCTFail("Expected a strum message")
        }
        XCTAssertEqual(sentID, id)
        XCTAssertEqual(direction, .up)
        XCTAssertEqual(hostTime ?? 0, 107.5, accuracy: 0.000_001)
    }

    func test_strumBeforeTheClockSyncs_hasNoHostTime() {
        var handler = ClientMessageHandler()
        handler.receive(.startSession, arrivedAt: 1)
        let id = UUID()
        XCTAssertEqual(handler.strumMessage(id: id, direction: .down, touchTime: 5),
                       .strum(id: id, direction: .down, hostTime: nil))
    }

    func test_ping_reportsTheMeasuredLatency() {
        var handler = ClientMessageHandler()
        XCTAssertEqual(handler.pingMessage(sentAt: 1), .ping(sentAt: 1, latencyMs: nil))
        handler.receive(.pong(sentAt: 1.000, receivedAt: 101.010, sessionActive: false), arrivedAt: 1.020)
        guard case let .ping(_, latencyMs) = handler.pingMessage(sentAt: 2) else { return XCTFail("Expected a ping") }
        XCTAssertEqual(latencyMs ?? 0, 10, accuracy: 0.000_001)
    }

    func test_pings_areQuickAtFirstThenEverySecond() {
        XCTAssertEqual(ClientMessageHandler.pingDelay(afterPing: 1), .milliseconds(150))
        XCTAssertEqual(ClientMessageHandler.pingDelay(afterPing: ClientMessageHandler.quickPingCount - 1), .milliseconds(150))
        XCTAssertEqual(ClientMessageHandler.pingDelay(afterPing: ClientMessageHandler.quickPingCount), .seconds(1))
    }

    func test_newConnection_forgetsTheOldClockAndSession() {
        var handler = ClientMessageHandler()
        handler.receive(.pong(sentAt: 1, receivedAt: 101, sessionActive: true), arrivedAt: 1.02)
        handler.connectionOpened(at: 50)
        XCTAssertNil(handler.clock.offset)
        XCTAssertFalse(handler.sessionActive)
        XCTAssertTrue(handler.isAlive(now: 50))
    }

    func test_goesQuiet_afterTheTimeoutWithoutAMessage() {
        var handler = ClientMessageHandler()
        handler.connectionOpened(at: 100)
        handler.receive(.pong(sentAt: 0, receivedAt: 0, sessionActive: false), arrivedAt: 103)
        XCTAssertTrue(handler.isAlive(now: 103 + ClientMessageHandler.livenessTimeout - 0.1))
        XCTAssertFalse(handler.isAlive(now: 103 + ClientMessageHandler.livenessTimeout))
    }
}
