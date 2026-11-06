import XCTest
@testable import StrumMeng

@MainActor
final class AVMenuSoundServiceTests: XCTestCase {
    private let missingFiles = AVMenuSoundService.Files(
        musicName: "NoSuchMusic",
        musicExtension: "mp3",
        buttonName: "NoSuchButton",
        buttonExtension: "wav"
    )

    func test_init_withBundledFiles_loadsMusicAndButtonSound() {
        let service = AVMenuSoundService()

        XCTAssertTrue(service.hasMusic)
        XCTAssertTrue(service.hasButtonSound)
    }

    func test_init_startsWithTheDefaultVolumes() {
        let service = AVMenuSoundService()

        XCTAssertEqual(service.musicVolume, VolumeConfig.defaultVolume)
        XCTAssertEqual(service.effectsVolume, VolumeConfig.defaultVolume)
    }

    func test_missingFiles_leaveTheServiceSilentWithoutCrashing() {
        let service = AVMenuSoundService(files: missingFiles)

        service.startMusic()
        service.playButtonSound()
        service.pauseMusic()

        XCTAssertFalse(service.hasMusic)
        XCTAssertFalse(service.hasButtonSound)
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
