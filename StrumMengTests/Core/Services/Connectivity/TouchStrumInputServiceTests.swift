import XCTest
@testable import StrumMeng

final class TouchStrumInputServiceTests: XCTestCase {
    func test_swipePastThreshold_emitsOneStrumAtTheTouchEventTime() async {
        let input = TouchStrumInputService()
        var strums = input.strums.makeAsyncIterator()

        input.dragChanged(translation: 6, at: 41.99)
        input.dragChanged(translation: 20, at: 42)
        input.dragChanged(translation: 40, at: 42.01)      // same direction: no second strum

        let strum = await strums.next()
        XCTAssertEqual(strum?.direction, .down)
        XCTAssertEqual(strum?.time, 42)
    }

    func test_eachGesture_startsFromZero_andGetsItsOwnID() async {
        let input = TouchStrumInputService()
        var strums = input.strums.makeAsyncIterator()

        input.dragChanged(translation: 20, at: 1)
        input.dragEnded()
        input.dragChanged(translation: -20, at: 2)

        let first = await strums.next()
        let second = await strums.next()
        XCTAssertEqual(first?.direction, .down)
        XCTAssertEqual(second?.direction, .up)
        XCTAssertNotEqual(first?.id, second?.id)
    }
}
