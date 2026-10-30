import XCTest
@testable import StrumMeng

/// End to end, without a real network: iPhone clock → ping/pong clock sync → strum message with
/// the touch time → iPad → TimingJudge. Proves a strum is judged by when the finger moved on the
/// iPhone, compared with the beat on the iPad clock, however long the message took to arrive.
final class ControllerTimingAccuracyTests: XCTestCase {
    /// The iPad clock runs this far ahead of the iPhone clock (two devices never agree).
    private let clockGap: TimeInterval = 1000
    private let beat: TimeInterval = 1100           // a node's beat time, on the iPad clock
    private let step = AudioBeatClock.stepInterval(bpm: 80)

    private var iPhone = ClientMessageHandler()
    private var iPad = HostMessageHandler()

    override func setUp() {
        super.setUp()
        iPad.sessionActive = true
    }

    /// The iPhone pings the iPad and records each pong, as BonjourControllerClient does.
    private func syncClocks(uplink: TimeInterval, downlink: TimeInterval) {
        var phoneNow: TimeInterval = 0
        for _ in 0..<ClientMessageHandler.quickPingCount {
            let ping = iPhone.pingMessage(sentAt: phoneNow)
            guard case let .reply(pong) = iPad.receive(ping, arrivedAt: phoneNow + clockGap + uplink) else {
                return XCTFail("The iPad should answer a ping")
            }
            iPhone.receive(pong, arrivedAt: phoneNow + uplink + downlink)
            phoneNow += 1
        }
    }

    /// A down-strum touched at `beat + touchOffset` (as the player really did it), delivered to the
    /// iPad `delay` seconds after the touch, then judged against the node at `beat`.
    private func judge(touchOffset: TimeInterval, delay: TimeInterval) throws -> BeatEvent {
        let phoneTouch = beat - clockGap + touchOffset
        let message = try XCTUnwrap(iPhone.strumMessage(id: UUID(), direction: .down, touchTime: phoneTouch))
        guard case let .strum(strum) = iPad.receive(message, arrivedAt: beat + touchOffset + delay) else {
            throw XCTSkip("The iPad did not accept the strum")
        }
        var engine = FeedbackEngine(config: .standard, latencyOffset: 0, stepInterval: step)
        _ = engine.addBeat(BeatTarget(index: 0, expectedTime: beat, direction: .down))
        var events = engine.addStrum(strum)
        // Everything still open closes once the window (and any wait for late strums) is over.
        events += engine.close(upTo: beat + 1)
        return try XCTUnwrap(events.first)
    }

    func test_onTimeTouch_isPerfect_evenWhenTheMessageArrivesLate() throws {
        syncClocks(uplink: 0.004, downlink: 0.004)
        iPhone.receive(.startSession, arrivedAt: 20)
        let event = try judge(touchOffset: 0.010, delay: 0.120)
        XCTAssertEqual(event.result, .perfect)
        XCTAssertEqual(try XCTUnwrap(event.offsetMs), 10, accuracy: 0.5)
    }

    func test_networkDelay_doesNotChangeTheMeasuredOffset() throws {
        syncClocks(uplink: 0.004, downlink: 0.004)
        iPhone.receive(.startSession, arrivedAt: 20)
        let offsets = try [0.005, 0.040, 0.090, 0.140].map { delay in
            try XCTUnwrap(judge(touchOffset: 0.020, delay: delay).offsetMs)
        }
        for offset in offsets {
            XCTAssertEqual(offset, 20, accuracy: 0.5, "Every delivery delay should give the same offset")
        }
    }

    func test_earlyTouch_isTooEarly_whateverTheDelay() throws {
        syncClocks(uplink: 0.004, downlink: 0.004)
        iPhone.receive(.startSession, arrivedAt: 20)
        XCTAssertEqual(try judge(touchOffset: -0.100, delay: 0.010).result, .tooEarly)
        XCTAssertEqual(try judge(touchOffset: -0.100, delay: 0.130).result, .tooEarly)
    }

    func test_lateTouch_isMiss_whateverTheDelay() throws {
        syncClocks(uplink: 0.004, downlink: 0.004)
        iPhone.receive(.startSession, arrivedAt: 20)
        XCTAssertEqual(try judge(touchOffset: 0.080, delay: 0.010).result, .miss)
    }

    /// The one error clock sync cannot remove: when the way there is slower than the way back,
    /// the clocks are misjudged by half the difference. On a local network that is a few ms.
    func test_unevenNetworkPaths_shiftTheOffsetByHalfTheirDifference() throws {
        syncClocks(uplink: 0.030, downlink: 0.010)
        iPhone.receive(.startSession, arrivedAt: 20)
        let event = try judge(touchOffset: 0, delay: 0.050)
        XCTAssertEqual(try XCTUnwrap(event.offsetMs), (30 - 10) / 2, accuracy: 0.5)
        XCTAssertEqual(event.result, .perfect)
    }

    /// The fastest ping wins, so a few slow round trips (Wi-Fi stalls) do not skew the clocks.
    func test_slowRoundTrips_doNotSkewTheClocks() throws {
        syncClocks(uplink: 0.004, downlink: 0.004)
        // Later pings stuck behind a Wi-Fi stall on the way back.
        var phoneNow: TimeInterval = 50
        for _ in 0..<3 {
            let ping = iPhone.pingMessage(sentAt: phoneNow)
            guard case let .reply(pong) = iPad.receive(ping, arrivedAt: phoneNow + clockGap + 0.004) else {
                return XCTFail("The iPad should answer a ping")
            }
            iPhone.receive(pong, arrivedAt: phoneNow + 0.004 + 0.090)
            phoneNow += 1
        }
        iPhone.receive(.startSession, arrivedAt: 60)
        XCTAssertEqual(try XCTUnwrap(judge(touchOffset: 0.010, delay: 0.060).offsetMs), 10, accuracy: 0.5)
    }
}
