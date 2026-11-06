import Foundation
import Observation

@MainActor
@Observable
final class OptionViewModel {
    private(set) var state: OptionState

    private let settings: any SettingsStore
    private let sounds: any MenuSoundService
    private let onBackRequested: () -> Void
    private let onSetUpDeviceRequested: () -> Void

    init(
        settings: any SettingsStore,
        sounds: any MenuSoundService,
        onBackRequested: @escaping () -> Void,
        onSetUpDeviceRequested: @escaping () -> Void = {}
    ) {
        self.settings = settings
        self.sounds = sounds
        self.onBackRequested = onBackRequested
        self.onSetUpDeviceRequested = onSetUpDeviceRequested
        self.state = OptionState(
            soundVolume: settings.soundVolume,
            sfxVolume: settings.sfxVolume
        )
    }

    /// Every slider change is saved at once and sent to the menu sounds, so the new volume is heard
    /// while dragging and survives closing the app. Music = `soundVolume`, Sound Effects = `sfxVolume`.
    func send(_ event: OptionEvent) {
        state = reduce(state, event)

        switch event {
        case .changeSoundVolume:
            settings.setSoundVolume(state.soundVolume)
            sounds.setMusicVolume(state.soundVolume)

        case .changeSFXVolume:
            settings.setSFXVolume(state.sfxVolume)
            sounds.setEffectsVolume(state.sfxVolume)

        case .tapSetUpDevice:
            sounds.playButtonSound()
            onSetUpDeviceRequested()

        case .tapBack:
            // No click here: closing the overlay plays it (HomeViewModel's dismissOverlay).
            onBackRequested()
        }
    }
}
