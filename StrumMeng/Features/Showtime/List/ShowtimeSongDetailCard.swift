import SwiftUI

/// Left side of the detail card: "STRUMMING PATTERN" and duration on top, and below it the 3
/// pattern cards from `Assets.xcassets/Songs` stacked vertically, with the chord banner underneath.
struct ShowtimeSongDetailCard: View {
    let song: Song
    var activePatternID: String = ""
    var onSelectPattern: ((String) -> Void)? = nil

    private var patterns: [ShowtimePatternInfo] {
        ShowtimePatternCatalog.patterns(forSongID: song.id)
    }

    private var currentPatternID: String {
        if !activePatternID.isEmpty {
            return activePatternID
        }
        return ShowtimePatternCatalog.defaultPatternID(for: song.id)
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
            // Header beside back button: Always "STRUMMING PATTERN"
            VStack(alignment: .leading, spacing: 2) {
                Text("STRUMMING PATTERN")
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

            if !patterns.isEmpty {
                // Stack of 3 pattern cards from Assets.xcassets/Songs
                ForEach(Array(patterns.enumerated()), id: \.element.id) { index, pattern in
                    let isActive = pattern.id == currentPatternID
                    let leading = isActive ? Self.activeLeading : Self.inactiveLeading
                    let top = Self.cardTop(for: index, isActive: isActive)

                    patternCardView(pattern: pattern, isActive: isActive)
                        .offset(x: leading, y: top)
                        .zIndex(isActive ? 10 : Double(5 - index))
                        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isActive)
                        .onTapGesture {
                            onSelectPattern?(pattern.id)
                        }
                }

                // Chord banner below the 3 pattern cards (positioned right above the title box)
                chordBannerView
                    .offset(x: Self.chordBannerLeading, y: Self.chordBannerTop)
                    .zIndex(1)
            } else if let fallbackPattern = song.primaryPatternID.flatMap(PatternCatalog.pattern(forID:)) {
                fallbackArtwork(for: fallbackPattern)
                    .offset(x: Self.artworkLeading, y: Self.artworkTop)
            }
        }
        .frame(width: 716, height: 820, alignment: .topLeading)
    }

    @ViewBuilder
    private func patternCardView(pattern: ShowtimePatternInfo, isActive: Bool) -> some View {
        let cardWidth = isActive ? Self.activeWidth : Self.inactiveWidth
        Image(pattern.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: cardWidth, alignment: .leading)
            .brightness(isActive ? 0 : -0.10)
            .colorMultiply(isActive ? .white : Color(red: 0.50, green: 0.34, blue: 0.23))
            .opacity(isActive ? 1.0 : 0.95)
            .shadow(color: isActive ? Color.black.opacity(0.38) : .clear, radius: 6, x: 0, y: 4)
            .contentShape(Rectangle())
            .accessibilityLabel(pattern.name)
            .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    @ViewBuilder
    private var chordBannerView: some View {
        Image(ShowtimeAssets.chordArtwork(forSongID: song.id))
            .resizable()
            .scaledToFit()
            .frame(width: Self.chordBannerWidth, alignment: .leading)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func fallbackArtwork(for pattern: StrumPattern) -> some View {
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

    // Active card: larger, longer, extends to left edge of wood wall
    private static let activeWidth: CGFloat = 672
    private static let activeLeading: CGFloat = 0

    // Inactive card: narrower, flushed with left edge, wood tone
    private static let inactiveWidth: CGFloat = 572
    private static let inactiveLeading: CGFloat = 0

    // Fallback constants
    private static let artworkWidth: CGFloat = 632
    private static let artworkLeading: CGFloat = 39
    private static let artworkTop: CGFloat = 250

    /// Vertical positions for the 3 pattern cards:
    /// Card 0 is at 195, Card 1 at 320, Card 2 at 445. Active card is slightly raised by 6 pt.
    private static func cardTop(for index: Int, isActive: Bool) -> CGFloat {
        let base = 195 + CGFloat(index) * 122
        return isActive ? base - 6 : base
    }

    /// Chord banner is positioned lower down (y = 660) between Card 3 and the bottom Title Box (y = 794).
    private static let chordBannerWidth: CGFloat = 642
    private static let chordBannerLeading: CGFloat = 20
    private static let chordBannerTop: CGFloat = 660
}

/// Right side of the detail card: the records card.
struct ShowtimeRecordsCard<Records: View>: View {
    private let records: Records

    init(stars: Int = 0, @ViewBuilder records: () -> Records) {
        self.records = records()
    }

    var body: some View {
        records
            .frame(width: 584, height: 480)
    }
}

/// Fallback arrows for a pattern that has no artwork.
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
