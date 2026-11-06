import Foundation
@testable import StrumMeng

/// Records what would have been played, instead of making sound.
final class MockMenuSoundService: MenuSoundService {
    private(set) var startMusicCount = 0
    private(set) var pauseMusicCount = 0
    private(set) var buttonSoundCount = 0
    private(set) var musicVolumes: [Double] = []
    private(set) var effectsVolumes: [Double] = []

    func startMusic() { startMusicCount += 1 }
    func pauseMusic() { pauseMusicCount += 1 }
    func playButtonSound() { buttonSoundCount += 1 }
    func setMusicVolume(_ volume: Double) { musicVolumes.append(volume) }
    func setEffectsVolume(_ volume: Double) { effectsVolumes.append(volume) }
}
