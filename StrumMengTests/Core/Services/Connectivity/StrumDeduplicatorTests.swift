import XCTest
@testable import StrumMeng

final class StrumDeduplicatorTests: XCTestCase {
    func test_firstCopy_isNew() {
        var deduplicator = StrumDeduplicator()
        XCTAssertTrue(deduplicator.isNew(UUID()))
    }

    func test_redundantCopies_areDropped() {
        var deduplicator = StrumDeduplicator()
        let id = UUID()
        XCTAssertTrue(deduplicator.isNew(id))
        XCTAssertFalse(deduplicator.isNew(id))
        XCTAssertFalse(deduplicator.isNew(id))
    }

    func test_differentStrums_areAllNew() {
        var deduplicator = StrumDeduplicator()
        XCTAssertTrue(deduplicator.isNew(UUID()))
        XCTAssertTrue(deduplicator.isNew(UUID()))
    }

    func test_copiesArrivingOutOfOrder_areStillDropped() {
        var deduplicator = StrumDeduplicator()
        let first = UUID()
        let second = UUID()
        XCTAssertTrue(deduplicator.isNew(second))
        XCTAssertTrue(deduplicator.isNew(first))
        XCTAssertFalse(deduplicator.isNew(second))
        XCTAssertFalse(deduplicator.isNew(first))
    }

    func test_memoryIsBounded_soVeryOldIdsAreForgotten() {
        var deduplicator = StrumDeduplicator()
        let oldest = UUID()
        XCTAssertTrue(deduplicator.isNew(oldest))
        for _ in 0..<StrumDeduplicator.capacity {
            XCTAssertTrue(deduplicator.isNew(UUID()))
        }
        XCTAssertTrue(deduplicator.isNew(oldest))
    }
}
