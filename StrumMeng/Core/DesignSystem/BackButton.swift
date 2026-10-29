//
//  BackButton.swift
//  StrumMeng
//
//  Created by rasyel on 29/10/26.
//


import SwiftUI

/// The one Back button for every screen, so it looks and behaves the same everywhere.
/// Place it with `.position(BackButton.referenceCenter)` on screens laid out in `AppLayout.referenceSize`.
struct BackButton: View {
    static let size = CGSize(width: 88.46, height: 95.85)
    /// Top-left corner of the reference space, where the design puts Back.
    static let referenceCenter = CGPoint(x: 109, y: 103)

    let action: () -> Void

    var body: some View {
        AssetPressButton(
            normalAsset: "Button_Back_Normal",
            pressedAsset: "Button_Back_Pressed",
            size: Self.size,
            accessibilityLabel: "Back",
            action: action
        )
    }
}

#Preview {
    BackButton {}
        .padding(AppSpacing.xl)
        .background(AppColors.brownPrimary)
}
