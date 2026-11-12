import SwiftUI

/// Left side of the detail card: the pattern's name and length on top, and below it the pattern's
/// own artwork (strumming pattern, line and chords), which is drawn entirely by the asset.
/// The parent places it with `.position`, like the Practice card.
struct ShowtimeSongDetailCard: View {
    let song: Song

    private var pattern: StrumPattern? {
        song.primaryPatternID.flatMap(PatternCatalog.pattern(forID:))
    }

    private var formattedDuration: String {
        let totalSeconds = Int(song.durationSeconds.rounded())
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        if mins > 0 && secs > 0 {
            return "\(mins) min \(secs) sec"
        } else if mins > 0 {
            return "\(mins) min"
        } else {
            return "\(secs) sec"
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text((pattern?.name ?? song.title).uppercased())
                    .font(ShowtimeStyle.title(40))
                    .foregroundStyle(ShowtimeStyle.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(formattedDuration)
                    .font(ShowtimeStyle.body(22))
                    .foregroundStyle(ShowtimeStyle.orange)
            }
            .frame(width: 500, alignment: .leading)
            .offset(x: 184, y: 56)

            if let pattern {
                patternArtwork(for: pattern)
                    .offset(x: Self.artworkLeading, y: Self.artworkTop)
            }
        }
        .frame(width: 716, height: 820, alignment: .topLeading)
    }

    /// Everything under the title comes from the pattern's own artwork. A pattern without artwork
    /// falls back to drawn arrows (no label, line or chords), so the card is never empty.
    @ViewBuilder
    private func patternArtwork(for pattern: StrumPattern) -> some View {
        if let name = ShowtimeAssets.patternArtwork(forPatternID: pattern.id) {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: Self.artworkWidth, alignment: .leading)
                .accessibilityLabel(pattern.name)
        } else {
            ShowtimeStrumRow(pattern: pattern)
                .padding(.leading, 27)
        }
    }

    /// Where the artwork sits. Its arrows line up with the design when it is this wide and this far
    /// from the left, and its line and chords land near the bottom of the wall. Tune the three
    /// numbers together if the artwork changes shape.
    private static let artworkWidth: CGFloat = 632
    private static let artworkLeading: CGFloat = 39
    private static let artworkTop: CGFloat = 250
}

/// Right side of the detail card: the best record's stars on top of the records.
/// `records` is the Showtime records content (`ShowtimeRecordsView`), which already draws the
/// "RECORDS:" title, the record box, 3 visible rows and the empty state.
struct ShowtimeRecordsCard<Records: View>: View {
    let stars: Int
    private let records: Records

    init(stars: Int, @ViewBuilder records: () -> Records) {
        self.stars = stars
        self.records = records()
    }

    var body: some View {
        ZStack(alignment: .top) {
            records
                .padding(.top, 65)

            Image(ShowtimeAssets.star(stars))
                .resizable()
                .scaledToFit()
                .frame(height: 130)
                .offset(y: -40)
        }
        .frame(width: 584, height: 533, alignment: .top)
    }
}

/// Fallback arrows for a pattern that has no artwork: red down, teal up, cream for a rest.
struct ShowtimeStrumRow: View {
    let pattern: StrumPattern

    private enum Kind { case down, up, rest }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(pattern.strokes.enumerated()), id: \.offset) { _, stroke in
                let kind: Kind = {
                    switch stroke {
                    case .down: return .down
                    case .up: return .up
                    default: return .rest
                    }
                }()
                cell(kind)
            }
        }
    }

    @ViewBuilder
    private func cell(_ kind: Kind) -> some View {
        let fill: Color = switch kind {
        case .down: ShowtimeStyle.downRed
        case .up: ShowtimeStyle.upTeal
        case .rest: ShowtimeStyle.cream
        }
        RoundedRectangle(cornerRadius: 10)
            .fill(fill)
            .frame(width: 62, height: 70)
            .overlay {
                switch kind {
                case .down:
                    Image(systemName: "arrow.down").font(.system(size: 34, weight: .heavy)).foregroundStyle(.white)
                case .up:
                    Image(systemName: "arrow.up").font(.system(size: 34, weight: .heavy)).foregroundStyle(.white)
                case .rest:
                    EmptyView()
                }
            }
    }
}

#if DEBUG
#Preview("Records card, 3 stars, empty", traits: .fixedLayout(width: 700, height: 620)) {
    ShowtimeRecordsCard(stars: 3) {
        ShowtimeRecordsContentView(state: .empty)
    }
    .background(ShowtimeStyle.darkBrown)
}
#endif
