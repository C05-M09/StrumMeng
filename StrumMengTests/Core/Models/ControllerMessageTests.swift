import XCTest
@testable import StrumMeng

final class ControllerMessageTests: XCTestCase {
    private func roundTrip(_ message: ControllerMessage) throws -> ControllerMessage {
        try ControllerMessage(data: message.encoded())
    }

    func test_everyMessage_survivesEncodingAndDecoding() throws {
        let messages: [ControllerMessage] = [
            .hello(deviceName: "Axel's iPhone"),
            .startSession,
            .stopSession,
            .strum(id: UUID(), direction: .down, hostTime: 1234.5678),
            .strum(id: UUID(), direction: .up, hostTime: nil),
            .ping(sentAt: 10.25, latencyMs: 12.5),
            .ping(sentAt: 10.25, latencyMs: nil),
            .pong(sentAt: 10.25, receivedAt: 99.75, sessionActive: true),
        ]
        for message in messages {
            XCTAssertEqual(try roundTrip(message), message)
        }
    }

    func test_strumTime_keepsSubMillisecondPrecision() throws {
        let message = ControllerMessage.strum(id: UUID(), direction: .down, hostTime: 86_400.000_123)
        XCTAssertEqual(try roundTrip(message), message)
    }

    func test_garbageData_throwsInsteadOfCrashing() {
        XCTAssertThrowsError(try ControllerMessage(data: Data([0xFF, 0x00, 0x13])))
    }

    func test_unknownMessageKind_throws() {
        let data = Data(#"{"selfDestruct":{}}"#.utf8)
        XCTAssertThrowsError(try ControllerMessage(data: data))
    }

    func test_encodedStrum_fitsInOneSmallDatagram() throws {
        let data = try ControllerMessage.strum(id: UUID(), direction: .down, hostTime: 123_456.789).encoded()
        XCTAssertLessThan(data.count, 512)
    }
}
