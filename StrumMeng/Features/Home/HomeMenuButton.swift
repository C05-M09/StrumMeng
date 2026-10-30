//
//  HomeMenuButton.swift
//  StrumMeng
//
//  Created by rasyel on 29/10/26.
//

import SwiftUI

/// A button drawn from one artwork. By default it sinks a little while pressed.
/// With `pressedAssetName` it swaps to a second artwork while pressed instead.
/// Only the height is fixed: the width follows the artwork's proportions.
struct HomeMenuButton: View {
    let assetName: String
    var pressedAssetName: String? = nil
    let title: String
    let height: CGFloat
    var hint: String = ""
    let action: () -> Void

    var body: some View {
        button
            .accessibilityLabel(title)
            .accessibilityHint(hint)
    }

    @ViewBuilder
    private var button: some View {
        if let pressedAssetName {
            Button(action: action) {
                artwork(assetName)
            }
            .buttonStyle(
                ArtworkSwapButtonStyle(
                    normalAsset: assetName,
                    pressedAsset: pressedAssetName,
                    height: height
                )
            )
        } else {
            Button(action: action) {
                artwork(assetName)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private func artwork(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
}

/// Shows `normalAsset`, and `pressedAsset` for as long as the finger is down.
/// The swap is instant: no fade between the two artworks.
private struct ArtworkSwapButtonStyle: ButtonStyle {
    let normalAsset: String
    let pressedAsset: String
    let height: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        // Both artworks stay in the view tree and only their visibility flips.
        // This also avoids a first-press flicker from loading the pressed image late.
        ZStack {
            artwork(normalAsset)
                .opacity(configuration.isPressed ? 0 : 1)
            artwork(pressedAsset)
                .opacity(configuration.isPressed ? 1 : 0)
        }
        .transaction { $0.animation = nil }   // no implicit animation on press / release
    }

    private func artwork(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
}
