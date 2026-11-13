import Foundation

/// Display model for one row in the Showtime records list.
/// Own type, apart from Practice's `RecordRowModel`: a song's tempo is fixed so there is no BPM,
/// and every row has stars.
struct ShowtimeRecordRowModel: Identifiable, Equatable, Sendable {
    let id: UUID
    let rank: Int
    let accuracyPercent: Int
    let perfectCount: Int
    let tooEarlyCount: Int
    let missCount: Int
    /// 0...3, from `StarRating`, the same rule as the summary.
    let stars: Int

    /// `rank` is 1-based and is decided by the order the repository returns.
    init(rank: Int, result: SessionResult) {
        self.id = result.id
        self.rank = rank
        // SessionResult.accuracy is a fraction 0...1.
        self.accuracyPercent = Int((result.accuracy * 100).rounded())
        self.perfectCount = result.perfectCount
        self.tooEarlyCount = result.tooEarlyCount
        self.missCount = result.missCount
        self.stars = StarRating.stars(for: result.accuracy)
    }
}
