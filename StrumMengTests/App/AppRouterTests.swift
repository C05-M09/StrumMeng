import XCTest
@testable import StrumMeng

@MainActor
final class AppRouterTests: XCTestCase {
    private let listen = AppRoute.listen(patternID: "foundation", bpm: 80)
    private let play = AppRoute.play(patternID: "foundation", bpm: 80)

    func test_replaceLast_swapsTheTopScreen() {
        let router = AppRouter()
        router.path = [.practiceList, listen]

        router.replaceLast(with: play)

        XCTAssertEqual(router.path, [.practiceList, play])
    }

    func test_replaceLast_onAnEmptyStack_pushes() {
        let router = AppRouter()

        router.replaceLast(with: .practiceList)

        XCTAssertEqual(router.path, [.practiceList])
    }

    func test_popTo_removesEverythingAboveTheRoute() {
        let router = AppRouter()
        router.path = [.practiceList, listen, play]

        router.popTo(.practiceList)

        XCTAssertEqual(router.path, [.practiceList])
    }

    func test_popTo_routeAlreadyOnTop_changesNothing() {
        let router = AppRouter()
        router.path = [.practiceList]

        router.popTo(.practiceList)

        XCTAssertEqual(router.path, [.practiceList])
    }

    func test_popTo_routeNotInTheStack_makesItTheOnlyScreen() {
        let router = AppRouter()
        router.path = [listen]

        router.popTo(.practiceList)

        XCTAssertEqual(router.path, [.practiceList])
    }
}
