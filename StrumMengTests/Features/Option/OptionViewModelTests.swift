import XCTest
@testable import StrumMeng

@MainActor
final class OptionViewModelTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "option-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeViewModel(
        onBackRequested: @escaping () -> Void = {}
    ) -> (OptionViewModel, UserDefaultsSettingsStore) {
        let (viewModel, store, _) = makeViewModelWithSounds(onBackRequested: onBackRequested)
        return (viewModel, store)
    }

    private func makeViewModelWithSounds(
        onBackRequested: @escaping () -> Void = {}
    ) -> (OptionViewModel, UserDefaultsSettingsStore, MockMenuSoundService) {
        let store = UserDefaultsSettingsStore(defaults: defaults)
        let sounds = MockMenuSoundService()
        let viewModel = OptionViewModel(settings: store, sounds: sounds, onBackRequested: onBackRequested)
        return (viewModel, store, sounds)
    }

    func test_init_showsTheSavedVolumes() {
        let saved = UserDefaultsSettingsStore(defaults: defaults)
        saved.setSoundVolume(0.3)
        saved.setSFXVolume(0.7)

        let (viewModel, _) = makeViewModel()

        XCTAssertEqual(viewModel.state, OptionState(soundVolume: 0.3, sfxVolume: 0.7))
    }

    func test_changeSoundVolume_savesToTheStoreRightAway() {
        let (viewModel, store) = makeViewModel()

        viewModel.send(.changeSoundVolume(0.9))

        XCTAssertEqual(viewModel.state.soundVolume, 0.9)
        XCTAssertEqual(store.soundVolume, 0.9)
        XCTAssertEqual(store.sfxVolume, VolumeConfig.defaultVolume)
    }

    func test_changeSFXVolume_savesToTheStoreRightAway() {
        let (viewModel, store) = makeViewModel()

        viewModel.send(.changeSFXVolume(0.2))

        XCTAssertEqual(viewModel.state.sfxVolume, 0.2)
        XCTAssertEqual(store.sfxVolume, 0.2)
        XCTAssertEqual(store.soundVolume, VolumeConfig.defaultVolume)
    }

    func test_changeVolume_outOfRange_isClampedBeforeSaving() {
        let (viewModel, store) = makeViewModel()

        viewModel.send(.changeSoundVolume(3))

        XCTAssertEqual(viewModel.state.soundVolume, 1)
        XCTAssertEqual(store.soundVolume, 1)
    }

    func test_changes_surviveReopeningTheScreen() {
        let (first, _) = makeViewModel()
        first.send(.changeSoundVolume(0.1))
        first.send(.changeSFXVolume(0.6))

        let (second, _) = makeViewModel()

        XCTAssertEqual(second.state, OptionState(soundVolume: 0.1, sfxVolume: 0.6))
    }

    func test_changeSoundVolume_setsTheMusicVolumeRightAway() {
        let (viewModel, _, sounds) = makeViewModelWithSounds()

        viewModel.send(.changeSoundVolume(0.4))

        XCTAssertEqual(sounds.musicVolumes, [0.4])
        XCTAssertEqual(sounds.effectsVolumes, [])
    }

    func test_changeSFXVolume_setsTheEffectsVolumeRightAway() {
        let (viewModel, _, sounds) = makeViewModelWithSounds()

        viewModel.send(.changeSFXVolume(0.8))

        XCTAssertEqual(sounds.effectsVolumes, [0.8])
        XCTAssertEqual(sounds.musicVolumes, [])
    }

    func test_changeVolume_outOfRange_sendsTheClampedVolume() {
        let (viewModel, _, sounds) = makeViewModelWithSounds()

        viewModel.send(.changeSoundVolume(-1))
        viewModel.send(.changeSFXVolume(5))

        XCTAssertEqual(sounds.musicVolumes, [0])
        XCTAssertEqual(sounds.effectsVolumes, [1])
    }

    func test_events_playNoSound_theButtonsClickThemselves() {
        let (viewModel, _, sounds) = makeViewModelWithSounds()

        viewModel.send(.tapSetUpDevice)
        viewModel.send(.changeSoundVolume(0.3))
        viewModel.send(.changeSFXVolume(0.3))
        viewModel.send(.tapBack)

        XCTAssertEqual(sounds.playedEffects, [])
    }

    func test_tapBack_doesNotChangeAnyVolume() {
        let (viewModel, _, sounds) = makeViewModelWithSounds()

        viewModel.send(.tapBack)

        XCTAssertEqual(sounds.musicVolumes, [])
        XCTAssertEqual(sounds.effectsVolumes, [])
    }

    func test_tapSetUpDevice_requestsTheSetupScreen_andKeepsTheVolumes() {
        let store = UserDefaultsSettingsStore(defaults: defaults)
        var didRequestSetup = false
        let viewModel = OptionViewModel(
            settings: store,
            sounds: MockMenuSoundService(),
            onBackRequested: {},
            onSetUpDeviceRequested: { didRequestSetup = true }
        )
        let before = viewModel.state

        viewModel.send(.tapSetUpDevice)

        XCTAssertTrue(didRequestSetup)
        XCTAssertEqual(viewModel.state, before)
    }

    func test_tapBack_requestsRouterPop() {
        var didRequestBack = false
        let (viewModel, _) = makeViewModel(onBackRequested: { didRequestBack = true })

        viewModel.send(.tapBack)

        XCTAssertTrue(didRequestBack)
    }

    func test_tapBack_doesNotChangeAnySetting() {
        let (viewModel, store) = makeViewModel()

        viewModel.send(.tapBack)

        XCTAssertEqual(store.soundVolume, VolumeConfig.defaultVolume)
        XCTAssertEqual(store.sfxVolume, VolumeConfig.defaultVolume)
    }
}
