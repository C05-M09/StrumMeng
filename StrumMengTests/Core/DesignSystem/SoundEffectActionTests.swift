import XCTest
@testable import StrumMeng

@MainActor
final class SoundEffectActionTests: XCTestCase {
    func test_action_playsTheEffectItIsCalledWith() {
        let sounds = MockMenuSoundService()
        let action = SoundEffectAction { sounds.play($0) }

        action(.wheelTick)
        action(.button)

        XCTAssertEqual(sounds.playedEffects, [.wheelTick, .button])
    }

    func test_containerAction_playsThroughTheMenuSounds() {
        let sounds = MockMenuSoundService()
        let container = AppContainer(router: AppRouter(), inMemory: true, menuSounds: sounds)

        container.soundEffectAction(.garage)

        XCTAssertEqual(sounds.playedEffects, [.garage])
    }
}
