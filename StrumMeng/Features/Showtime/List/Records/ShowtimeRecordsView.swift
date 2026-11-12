import SwiftUI

/// Records of one song. `.task` loads again every time the card opens, and is cancelled when it
/// closes.
struct ShowtimeRecordsView: View {
    let viewModel: ShowtimeRecordsViewModel

    var body: some View {
        ShowtimeRecordsContentView(state: viewModel.state)
            .task { await viewModel.load() }
    }
}

/// Pure rendering of a `ShowtimeRecordsViewState` on the `Showtime_Record box` card.
///
/// The asset is a finished card (rounded border, its own "RECORDS:" heading, red base), so it is
/// drawn at its own proportions and never stretched. The rows are placed inside it by fractions of
/// the card, so they stay inside the card whatever its size. Same rules as Practice: 3 rows
/// visible, a piece of the 4th peeks out, the rest scrolls, same empty text. Rows show stars
/// instead of BPM.
struct ShowtimeRecordsContentView: View {
    let state: ShowtimeRecordsViewState

    private enum Layout {
        static let cardWidth: CGFloat = 584

        // Where the rows may go, as a fraction of the card. Tune these three to the asset:
        /// Space above the rows: the heading that is drawn in the asset.
        static let topInset: CGFloat = 0.24
        /// Space below the rows: the red base of the card.
        static let bottomInset: CGFloat = 0.10
        static let horizontalInset: CGFloat = 0.06

        static let visibleRows: CGFloat = 3
        /// How much of the 4th row peeks out, as a fraction of one row.
        static let peekRows: CGFloat = 0.45
        static let fadeTop: CGFloat = 14
        static let scrollTrailingInset: CGFloat = 20
        static let dividerHeight: CGFloat = 1
        static let bodySize: CGFloat = 17
        static let mutedOpacity: Double = 0.75
    }

    var body: some View {
        Image(ShowtimeAssets.recordBox)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Layout.cardWidth)
            .overlay {
                GeometryReader { proxy in
                    content(in: proxy.size)
                }
            }
    }

    private func content(in card: CGSize) -> some View {
        let top = card.height * Layout.topInset
        let bottom = card.height * Layout.bottomInset
        let side = card.width * Layout.horizontalInset
        let listHeight = card.height - top - bottom
        // 3 full rows + the peeking part of the 4th + the top fade fill the list exactly.
        let rowHeight = (listHeight - Layout.fadeTop) / (Layout.visibleRows + Layout.peekRows)

        return list(listHeight: listHeight, rowHeight: rowHeight)
            .frame(width: card.width - side * 2, height: listHeight)
            .padding(.leading, side)
            .padding(.top, top)
            .frame(width: card.width, height: card.height, alignment: .topLeading)
    }

    @ViewBuilder
    private func list(listHeight: CGFloat, rowHeight: CGFloat) -> some View {
        switch state {
        case .loading:
            ProgressView()
                .tint(AppColors.brownInk)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            // Same text as Practice.
            message("No records history yet")
        case .failed:
            message("Records couldn't be loaded")
        case .loaded(let rows):
            let fadeBottom = rowHeight * Layout.peekRows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(rows) { row in
                        ShowtimeRecordRowView(model: row)
                            .frame(height: rowHeight)
                        Rectangle()
                            .fill(AppColors.recordOutline)
                            .frame(height: Layout.dividerHeight)
                    }
                }
                .padding(.trailing, Layout.scrollTrailingInset)
                .padding(.top, Layout.fadeTop)
                .padding(.bottom, fadeBottom)
            }
            .scrollIndicators(.visible)
            .frame(height: listHeight)
            .mask(edgeFadeMask(bottom: fadeBottom))
        }
    }

    /// Alpha mask only: opaque in the middle, fading out at the top and at the peeking row.
    private func edgeFadeMask(bottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: Layout.fadeTop)
            Rectangle()
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: bottom)
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.dmMono(size: Layout.bodySize))
            .foregroundStyle(AppColors.brownInk.opacity(Layout.mutedOpacity))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// One Showtime record: rank, accuracy, Perfect, Miss and the stars it earned.
struct ShowtimeRecordRowView: View {
    let model: ShowtimeRecordRowModel

    private enum Layout {
        static let columnSpacing: CGFloat = 10
        static let statSpacing: CGFloat = 12
        static let rankWidth: CGFloat = 52
        static let labelSpacing: CGFloat = -2
        static let rankSize: CGFloat = 28
        static let valueSize: CGFloat = 28
        static let accuracySize: CGFloat = 36
        static let labelSize: CGFloat = 15
        static let mutedOpacity: Double = 0.75
        static let valueAreaHeight: CGFloat = 36
        static let starsHeight: CGFloat = 32
    }

    var body: some View {
        HStack(spacing: Layout.columnSpacing) {
            Text("#\(model.rank)")
                .font(AppTypography.dmMono(size: Layout.rankSize))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: Layout.rankWidth, alignment: .leading)

            HStack(spacing: Layout.statSpacing) {
                statColumn(
                    value: "\(model.accuracyPercent)%",
                    label: "Accuracy",
                    valueFont: AppTypography.bungee(size: Layout.accuracySize)
                )
                statColumn(value: "\(model.perfectCount)", label: "Perfect")
                statColumn(value: "\(model.missCount)", label: "Miss")
            }

            Spacer(minLength: 0)

            Image(ShowtimeAssets.star(model.stars))
                .resizable()
                .scaledToFit()
                .frame(height: Layout.starsHeight)
        }
        .foregroundStyle(AppColors.brownInk)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Record \(model.rank): accuracy \(model.accuracyPercent) percent, "
            + "\(model.perfectCount) perfect, \(model.missCount) miss, \(model.stars) of 3 stars"
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

#if DEBUG
private let showtimePreviewRows: [ShowtimeRecordRowModel] = [0.95, 0.88, 0.70, 0.60, 0.30]
    .enumerated()
    .map { index, accuracy in
        ShowtimeRecordRowModel(
            rank: index + 1,
            result: SessionResult(
                id: UUID(),
                patternID: "subdivision",
                songID: "jingle-bells",
                bpm: 90,
                accuracy: accuracy,
                perfectCount: 20 - index * 3,
                tooEarlyCount: 1,
                missCount: index + 1,
                createdAt: .now,
                beatEvents: []
            )
        )
    }

#Preview("Showtime records, loaded", traits: .fixedLayout(width: 720, height: 600)) {
    ShowtimeRecordsContentView(state: .loaded(showtimePreviewRows))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3))
}
#Preview("Showtime records, empty", traits: .fixedLayout(width: 720, height: 600)) {
    ShowtimeRecordsContentView(state: .empty)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3))
}
#Preview("Showtime records, loading", traits: .fixedLayout(width: 720, height: 600)) {
    ShowtimeRecordsContentView(state: .loading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3))
}
#endif
