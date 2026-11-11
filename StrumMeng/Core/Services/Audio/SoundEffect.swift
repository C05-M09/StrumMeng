import Foundation

/// The short UI sounds the iPad plays. All of them follow the SFX volume in Option.
nonisolated enum SoundEffect: CaseIterable, Sendable {
    /// Every button, on press.
    case button
    /// The garage shutter closing after a session and opening on Summary.
    case garage
    /// A Guidebook card shuffling to the next or previous page.
    case guidebookPage
    /// A celebration pop-up appearing: the end-of-session banner, Listen's information,
    /// the BPM recommendation and the Replay ready card.
    case popUp
    /// The practice wheel passing one pattern, once per pattern, like a ratchet.
    case wheelTick
}
