//
//  HomeLayout.swift
//  StrumMeng
//
//  Created by rasyel on 29/10/26.
//

import SwiftUI

/// Positions and sizes on the Home screen, in `AppLayout.referenceSize` (1376 x 1032),
/// the same size as the `Cover` artwork. Measured from the cover sketch.
enum HomeLayout {
    /// One menu button: its artwork, its height and where its center sits.
    /// The width follows the artwork's own proportions.
    struct MenuButton {
        let asset: String
        let height: CGFloat
        let center: CGPoint
    }

    // Tinggi dan posisi diukur dari cover_sketch.png. Ketiganya berbeda ukuran.
    static let practice = MenuButton(
        asset: "Button_Practice",
        height: 190,
        center: CGPoint(x: 970, y: 566)
    )
    static let showtime = MenuButton(
        asset: "Button_Showtime",
        height: 155,
        center: CGPoint(x: 966, y: 710)
    )
    static let option = MenuButton(
        asset: "Button_Option",
        height: 100,
        center: CGPoint(x: 974, y: 857)
    )
    

    /// The Guidebook icon in the top-right corner.
    static let guidebookSize = CGSize(width: 125, height: 125)
    static let guidebookCenter = CGPoint(x: 1263, y: 115)

    static let coverAsset = "Cover"
    static let guidebookAsset = "Button_Guidebook_Normal"
    static let guidebookPressedAsset = "Button_Guidebook_Pressed"
}

