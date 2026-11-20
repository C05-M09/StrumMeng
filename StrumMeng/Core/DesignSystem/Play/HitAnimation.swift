import Foundation

/// The hit animation, as in the test-audio prototype. Pure maths of how long ago a result appeared,
/// so it stays locked to session time. Colour only (CLAUDE.md §9):
/// - Hit (Perfect / Too Early): the node stays in the ring, grows and fades; a colour wave spreads
///   from the ring, and the ring holds the result colour for a moment.
/// - Miss: the node turns grey and faint and keeps moving past the ring.
/// - Every swipe, judged or not: the ring's stroke thickens for a moment.
enum HitAnimation {
    static let hitDuration: TimeInterval = 0.3
    static let ringColourDuration: TimeInterval = 0.2
    static let swipePulseDuration: TimeInterval = 0.12
    static let waveDuration: TimeInterval = 0.35

    /// Seconds since the judgement, or nil before it (or when there is none).
    static func age(of judgement: PlayJudgement?, songTime: TimeInterval) -> TimeInterval? {
        guard let judgement, songTime >= judgement.time else { return nil }
        return songTime - judgement.time
    }

    static func node(judgement: PlayJudgement?, songTime: TimeInterval) -> NodeHitAppearance {
        guard let judgement, let age = age(of: judgement, songTime: songTime) else { return .resting }
        var look = NodeHitAppearance()
        if judgement.feedback == .miss {
            look.greyedOut = true
            look.opacity = 0.45
        } else {
            look.snapsToRing = true
            look.scale = 1 + 1.2 * age
            look.opacity = max(0, 1 - age / hitDuration)
        }
        return look
    }

    /// 1 while the ring shows the latest result's colour, 0 otherwise.
    static func ringStrength(judgement: PlayJudgement?, songTime: TimeInterval) -> Double {
        guard let age = age(of: judgement, songTime: songTime) else { return 0 }
        return age < ringColourDuration ? 1 : 0
    }

    /// Stroke multiplier for the ring: thicker for a moment after every swipe, so the player always
    /// sees that the swipe registered.
    static func ringLineScale(lastStrumTime: TimeInterval?, songTime: TimeInterval) -> Double {
        guard let lastStrumTime else { return 1 }
        let age = songTime - lastStrumTime
        return age >= 0 && age < swipePulseDuration ? 13.0 / 9.0 : 1
    }

    /// The colour wave spreading from the ring after a hit: (scale relative to the ring, opacity).
    /// Nil on a Miss and once the wave is over.
    static func wave(judgement: PlayJudgement?, songTime: TimeInterval) -> (scale: Double, opacity: Double)? {
        guard let judgement, judgement.feedback != .miss,
              let age = age(of: judgement, songTime: songTime), age < waveDuration else { return nil }
        return (1 + 1.75 * age, 1 - age / waveDuration)
    }
}
