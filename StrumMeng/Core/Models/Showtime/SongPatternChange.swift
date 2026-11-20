/// Pattern changes are expressed in eighth-note slots, just like chord changes.
struct SongPatternChange: Equatable, Sendable {
    let slot: Int
    let pattern: StrumPattern
}
