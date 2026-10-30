import XCTest
@testable import StrumMeng

@MainActor
final class SessionResultStoreTests: XCTestCase {
    private func result(id: UUID = UUID(), bpm: Int = 80) -> SessionResult {
        SessionResultBuilder.build(id: id, patternID: "foundation", bpm: bpm,
                                   beatEvents: PracticeFixtures.events([.perfect, .miss]),
                                   createdAt: Date(timeIntervalSince1970: 0))
    }

    func test_addedResult_canBeFoundByItsID() {
        let store = SessionResultStore()
        let session = result()

        store.add(session)

        XCTAssertEqual(store.result(for: session.id), session)
    }

    func test_unknownID_returnsNil() {
        let store = SessionResultStore()
        store.add(result())

        XCTAssertNil(store.result(for: UUID()))
    }

    func test_addingTheSameIDAgain_keepsOneResult() {
        let store = SessionResultStore()
        let id = UUID()

        store.add(result(id: id, bpm: 80))
        store.add(result(id: id, bpm: 70))

        XCTAssertEqual(store.result(for: id)?.bpm, 70)
    }
}
