import XCTest
import UIKit
@testable import StrumMeng

final class ShowtimeRecordRowModelTests: XCTestCase {
    private func result(accuracy: Double) -> SessionResult {
        SessionResult(id: UUID(), patternID: "foundation", songID: "twinkle", bpm: 100, accuracy: accuracy,
                      perfectCount: 0, tooEarlyCount: 0, missCount: 0, createdAt: Date(), beatEvents: [])
    }

    func test_rowStars_followTheSummarysStarRule() {
        for accuracy in [0.0, 0.504, 0.505, 0.65, 0.66, 0.854, 0.855, 1.0] {
            XCTAssertEqual(ShowtimeRecordRowModel(rank: 1, result: result(accuracy: accuracy)).stars,
                           StarRating.stars(for: accuracy), "accuracy \(accuracy)")
        }
    }

    /// The star images moved to the catalog's `Star` folder once; a wrong path draws nothing.
    func test_everyStarCount_hasAnImageInTheCatalog() {
        for count in 0...3 {
            XCTAssertNotNil(UIImage(named: ShowtimeAssets.star(count)), ShowtimeAssets.star(count))
        }
    }
}
