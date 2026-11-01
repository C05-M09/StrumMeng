import Foundation
import Observation

@MainActor
@Observable
final class OptionViewModel {
    private(set) var state: OptionState

    private let settings: any SettingsStore
    private let onBackRequested: () -> Void
    private let onSetUpDeviceRequested: () -> Void

    init(
        settings: any SettingsStore,
        onBackRequested: @escaping () -> Void,
        onSetUpDeviceRequested: @escaping () -> Void = {}
    ) {
        self.settings = settings
        self.onBackRequested = onBackRequested
        self.onSetUpDeviceRequested = onSetUpDeviceRequested
        self.state = OptionState(
            soundVolume: settings.soundVolume,
            sfxVolume: settings.sfxVolume
        )
    }

    /// Every slider change is saved at once, so the new volume applies right away
    /// (including while a session is playing) and survives closing the app.
    func send(_ event: OptionEvent) {
        state = reduce(state, event)

        switch event {
        case .changeSoundVolume:
            settings.setSoundVolume(state.soundVolume)

        case .changeSFXVolume:
            settings.setSFXVolume(state.sfxVolume)

        case .tapSetUpDevice:
            onSetUpDeviceRequested()

        case .tapBack:
            onBackRequested()
        }
    }
}
