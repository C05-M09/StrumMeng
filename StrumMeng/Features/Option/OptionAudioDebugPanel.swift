#if DEBUG
import SwiftUI

/// DEBUG ONLY. Two buttons under the Option card so you can hear the sliders working:
/// "Play sound" loops a soft chord at the Sound volume, "Play effect" plays a blip at the Sound Effects volume.
/// Move the Sound slider while the chord plays and the volume changes right away.
struct OptionAudioDebugPanel: View {
    let soundVolume: Double
    let sfxVolume: Double

    @State private var player = DummyAudioPlayer()

    var body: some View {
        VStack(spacing: 14) {
            Text("DEBUG: test audio")
                .font(AppTypography.dmMono(size: 22))
                .foregroundStyle(AppColors.cream)

            if let player {
                HStack(spacing: 20) {
                    debugButton(player.isMusicPlaying ? "Stop sound" : "Play sound") {
                        if player.isMusicPlaying {
                            player.stopMusic()
                        } else {
                            player.startMusic()
                        }
                    }
                    debugButton("Play effect") {
                        player.playEffect()
                    }
                }
                Text("Sound \(percent(soundVolume))   Effects \(percent(sfxVolume))")
                    .font(AppTypography.dmMono(size: 22))
                    .foregroundStyle(AppColors.cream)
            } else {
                Text("Audio could not start")
                    .font(AppTypography.dmMono(size: 22))
                    .foregroundStyle(AppColors.cream)
            }
        }
        .onAppear { applyVolumes() }
        .onChange(of: soundVolume) { _, newValue in player?.setSoundVolume(newValue) }
        .onChange(of: sfxVolume) { _, newValue in player?.setSFXVolume(newValue) }
        .onDisappear { player?.stopMusic() }
    }

    private func applyVolumes() {
        player?.setSoundVolume(soundVolume)
        player?.setSFXVolume(sfxVolume)
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func debugButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.dmMono(size: 26))
                .foregroundStyle(AppColors.brownInk)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppColors.cream, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
#endif
