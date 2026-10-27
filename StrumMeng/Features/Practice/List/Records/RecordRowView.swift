//
//  RecordRowView.swift
//  StrumMeng
//
//  Created by rasyel on 26/10/26.
//

import SwiftUI

/// One record: rank, accuracy, Perfect, Miss, BPM.
struct RecordRowView: View {
    let model: RecordRowModel

    private enum Layout {
        static let columnSpacing: CGFloat = 12
        /// Gap between Accuracy, Perfect and Miss.
        static let statSpacing: CGFloat = 8
        static let rankWidth: CGFloat = 60
        static let labelSpacing: CGFloat = -2
        static let rankSize: CGFloat = 30
        static let valueSize: CGFloat = 30
        static let accuracySize: CGFloat = 40
        static let labelSize: CGFloat = 17
        static let mutedOpacity: Double = 0.75
        /// Every number sits in a box of this height, so the 40 pt accuracy and the 30 pt
        /// counts share one baseline for their labels ("Accuracy" lines up with "Perfect").
        static let valueAreaHeight: CGFloat = 40
        /// Moves only the accuracy column to the left. It is a visual offset, so
        /// Perfect, Miss and BPM keep their positions.
        static let accuracyLeftShift: CGFloat = 12
        /// Pushes Perfect and Miss to the right; Accuracy stays where it is.
        static let perfectMissRightShift: CGFloat = 16
    }

    var body: some View {
        HStack(spacing: Layout.columnSpacing) {
            Text("#\(model.rank)")
                .font(AppTypography.dmMono(size: Layout.rankSize))
                .frame(width: Layout.rankWidth, alignment: .leading)

            // The three stat columns sit close together; the leftover space goes before BPM.
            HStack(spacing: Layout.statSpacing) {
                statColumn(
                    value: "\(model.accuracyPercent)%",
                    label: "Accuracy",
                    valueFont: AppTypography.bungee(size: Layout.accuracySize)
                )
                .offset(x: -Layout.accuracyLeftShift)
                statColumn(value: "\(model.perfectCount)", label: "Perfect")
                    .padding(.leading, Layout.perfectMissRightShift)
                statColumn(value: "\(model.missCount)", label: "Miss")
            }

            Spacer(minLength: 0)

            Text("BPM \(model.bpm)")
                .font(AppTypography.dmMono(size: Layout.valueSize))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(AppColors.brownInk)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Record \(model.rank): accuracy \(model.accuracyPercent) percent, "
            + "\(model.perfectCount) perfect, \(model.missCount) miss, BPM \(model.bpm)"
        )
    }

    private func statColumn(value: String, label: String, valueFont: Font? = nil) -> some View {
        VStack(spacing: Layout.labelSpacing) {
            Text(value)
                .font(valueFont ?? AppTypography.dmMono(size: Layout.valueSize))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: Layout.valueAreaHeight)
            Text(label)
                .font(AppTypography.dmMono(size: Layout.labelSize))
                .opacity(Layout.mutedOpacity)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
