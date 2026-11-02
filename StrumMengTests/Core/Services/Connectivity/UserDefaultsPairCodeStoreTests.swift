import XCTest
@testable import StrumMeng

final class UserDefaultsPairCodeStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "pair-code-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func test_hostPairCode_staysTheSameAcrossLaunches() {
        let first = UserDefaultsPairCodeStore(defaults: defaults).hostPairCode()
        let second = UserDefaultsPairCodeStore(defaults: defaults).hostPairCode()

        XCTAssertEqual(first, second)
    }

    func test_hostPairCode_replacesAnInvalidSavedCode() {
        defaults.set("not a code", forKey: "controller.hostPairCode")

        let code = UserDefaultsPairCodeStore(defaults: defaults).hostPairCode()

        XCTAssertEqual(code.value.count, PairCode.length)
        XCTAssertEqual(UserDefaultsPairCodeStore(defaults: defaults).hostPairCode(), code)
    }

    func test_enteredPairCode_isNilUntilSaved() {
        XCTAssertNil(UserDefaultsPairCodeStore(defaults: defaults).enteredPairCode)
    }

    func test_enteredPairCode_survivesALaunch() {
        let code = PairCode("482913")
        UserDefaultsPairCodeStore(defaults: defaults).setEnteredPairCode(code)

        XCTAssertEqual(UserDefaultsPairCodeStore(defaults: defaults).enteredPairCode, code)
    }

    func test_settingNil_forgetsTheEnteredCode() {
        let store = UserDefaultsPairCodeStore(defaults: defaults)
        store.setEnteredPairCode(PairCode("482913"))

        store.setEnteredPairCode(nil)

        XCTAssertNil(store.enteredPairCode)
    }
}
