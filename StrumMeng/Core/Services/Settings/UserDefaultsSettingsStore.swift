import Foundation
import Observation

/// `SettingsStore` backed by `UserDefaults`. Lighter than SwiftData for two numbers.
/// Defaults and clamping live in `VolumeConfig`, so there is no second copy of them here.
@MainActor
@Observable
final class UserDefaultsSettingsStore: SettingsStore {
    enum Key {
        static let soundVolume = "settings.soundVolume"
        static let sfxVolume = "settings.sfxVolume"
    }

    private(set) var soundVolume: Double
    private(set) var sfxVolume: Double

    @ObservationIgnored private let defaults: UserDefaults

    /// Pass a throwaway `UserDefaults(suiteName:)` in tests and previews.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.soundVolume = Self.loadVolume(forKey: Key.soundVolume, from: defaults)
        self.sfxVolume = Self.loadVolume(forKey: Key.sfxVolume, from: defaults)
    }

    func setSoundVolume(_ value: Double) {
        let volume = VolumeConfig.clamped(value)
        soundVolume = volume
        defaults.set(volume, forKey: Key.soundVolume)
    }

    func setSFXVolume(_ value: Double) {
        let volume = VolumeConfig.clamped(value)
        sfxVolume = volume
        defaults.set(volume, forKey: Key.sfxVolume)
    }

    /// Nothing saved yet gives the default. A saved value outside the range is clamped.
    private static func loadVolume(forKey key: String, from defaults: UserDefaults) -> Double {
        guard defaults.object(forKey: key) != nil else { return VolumeConfig.defaultVolume }
        return VolumeConfig.clamped(defaults.double(forKey: key))
    }
}
