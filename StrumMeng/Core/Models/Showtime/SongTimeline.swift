import Foundation

/// Both preview and gameplay unfold this same musical grid. Rests occupy time too.
struct SongTimeline: Equatable, Sendable {
    let song: Song
    var slotInterval: TimeInterval { 60 / Double(max(1, song.bpm)) / 2 }
    var totalSlots: Int { max(0, song.barCount) * 8 }
    var duration: TimeInterval { Double(totalSlots) * slotInterval }
    var strokes: [Stroke] {
        guard !song.strokes.isEmpty else { return [] }
        return (0..<totalSlots).map { stroke(at: $0) }
    }
    func stroke(at slot: Int) -> Stroke {
        guard slot >= 0, slot < totalSlots, !song.strokes.isEmpty else { return .rest }
        if let change = song.patternChanges.filter({ $0.slot <= slot }).max(by: { $0.slot < $1.slot }),
           !change.pattern.strokes.isEmpty {
            return change.pattern.strokes[(slot - change.slot) % change.pattern.strokes.count]
        }
        return song.strokes[slot % song.strokes.count]
    }
    /// Each distinct pattern is listened to on C, independently of the song's chord schedule.
    var previewPatterns: [StrumPattern] {
        let base = StrumPattern(id: song.patternID,
            name: PatternCatalog.all.first(where: { $0.id == song.patternID })?.name ?? "Pattern 1",
            strokes: song.strokes, beatLabels: song.strokes.indices.map { PlayTimeline.countLabels[$0 % 8] },
            beatsPerPattern: song.strokes.count / 2, suggestedOrder: 1, defaultBPM: song.bpm)
        let candidates = [base] + song.patternChanges.sorted(by: { $0.slot < $1.slot }).map(\.pattern)
        return candidates.reduce(into: []) { result, pattern in
            guard !result.contains(where: { $0.id == pattern.id && $0.strokes == pattern.strokes }) else { return }
            result.append(pattern)
        }
    }
    func chord(at slot: Int) -> String? {
        song.chords.filter { $0.slot <= slot }.max(by: { $0.slot < $1.slot })?.chord
    }
    /// Initial chord plus actual changes only; repeated metadata entries do not create extra labels.
    var chordLabels: [Int: String] {
        var labels: [Int: String] = [:]
        var previous: String?
        for slot in 0..<totalSlots {
            guard let current = chord(at: slot), current != previous else { continue }
            labels[slot] = current
            previous = current
        }
        return labels
    }
    /// One unfolded pattern, played once by the existing Practice engine.
    var sessionPattern: StrumPattern {
        StrumPattern(id: song.patternID, name: song.title, strokes: strokes,
                     beatLabels: (0..<totalSlots).map { PlayTimeline.countLabels[$0 % 8] },
                     beatsPerPattern: totalSlots / 2, suggestedOrder: 1, defaultBPM: song.bpm)
    }
}
