import UIKit
import XCTest
@testable import StrumMeng

final class DeviceRoleTests: XCTestCase {
    func test_iPhone_isTheController() {
        XCTAssertEqual(DeviceRole(idiom: .phone), .controller)
    }

    func test_iPad_isTheHost() {
        XCTAssertEqual(DeviceRole(idiom: .pad), .host)
    }

    func test_unknownIdiom_fallsBackToHost() {
        XCTAssertEqual(DeviceRole(idiom: .unspecified), .host)
    }
}
