//
//  AppContainerTests.swift
//  StrumMeng
//
//  Created by rasyel on 29/10/26.
//

import XCTest
@testable import StrumMeng

@MainActor
final class AppContainerTests: XCTestCase {

    private var router: AppRouter!
    private var sut: AppContainer!

    override func setUp() {
        super.setUp()
        router = AppRouter()
        sut = AppContainer(router: router)
    }

    override func tearDown() {
        sut = nil
        router = nil
        super.tearDown()
    }

    // MARK: - Home

    func test_homeViewModel_tapPractice_pushesPracticeList() {
        let home = sut.makeHomeViewModel()

        home.send(.tapPractice)

        XCTAssertEqual(router.path.count, 1)
    }

    func test_homeViewModel_tapGuidebook_showsOverlayWithoutPushingRoute() {
        let home = sut.makeHomeViewModel()

        home.send(.tapGuidebook)

        XCTAssertEqual(router.path.count, 0, "Guidebook adalah overlay, bukan route")
        XCTAssertEqual(home.presentedOverlay, .guidebook)
    }

    func test_homeViewModel_tapOption_doesNotPushRoute() {
        let home = sut.makeHomeViewModel()

        home.send(.tapOption)

        XCTAssertEqual(router.path.count, 0, "Option adalah overlay, bukan route")
        XCTAssertEqual(home.presentedOverlay, .option)
    }

    func test_homeViewModel_tapShowtime_doesNotPushRoute() {
        let home = sut.makeHomeViewModel()

        home.send(.tapShowtime)

        XCTAssertEqual(router.path.count, 0)
        XCTAssertNil(home.presentedOverlay)
    }

    // MARK: - Option

    func test_optionViewModel_tapBack_callsInjectedAction() {
        var backCount = 0
        let option = sut.makeOptionViewModel { backCount += 1 }

        option.send(.tapBack)

        XCTAssertEqual(backCount, 1)
    }

    func test_optionViewModel_tapBack_doesNotPopRouter() {
        router.push(.practiceList)
        let option = sut.makeOptionViewModel {}

        option.send(.tapBack)

        XCTAssertEqual(router.path.count, 1, "Back di Option menutup overlay, tidak men-pop router")
    }

    func test_optionOverlay_closesThroughHomeViewModel() {
        // Meniru penyambungan di ContentView
        let home = sut.makeHomeViewModel()
        let option = sut.makeOptionViewModel { [weak home] in
            home?.send(.dismissOverlay)
        }
        home.send(.tapOption)
        XCTAssertEqual(home.presentedOverlay, .option)

        option.send(.tapBack)

        XCTAssertNil(home.presentedOverlay)
    }
}
