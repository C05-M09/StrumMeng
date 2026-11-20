#if DEBUG
import SwiftUI

// Playable previews of the real game loop: the real AudioBeatClock and swipe input, no sound yet.
// Tap READY?, wait for 3-2-1, then swipe up/down anywhere in time with the nodes.
// They live in App because only the composition layer may build concrete services.

private func makeSessionViewModel(patternID: String, bpm: Int) -> PlayViewModel? {
    guard let pattern = PatternCatalog.all.first(where: { $0.id == patternID }) else { return nil }
    let input = TouchStrumInputService()
    return PlayViewModel(
        pattern: pattern, bpm: bpm, clock: AudioBeatClock(), input: input, touchInput: input,
        now: HostClock.now,
        waitUntil: { time in
            let delay = time - HostClock.now()
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
        })
}

#Preview("Play session - Subdivision 80", traits: .landscapeLeft) {
    if let viewModel = makeSessionViewModel(patternID: "subdivision", bpm: 80) {
        PracticePlaySessionView(viewModel: viewModel)
    }
}

#Preview("Play session - Syncopation 60", traits: .landscapeLeft) {
    if let viewModel = makeSessionViewModel(patternID: "syncopation", bpm: 60) {
        PracticePlaySessionView(viewModel: viewModel)
    }
}
#endif
