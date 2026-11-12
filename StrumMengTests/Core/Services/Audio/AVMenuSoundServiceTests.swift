import XCTest
@testable import StrumMeng

@MainActor
final class AVMenuSoundServiceTests: XCTestCase {
    private let missingFiles = AVMenuSoundService.Files(
        musicName: "NoSuchMusic",
        musicExtension: "mp3",
        effects: Dictionary(uniqueKeysWithValues: SoundEffect.allCases.map { ($0, "NoSuchEffect") }),
        effectsExtension: "mp3"
    )

    func test_init_withBundledFiles_loadsTheMusicAndEverySoundEffect() {
        let service = AVMenuSoundService()

        XCTAssertTrue(service.hasMusic)
        for effect in SoundEffect.allCases {
            XCTAssertTrue(service.hasSound(for: effect), "\(effect) has no bundled sound")
        }
    }

    func test_controllerFiles_loadOnlyTheButtonClick_andNoMusic() {
        let service = AVMenuSoundService(files: .controller)

        XCTAssertFalse(service.hasMusic)
        XCTAssertTrue(service.hasSound(for: .button))
        XCTAssertFalse(service.hasSound(for: .wheelTick))
    }

    func test_bundledFiles_nameASoundForEveryEffect() {
        XCTAssertEqual(Set(AVMenuSoundService.Files.bundled.effects.keys), Set(SoundEffect.allCases))
    }

    func test_wheelTick_hasEnoughVoicesToOverlapAFastSpin() {
        XCTAssertGreaterThan(AVMenuSoundService.voiceCount(for: .wheelTick), 1)
        for effect in SoundEffect.allCases {
            XCTAssertGreaterThanOrEqual(AVMenuSoundService.voiceCount(for: effect), 1)
        }
    }

    func test_playingEveryEffect_repeatedly_doesNotCrash() {
        let service = AVMenuSoundService()
        service.setEffectsVolume(0)  // keep the test run quiet; a muted effect is skipped
        service.setEffectsVolume(0.01)

        for _ in 0..<6 {
            SoundEffect.allCases.forEach(service.play)
        }
    }

    func test_init_startsWithTheDefaultVolumes() {
        let service = AVMenuSoundService()

        XCTAssertEqual(service.musicVolume, VolumeConfig.defaultVolume)
        XCTAssertEqual(service.effectsVolume, VolumeConfig.defaultVolume)
    }

    func test_missingFiles_leaveTheServiceSilentWithoutCrashing() {
        let service = AVMenuSoundService(files: missingFiles)

        service.startMusic()
        SoundEffect.allCases.forEach(service.play)
        service.pauseMusic()

        XCTAssertFalse(service.hasMusic)
        for effect in SoundEffect.allCases {
            XCTAssertFalse(service.hasSound(for: effect))
        }
        XCTAssertFalse(service.isMusicPlaying)
    }

    func test_startMusic_thenPauseMusic_stopsTheMusic() {
        let service = AVMenuSoundService()
        service.setMusicVolume(0)  // keep the test run quiet

        service.startMusic()
        XCTAssertTrue(service.isMusicPlaying)

        service.pauseMusic()
        XCTAssertFalse(service.isMusicPlaying)
    }

    func test_startMusic_whilePlaying_keepsPlaying() {
        let service = AVMenuSoundService()
        service.setMusicVolume(0)

        service.startMusic()
        service.startMusic()

        XCTAssertTrue(service.isMusicPlaying)
        service.pauseMusic()
    }

    func test_setMusicVolume_clampsToZeroToOne() {
        let service = AVMenuSoundService()

        service.setMusicVolume(1.5)
        XCTAssertEqual(service.musicVolume, 1)

        service.setMusicVolume(-0.2)
        XCTAssertEqual(service.musicVolume, 0)

        service.setMusicVolume(0.3)
        XCTAssertEqual(service.musicVolume, 0.3)
    }

    func test_setEffectsVolume_clampsToZeroToOne() {
        let service = AVMenuSoundService()

        service.setEffectsVolume(2)
        XCTAssertEqual(service.effectsVolume, 1)

        service.setEffectsVolume(-1)
        XCTAssertEqual(service.effectsVolume, 0)

        service.setEffectsVolume(0.7)
        XCTAssertEqual(service.effectsVolume, 0.7)
    }
}
