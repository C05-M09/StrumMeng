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
        let store = UserDefaultsSettingsStore(defaults: defaults)
        let viewModel = OptionViewModel(settings: store, onBackRequested: onBackRequested)
        return (viewModel, store)
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
