import Foundation

/// Stands in when the audio engine could not be made, so Listen and Play still work, silently.
final class SilentGuitarSound: GuitarSound, MetronomeSound {
    func prepare() async {}
    func strum(_ direction: StrumDirection, at time: TimeInterval?, accent: Double) {}
    func stopStrums() {}
    func click(at time: TimeInterval, accent: Bool) {}
    func cancelClicks() {}
}
