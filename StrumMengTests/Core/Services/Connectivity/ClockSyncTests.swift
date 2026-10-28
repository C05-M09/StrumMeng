import XCTest
@testable import StrumMeng

final class ClockSyncTests: XCTestCase {
    func test_beforeAnyPong_isNotSynced() {
        let sync = ClockSync()
        XCTAssertNil(sync.offset)
        XCTAssertNil(sync.latencyMs)
        XCTAssertNil(sync.hostTime(fromLocalTime: 5))
    }

    func test_symmetricRoundTrip_givesTheExactOffset() throws {
        // iPad is 100 s ahead; 10 ms each way.
        var sync = ClockSync()
        sync.record(sentAt: 1.000, hostReceivedAt: 101.010, receivedBackAt: 1.020)
        XCTAssertEqual(try XCTUnwrap(sync.offset), 100, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(sync.latencyMs), 10, accuracy: 0.000_001)
    }

    func test_iPhoneAheadOfIPad_givesANegativeOffset() throws {
        var sync = ClockSync()
        sync.record(sentAt: 500.000, hostReceivedAt: 20.005, receivedBackAt: 500.010)
        XCTAssertEqual(try XCTUnwrap(sync.offset), -480, accuracy: 0.000_001)
    }

    func test_offset_comesFromTheFastestRoundTrip() throws {
        var sync = ClockSync()
        // Slow, asymmetric round trip (stuck in a queue on the way back): a skewed estimate.
        sync.record(sentAt: 1.000, hostReceivedAt: 101.010, receivedBackAt: 1.200)
        // Fast round trip: an accurate estimate.
        sync.record(sentAt: 2.000, hostReceivedAt: 102.005, receivedBackAt: 2.010)
        XCTAssertEqual(try XCTUnwrap(sync.offset), 100, accuracy: 0.000_001)
    }

    func test_latency_reportsTheLatestRoundTrip() throws {
        var sync = ClockSync()
        sync.record(sentAt: 2.000, hostReceivedAt: 102.005, receivedBackAt: 2.010)
        sync.record(sentAt: 3.000, hostReceivedAt: 103.030, receivedBackAt: 3.060)
        XCTAssertEqual(try XCTUnwrap(sync.latencyMs), 30, accuracy: 0.000_001)
    }

    func test_negativeOrTooSlowRoundTrips_areIgnored() {
        var sync = ClockSync()
        sync.record(sentAt: 5, hostReceivedAt: 100, receivedBackAt: 4)
        sync.record(sentAt: 5, hostReceivedAt: 100, receivedBackAt: 5 + ClockSync.maxRoundTrip)
        XCTAssertNil(sync.offset)
    }

    func test_onlyRecentSamplesAreKept() throws {
        var sync = ClockSync()
        // A very fast but old sample with a stale offset...
        sync.record(sentAt: 0, hostReceivedAt: 50, receivedBackAt: 0.001)
        // ...is pushed out by newer, slower ones once the window is full.
        for i in 1...ClockSync.sampleLimit {
            let sent = Double(i)
            sync.record(sentAt: sent, hostReceivedAt: sent + 100.010, receivedBackAt: sent + 0.020)
        }
        XCTAssertEqual(try XCTUnwrap(sync.offset), 100, accuracy: 0.000_001)
    }

    func test_reset_forgetsTheOffset() {
        var sync = ClockSync()
        sync.record(sentAt: 1.000, hostReceivedAt: 101.010, receivedBackAt: 1.020)
        sync.reset()
        XCTAssertNil(sync.offset)
    }

    func test_hostTime_appliesTheOffsetToALocalTouchTime() throws {
        var sync = ClockSync()
        sync.record(sentAt: 1.000, hostReceivedAt: 101.010, receivedBackAt: 1.020)
        XCTAssertEqual(try XCTUnwrap(sync.hostTime(fromLocalTime: 7.5)), 107.5, accuracy: 0.000_001)
    }
}
