import XCTest
@testable import StrumMeng

final class AsyncBroadcastTests: XCTestCase {
    func test_everySubscriber_receivesEveryValue() async {
        let broadcast = AsyncBroadcast<Int>()
        var first = broadcast.stream().makeAsyncIterator()
        var second = broadcast.stream().makeAsyncIterator()
        broadcast.yield(1)
        broadcast.yield(2)
        let firstValues = [await first.next(), await first.next()]
        let secondValues = [await second.next(), await second.next()]
        XCTAssertEqual(firstValues, [1, 2])
        XCTAssertEqual(secondValues, [1, 2])
    }

    func test_withALatestValue_newSubscribersStartFromIt() async {
        let broadcast = AsyncBroadcast<String>(latest: "unpaired")
        broadcast.yield("searching")
        var iterator = broadcast.stream().makeAsyncIterator()
        broadcast.yield("connected")
        let values = [await iterator.next(), await iterator.next()]
        XCTAssertEqual(values, ["searching", "connected"])
    }

    func test_withoutALatestValue_newSubscribersOnlyGetNewValues() async {
        let broadcast = AsyncBroadcast<Int>()
        broadcast.yield(1)
        var iterator = broadcast.stream().makeAsyncIterator()
        broadcast.yield(2)
        let value = await iterator.next()
        XCTAssertEqual(value, 2)
    }

    func test_latest_reportsTheMostRecentValue() {
        let broadcast = AsyncBroadcast<Bool>(latest: false)
        broadcast.yield(true)
        XCTAssertEqual(broadcast.latest, true)
    }
}
