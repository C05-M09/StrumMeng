import Foundation

/// One eighth-note slot on the scrolling lane.
struct PlayLaneNode: Identifiable, Equatable {
    let index: Int
    /// nil = rest: only the count label is drawn.
    let arrow: BeatNodeView.Arrow?
    let countLabel: String
    /// Session time (seconds after the first slot) at which the node sits in the hit ring.
    let time: TimeInterval
    var judgement: PlayJudgement?

    var id: Int { index }
}
