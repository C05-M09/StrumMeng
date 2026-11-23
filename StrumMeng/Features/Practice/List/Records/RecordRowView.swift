//
//  RecordRowView.swift
//  StrumMeng
//
//  Created by rasyel on 26/10/26.
//

import SwiftUI

/// One record: rank, accuracy, Perfect, Miss, BPM, and arrow navigating to summary.
struct RecordRowView: View {
    let model: RecordRowModel

    private enum Layout {
        static let leadingPadding: CGFloat = 8  // Space before #1 (indents from left edge of divider)
        static let trailingPadding: CGFloat = 8 // Space after '>' (indents from right edge of divider)
        static let rankWidth: CGFloat = 42 // Width of the rank column (#1, #2, etc.)
        static let rankToStatsSpacing: CGFloat = 12 // Gap between '#1' and the Accuracy column
        static let accuracyWidth: CGFloat = 92 // Fixed width for Accuracy column
        static let perfectWidth: CGFloat = 68 // Fixed width for Perfect column
        static let missWidth: CGFloat = 52 // Fixed width for Miss column
        static let minColumnSpacing: CGFloat = 16 // Minimum gap between columns
        static let labelSpacing: CGFloat = -2 // Vertical spacing between number and label
        static let rankSize: CGFloat = 28 // Font size of '#1'
        static let valueSize: CGFloat = 28 // Font size of counts (1, 4) and 'BPM 80'
        static let accuracySize: CGFloat = 38 // Font size of '90%'
        static let labelSize: CGFloat = 16 // Font size of 'Accuracy', 'Perfect', 'Miss'
        static let mutedOpacity: Double = 0.75 // Transparency of the labels
        static let valueAreaHeight: CGFloat = 38 // Height box ensuring numbers share a baseline
        static let arrowSize: CGFloat = 24 // Size of the '>' chevron
        static let arrowSpacing: CGFloat = 8 // Gap between 'BPM 80' and '>'
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("#\(model.rank)")
                .font(AppTypography.dmMono(size: Layout.rankSize))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: Layout.rankWidth, alignment: .leading)

            Spacer().frame(width: Layout.rankToStatsSpacing)

            statColumn(
                value: "\(model.accuracyPercent)%",
                label: "Accuracy",
                valueFont: AppTypography.bungee(size: Layout.accuracySize),
                width: Layout.accuracyWidth
            )

            Spacer(minLength: Layout.minColumnSpacing)

            statColumn(
                value: "\(model.perfectCount)",
                label: "Perfect",
                width: Layout.perfectWidth
            )

            Spacer(minLength: Layout.minColumnSpacing)

            statColumn(
                value: "\(model.missCount)",
                label: "Miss",
                width: Layout.missWidth
            )

            Spacer(minLength: Layout.minColumnSpacing)

            HStack(spacing: Layout.arrowSpacing) {
                Text("BPM \(model.bpm)")
                    .font(AppTypography.dmMono(size: Layout.valueSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.right")
                    .font(.system(size: Layout.arrowSize, weight: .medium))
                    .foregroundStyle(AppColors.recordOutline)
            }
        }
        .padding(.leading, Layout.leadingPadding)
        .padding(.trailing, Layout.trailingPadding)
        .foregroundStyle(AppColors.brownInk)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Record \(model.rank): accuracy \(model.accuracyPercent) percent, "
            + "\(model.perfectCount) perfect, \(model.missCount) miss, BPM \(model.bpm)"
        )
        .accessibilityHint("Shows summary of this record")
    }

    private func statColumn(
        value: String,
        label: String,
        valueFont: Font? = nil,
        width: CGFloat? = nil
    ) -> some View {
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
        .frame(width: width)
    }
}


#Preview("Single Row", traits: .fixedLayout(width: 520, height: 110)) {
    RecordRowView(
        model: RecordRowModel(
            rank: 1,
            result: SessionResult(
                id: UUID(),
                patternID: "foundation",
                songID: nil,
                bpm: 80,
                accuracy: 0.90,
                perfectCount: 1,
                tooEarlyCount: 0,
                missCount: 4,
                createdAt: .now,
                beatEvents: []
            )
        )
    )
    .frame(height: 95)
    .background(AppColors.cream)
}

#Preview("Rows in List", traits: .fixedLayout(width: 555, height: 320)) {
    VStack(spacing: 0) {
        ForEach([
            (rank: 1, acc: 1.00, bpm: 80, perf: 40, miss: 0),
            (rank: 2, acc: 0.54, bpm: 80, perf: 22, miss: 18),
            (rank: 3, acc: 0.08, bpm: 80, perf: 3, miss: 37)
        ], id: \.rank) { item in
            RecordRowView(
                model: RecordRowModel(
                    rank: item.rank,
                    result: SessionResult(
                        id: UUID(),
                        patternID: "foundation",
                        songID: nil,
                        bpm: item.bpm,
                        accuracy: item.acc,
                        perfectCount: item.perf,
                        tooEarlyCount: 0,
                        missCount: item.miss,
                        createdAt: .now,
                        beatEvents: []
                    )
                )
            )
            .frame(height: 95)

            Rectangle()
                .fill(AppColors.recordOutline)
                .frame(height: 1)
        }
    }
    .padding(.horizontal, 20)
    .background(AppColors.cream)
}
