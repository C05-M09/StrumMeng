import XCTest
@testable import StrumMeng

final class PairCodeTests: XCTestCase {
    func test_sixDigits_isAValidCode() {
        XCTAssertEqual(PairCode("012345")?.value, "012345")
    }

    func test_wrongLength_isRejected() {
        XCTAssertNil(PairCode("12345"))
        XCTAssertNil(PairCode("1234567"))
        XCTAssertNil(PairCode(""))
    }

    func test_nonDigits_areRejected() {
        XCTAssertNil(PairCode("12a456"))
        XCTAssertNil(PairCode("12 456"))
        XCTAssertNil(PairCode("١٢٣٤٥٦"), "Non-ASCII digits would not match the code typed on the other device")
    }

    func test_randomCode_isAlwaysSixDigits_includingLeadingZeros() {
        for _ in 0..<500 {
            let code = PairCode.random()
            XCTAssertNotNil(PairCode(code.value), "\(code) is not six digits")
        }
    }
}
