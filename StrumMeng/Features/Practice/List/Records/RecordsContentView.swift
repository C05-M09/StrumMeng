//
//  RecordsContentView.swift
//  StrumMeng
//
//  Created by rasyel on 26/10/26.
//

import SwiftUI

/// Pure rendering of a `RecordsViewState`, drawn inside the rounded outline frame.
/// No view model, so every state can have its own #Preview.
struct RecordsContentView: View {
    let state: RecordsViewState

    private enum Layout {
        static let rowHeight: CGFloat = 95
        static let visibleRows: CGFloat = 3
        /// The design lets a piece of the 4th row peek out to hint that the list scrolls.
        /// Set to 0 for exactly 3 rows.
        static let peek: CGFloat = 48
        /// Soft fade at the inner top and bottom edges so rows do not get cut off sharply.
        static let fadeTop: CGFloat = 16
        static let fadeBottom: CGFloat = Layout.peek
        /// Space between the row content and the scroll indicator.
        static let scrollTrailingInset: CGFloat = 28
        static let headerSpacing: CGFloat = 4
        static let dividerHeight: CGFloat = 1
        static let sectionTitleSize: CGFloat = 30
        static let bodySize: CGFloat = 17
        static let mutedOpacity: Double = 0.75

        static let frameImageName = "Practice_Record_Frame"
        /// Size of the corner area (in the image's own points) that must not be stretched.
        /// Tune it to the corner radius plus line width of the asset.
        static let frameCapInset: CGFloat = 40
        static let frameHorizontalPadding: CGFloat = 20
        static let frameVerticalPadding: CGFloat = 24
        /// The frame never grows wider than this, even if the card slot is wider.
        static let frameMaxWidth: CGFloat = 555
    }

    private var listHeight: CGFloat { Layout.rowHeight * Layout.visibleRows }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            Text("RECORDS:")
                .font(AppTypography.bungee(size: Layout.sectionTitleSize))
                .foregroundStyle(AppColors.brownInk)

            switch state {
            case .loading:
                ProgressView()
                    .tint(AppColors.brownInk)
                    .frame(maxWidth: .infinity, minHeight: listHeight)
            case .empty:
                message("No records history yet")
            case .failed:
                message("Records couldn't be loaded")
            case .loaded(let rows):
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(rows) { row in
                            RecordRowView(model: row)
                                .frame(height: Layout.rowHeight)
                            Rectangle()
                                .fill(AppColors.recordOutline)
                                .frame(height: Layout.dividerHeight)
                        }
                    }
                    // Keeps the content away from the scroll indicator on the right,
                    // and leaves room so the first/last row rest outside the fades.
                    .padding(.trailing, Layout.scrollTrailingInset)
                    .padding(.top, Layout.fadeTop)
                    .padding(.bottom, Layout.fadeBottom)
                }
                .scrollIndicators(.visible)
                .frame(height: Layout.fadeTop + listHeight + Layout.fadeBottom)
                .mask(edgeFadeMask)
            }
        }
        .padding(.horizontal, Layout.frameHorizontalPadding)
        .padding(.vertical, Layout.frameVerticalPadding)
        .background {
            // The outline comes from the asset catalog. The corners (capInsets) keep their
            // shape and only the straight edges stretch to the size of the content.
            Image(Layout.frameImageName)
                .resizable(
                    capInsets: EdgeInsets(
                        top: Layout.frameCapInset,
                        leading: Layout.frameCapInset,
                        bottom: Layout.frameCapInset,
                        trailing: Layout.frameCapInset
                    ),
                    resizingMode: .stretch
                )
        }
        .frame(maxWidth: Layout.frameMaxWidth)
    }

    /// Alpha mask only (the colours are never drawn): opaque in the middle, fading to
    /// transparent at the top and bottom edges.
    private var edgeFadeMask: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: Layout.fadeTop)
            Rectangle()
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: Layout.fadeBottom)
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.dmMono(size: Layout.bodySize))
            .foregroundStyle(AppColors.brownInk.opacity(Layout.mutedOpacity))
            .frame(maxWidth: .infinity, minHeight: listHeight)
    }
}

#if DEBUG
/// Sample rows that mirror the Figma reference, for previews only.
private extension RecordRowModel {
    static let previewSamples: [RecordRowModel] = [
        (90, 80, 1, 0, 4),
        (80, 70, 1, 1, 5),
        (70, 80, 1, 0, 6),
        (70, 90, 13, 1, 6),
        (60, 60, 8, 2, 7)
    ].enumerated().map { index, sample in
        RecordRowModel(
            rank: index + 1,
            result: SessionResult(
                id: UUID(),
                patternID: "upbeat",
                songID: nil,
                bpm: sample.1,
                accuracy: Double(sample.0) / 100,
                perfectCount: sample.2,
                tooEarlyCount: sample.3,
                missCount: sample.4,
                createdAt: .now,
                beatEvents: []
            )
        )
    }
}

/// Preview only: just the rounded rectangle, filled with cream inside its own shape.
private struct RecordsPreviewCanvas<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .background(AppColors.cream, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

#Preview("Loaded, scrollable") {
    RecordsPreviewCanvas { RecordsContentView(state: .loaded(RecordRowModel.previewSamples)) }
}
#Preview("Empty") { RecordsPreviewCanvas { RecordsContentView(state: .empty) } }
#Preview("Loading") { RecordsPreviewCanvas { RecordsContentView(state: .loading) } }
#Preview("Failed") { RecordsPreviewCanvas { RecordsContentView(state: .failed) } }
#endif
