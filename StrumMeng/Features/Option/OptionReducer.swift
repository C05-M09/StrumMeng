import Foundation

func reduce(_ state: OptionState, _ event: OptionEvent) -> OptionState {
    switch event {
    case let .changeSoundVolume(volume):
        return OptionState(
            soundVolume: VolumeConfig.clamped(volume),
            sfxVolume: state.sfxVolume
        )

    case let .changeSFXVolume(volume):
        return OptionState(
            soundVolume: state.soundVolume,
            sfxVolume: VolumeConfig.clamped(volume)
        )

    case .tapBack:
        return state
    }
}
