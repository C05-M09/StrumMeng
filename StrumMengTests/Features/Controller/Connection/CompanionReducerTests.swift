import XCTest
@testable import StrumMeng

final class CompanionReducerTests: XCTestCase {
    func test_typingADigit_addsItToTheCode() {
        XCTAssertEqual(reduce(.enteringCode("4"), .typeDigit(8)), .enteringCode("48"))
    }

    func test_theSixthDigit_completesTheCode_withoutConnecting() {
        XCTAssertEqual(reduce(.enteringCode("48291"), .typeDigit(3)), .enteringCode("482913"))
    }

    func test_aSeventhDigit_isIgnored() {
        XCTAssertEqual(reduce(.enteringCode("482913"), .typeDigit(7)), .enteringCode("482913"))
    }

    func test_confirm_connectsWithAFullCode() {
        XCTAssertEqual(reduce(.enteringCode("482913"), .confirmCode), .connecting("482913"))
    }

    func test_confirm_isIgnoredWithAnIncompleteCode() {
        XCTAssertEqual(reduce(.enteringCode("48291"), .confirmCode), .enteringCode("48291"))
        XCTAssertEqual(reduce(.enteringCode(""), .confirmCode), .enteringCode(""))
    }

    func test_confirm_afterNotFound_triesTheSameCodeAgain() {
        XCTAssertEqual(reduce(.notFound("482913"), .confirmCode), .connecting("482913"))
    }

    func test_confirm_isIgnoredWhileConnectingOrOnThePad() {
        XCTAssertEqual(reduce(.connecting("482913"), .confirmCode), .connecting("482913"))
        XCTAssertEqual(reduce(.connected, .confirmCode), .connected)
        XCTAssertEqual(reduce(.reconnecting, .confirmCode), .reconnecting)
    }

    func test_aValueThatIsNotADigit_isIgnored() {
        XCTAssertEqual(reduce(.enteringCode("4"), .typeDigit(10)), .enteringCode("4"))
        XCTAssertEqual(reduce(.enteringCode("4"), .typeDigit(-1)), .enteringCode("4"))
    }

    func test_delete_removesTheLastDigit_andIsSafeOnAnEmptyCode() {
        XCTAssertEqual(reduce(.enteringCode("48"), .deleteDigit), .enteringCode("4"))
        XCTAssertEqual(reduce(.enteringCode(""), .deleteDigit), .enteringCode(""))
    }

    func test_resumePairing_connectsWithTheSavedCode() {
        XCTAssertEqual(reduce(.enteringCode(""), .resumePairing("482913")), .connecting("482913"))
    }

    func test_resumePairing_isIgnoredOnceConnected() {
        XCTAssertEqual(reduce(.connected, .resumePairing("482913")), .connected)
    }

    func test_linkConnected_opensThePadWhileConnecting() {
        XCTAssertEqual(reduce(.connecting("482913"), .linkConnected), .connected)
        XCTAssertEqual(reduce(.enteringCode("48"), .linkConnected), .enteringCode("48"))
    }

    func test_linkLost_reconnectsOnlyAfterConnecting() {
        XCTAssertEqual(reduce(.connected, .linkLost), .reconnecting)
        XCTAssertEqual(reduce(.connecting("482913"), .linkLost), .connecting("482913"))
    }

    func test_linkConnected_endsReconnecting() {
        XCTAssertEqual(reduce(.reconnecting, .linkConnected), .connected)
    }

    func test_disconnect_returnsToAnEmptyCode() {
        XCTAssertEqual(reduce(.connected, .disconnect), .enteringCode(""))
        XCTAssertEqual(reduce(.connecting("482913"), .disconnect), .enteringCode(""))
        XCTAssertEqual(reduce(.reconnecting, .disconnect), .enteringCode(""))
    }

    func test_aTimeout_showsNotFound_onlyWhileConnecting() {
        XCTAssertEqual(reduce(.connecting("482913"), .connectionTimedOut), .notFound("482913"))
        XCTAssertEqual(reduce(.connected, .connectionTimedOut), .connected)
    }

    func test_typingAfterNotFound_startsANewCode() {
        XCTAssertEqual(reduce(.notFound("482913"), .typeDigit(7)), .enteringCode("7"))
    }

    func test_deleteAfterNotFound_clearsTheCode() {
        XCTAssertEqual(reduce(.notFound("482913"), .deleteDigit), .enteringCode(""))
    }

    func test_typingWhileConnectingOrConnected_isIgnored() {
        XCTAssertEqual(reduce(.connecting("482913"), .typeDigit(1)), .connecting("482913"))
        XCTAssertEqual(reduce(.connecting("482913"), .deleteDigit), .connecting("482913"))
        XCTAssertEqual(reduce(.connected, .typeDigit(1)), .connected)
    }
}
