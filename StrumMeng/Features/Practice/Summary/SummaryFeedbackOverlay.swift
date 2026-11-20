//
//  SummaryFeedbackOverlay.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import SwiftUI

/// Shared headline, mascot asset, and dynamic next-step feedback copy for a finished session,
/// reused by both `SummaryFeedbackOverlay` and `SummaryView`.
struct SummaryFeedbackContent {
    let headline: String
    let characterImageName: String
    let message: String

    init(result: SessionResult) {
        let offTempoCount = result.tooEarlyCount + result.missCount
        let extraStrumCount = result.extraStrumCount
        let bpm = result.bpm

        if result.accuracy >= 0.85 {
            headline = "PURRFECT!"
            characterImageName = "cat_purfect"

            if offTempoCount == 0 {
                if bpm < 120 {
                    message = "FLAWLESS RHYTHM! 0 MISTAKES. TAP RETRY TO PUSH TEMPO UP, OR TRY A NEW PATTERN!"
                } else {
                    message = "TOP-SPEED PURRFECT! YOU ACED MAX BPM. HEAD BACK TO TRY THE NEXT PATTERN!"
                }
            } else if bpm >= 120 {
                message = "AWESOME AT MAX BPM! ONLY \(Self.plural(offTempoCount, "SLIP")). WATCH REPLAY OR TRY A NEW PATTERN!"
            } else if result.tooEarlyCount > result.missCount {
                message = "SO SHARP! JUST \(Self.plural(result.tooEarlyCount, "EARLY STRUM")). CHECK REPLAY OR TAP RETRY TO GO FASTER!"
            } else {
                message = "NAILED IT! ONLY \(Self.plural(offTempoCount, "SLIP")). PEEK AT REPLAY OR TAP RETRY TO SPEED UP!"
            }
        } else if result.accuracy >= 0.65 {
            headline = "NICE!!"
            characterImageName = "cat_oke"

            if result.tooEarlyCount > result.missCount {
                message = "CLOSE TIMING! RUSHED \(Self.plural(result.tooEarlyCount, "STRUM")). WATCH REPLAY, THEN RETRY AT THIS BPM!"
            } else if extraStrumCount > 0 && result.missCount >= result.tooEarlyCount {
                message = "ALMOST THERE! AVOID EXTRA STRUMS. CHECK REPLAY, THEN RETRY TO LOCK IT IN!"
            } else if result.missCount > result.tooEarlyCount {
                message = "GOOD JOB! MISSED \(Self.plural(result.missCount, "BEAT")). PEEK AT REPLAY TO HEAR IT, THEN TAP RETRY!"
            } else {
                message = "SOLID RUN! \(Self.plural(offTempoCount, "OFF-TEMPO BEAT")). CHECK REPLAY AND RETRY TO NAIL EVERY HIT!"
            }
        } else {
            headline = "YOU GOOD?"
            characterImageName = "cat_you good"

            if result.perfectCount == 0 {
                message = "TOUGH TAKE! NO PERFECT HITS YET. WATCH REPLAY OR TAP RETRY FOR SLOWER BPM!"
            } else if result.tooEarlyCount > result.missCount {
                if bpm > 60 {
                    message = "WHOA, TOO FAST! RUSHED \(Self.plural(result.tooEarlyCount, "TIME")). CHECK REPLAY, THEN RETRY SLOWER!"
                } else {
                    message = "HOLD YOUR PAWS! RUSHED \(Self.plural(result.tooEarlyCount, "TIME")). WATCH REPLAY AND COUNT ALONG ON RETRY!"
                }
            } else if extraStrumCount > 0 && bpm > 60 {
                message = "TOO MANY EXTRA STRUMS! WATCH REPLAY TO HEAR IT, THEN RETRY SLOWER!"
            } else if bpm > 60 {
                message = "LOST THE BEAT ON \(Self.plural(result.missCount, "BEAT")). CHECK REPLAY, THEN RETRY SLOWER!"
            } else {
                message = "ROUGH RUN AT 60 BPM! WATCH REPLAY TO SPOT MISSES, THEN TAP RETRY AGAIN!"
            }
        }
    }

    private static func plural(_ count: Int, _ singular: String) -> String {
        count == 1 ? "1 \(singular)" : "\(count) \(singular)S"
    }
}

/// An intro overlay presented before the main Summary board is revealed.
///
/// Displays only:
/// 1. The character mascot corresponding to accuracy
/// 2. The outcome banner (e.g. "PURRFECT!", "NICE!!", "YOU GOOD?")
/// 3. The feedback message (off-tempo count or perfect rhythm)
/// 4. A NEXT button to dismiss the overlay and reveal the full Summary view.
struct SummaryFeedbackOverlay: View {
    let result: SessionResult
    var onNext: () -> Void

    @State private var mascotEntered: Bool = false
    @State private var bannerEntered: Bool = false
    @State private var feedbackEntered: Bool = false
    @State private var buttonEntered: Bool = false

    init(result: SessionResult, onNext: @escaping () -> Void = {}) {
        self.result = result
        self.onNext = onNext
    }

    private var content: SummaryFeedbackContent {
        SummaryFeedbackContent(result: result)
    }

    var body: some View {
        GeometryReader { proxy in
            let sx = proxy.size.width / AppLayout.referenceSize.width
            let sy = proxy.size.height / AppLayout.referenceSize.height

            ZStack {
                // 1. Semi-transparent dark comic dim layer (allows SummaryView to be seen behind)
                AppColor.dim.opacity(0.95)
                    .ignoresSafeArea()

                // 2. Main overlay content scaled to reference canvas (1376 x 1032)
                overlayCanvas
                    .frame(
                        width: AppLayout.referenceSize.width,
                        height: AppLayout.referenceSize.height
                    )
                    .scaleEffect(x: sx, y: sy)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            triggerEntranceAnimation()
        }
    }

    // MARK: - Entrance Animation
    private func triggerEntranceAnimation() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(0.35)) {
            mascotEntered = true
        }
        withAnimation(.spring(response: 0.40, dampingFraction: 0.70).delay(0.47)) {
            bannerEntered = true
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.75).delay(0.59)) {
            feedbackEntered = true
        }
        // Step 4: Tombol NEXT muncul setelah 3 detik
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(3.0)) {
            buttonEntered = true
        }
    }

    // MARK: - Overlay Canvas (1376 x 1032)
    @ViewBuilder
    private var overlayCanvas: some View {
        ZStack {
           

            // 2. Banner Background Chatbox
            // 💡 Atur x dan y untuk posisikan banner background
            VStack {
                Image("Summary_Title chatbox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 610)
            }
            .position(x: 480, y: 685)
            .offset(x: bannerEntered ? 0 : 200)
            .opacity(bannerEntered ? 1.0 : 0.0)

            // 2b. Teks Judul ("NICE!!", "PURRFECT!", dll.)
            // 💡 Atur x dan y untuk posisikan teks judul agar pas persis dengan SummaryView
            VStack(alignment: .leading) {
                Text(content.headline)
                    .font(AppTypography.bungee(size: 55))
                    .foregroundStyle(AppColors.white)
            }
            .frame(width: 400, height: 100, alignment: .leading)
            .position(x: 595, y: 680)
            .offset(x: bannerEntered ? 0 : 200)
            .opacity(bannerEntered ? 1.0 : 0.0)

            // 3. Feedback Chatbox (Pesan off-tempo / perfect)
            // 💡 Atur x dan y untuk posisikan kotak feedback
            VStack {
                ZStack(alignment: .leading) {
                    Image("Summary_Chatbox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 760)
                    
                    Text(content.message)
                        .font(AppTypography.dmMono(size: 28))
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.brownInk)
                        .lineSpacing(4)
                        .minimumScaleFactor(0.85)
                        .frame(width: 480, height: 190, alignment: .leading)
                        .padding(.leading, 220)
                        .padding(.bottom, 20)
                }
            }
            .position(x: 560, y: 870)
            .offset(y: feedbackEntered ? 0 : 40)
            .opacity(feedbackEntered ? 1.0 : 0.0)

            // 4. Tombol NEXT
            // 💡 Atur x dan y untuk posisikan tombol NEXT
            VStack {
                Button {
                    onNext()
                } label: {
                    EmptyView()
                }
                .disabled(!buttonEntered)
                .buttonStyle(
                    AssetButtonStyle(
                        normalAssetName: "Button_Next_Normal",
                        pressedAssetName: "Button_Next_Pressed",
                        size: CGSize(width: 240, height: 100)
                    )
                )
            }
            .position(x: 950, y: 960)
            .offset(y: buttonEntered ? 0 : 30)
            .opacity(buttonEntered ? 1.0 : 0.0)
            
//            // 1. Ekspresi Maskot Karakter
//            // 💡 Atur x dan y untuk posisikan maskot
            VStack {
                Image(content.characterImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400)
            }
            .position(x: 190, y: 820)
            .offset(x: mascotEntered ? 0 : -300)
            .opacity(mascotEntered ? 1.0 : 0.0)
            
        }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
    }
}

// MARK: - Previews
#if DEBUG
private struct OverlayPreviewSessionRepository: SessionRepository {
    func save(_ result: SessionResult) async throws {}
    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult] { [] }
    func lastPracticeBPM(forPattern patternID: String) async throws -> Int? { nil }
    func topRecords(
        patternID: String,
        limit: Int?,
        sortedBy: RecordSortCriterion
    ) async throws -> [SessionResult] { [] }
}

private struct FeedbackScenario: Identifiable {
    let id: String
    let label: String
    let result: SessionResult

    static func makeResult(
        bpm: Int,
        accuracy: Double,
        perfect: Int,
        early: Int,
        miss: Int,
        extraStrums: Int = 0
    ) -> SessionResult {
        let extras = (0..<extraStrums).map {
            RecordedStrum(time: Double($0) * 0.5, direction: .down, isExtra: true)
        }
        return SessionResult(
            id: UUID(),
            patternID: "syncopation",
            songID: nil,
            bpm: bpm,
            accuracy: accuracy,
            perfectCount: perfect,
            tooEarlyCount: early,
            missCount: miss,
            createdAt: Date(),
            beatEvents: [],
            strums: extras
        )
    }

    static let all: [FeedbackScenario] = [
        FeedbackScenario(id: "p1", label: "Purrfect 100% (<120)", result: makeResult(bpm: 80, accuracy: 1.0, perfect: 16, early: 0, miss: 0)),
        FeedbackScenario(id: "p2", label: "Purrfect 100% (120 BPM)", result: makeResult(bpm: 120, accuracy: 1.0, perfect: 16, early: 0, miss: 0)),
        FeedbackScenario(id: "p3", label: "Purrfect Minor Early", result: makeResult(bpm: 90, accuracy: 0.90, perfect: 14, early: 2, miss: 0)),
        FeedbackScenario(id: "p4", label: "Purrfect Minor Miss", result: makeResult(bpm: 90, accuracy: 0.88, perfect: 14, early: 0, miss: 2)),
        FeedbackScenario(id: "p5", label: "Purrfect Slip @ 120", result: makeResult(bpm: 120, accuracy: 0.90, perfect: 14, early: 1, miss: 1)),
        FeedbackScenario(id: "n1", label: "Nice!! Mostly Early", result: makeResult(bpm: 90, accuracy: 0.75, perfect: 12, early: 3, miss: 1)),
        FeedbackScenario(id: "n2", label: "Nice!! Extra Strums", result: makeResult(bpm: 90, accuracy: 0.75, perfect: 12, early: 1, miss: 3, extraStrums: 2)),
        FeedbackScenario(id: "n3", label: "Nice!! Mostly Miss", result: makeResult(bpm: 90, accuracy: 0.70, perfect: 11, early: 1, miss: 4)),
        FeedbackScenario(id: "n4", label: "Nice!! Balanced", result: makeResult(bpm: 90, accuracy: 0.75, perfect: 12, early: 2, miss: 2)),
        FeedbackScenario(id: "y1", label: "You Good? 0 Perfect", result: makeResult(bpm: 80, accuracy: 0.15, perfect: 0, early: 4, miss: 12)),
        FeedbackScenario(id: "y2", label: "You Good? Fast >60", result: makeResult(bpm: 90, accuracy: 0.50, perfect: 8, early: 6, miss: 2)),
        FeedbackScenario(id: "y3", label: "You Good? Fast @60", result: makeResult(bpm: 60, accuracy: 0.50, perfect: 8, early: 6, miss: 2)),
        FeedbackScenario(id: "y4", label: "You Good? Extra >60", result: makeResult(bpm: 80, accuracy: 0.45, perfect: 7, early: 2, miss: 7, extraStrums: 3)),
        FeedbackScenario(id: "y5", label: "You Good? Miss >60", result: makeResult(bpm: 80, accuracy: 0.45, perfect: 7, early: 2, miss: 7)),
        FeedbackScenario(id: "y6", label: "You Good? Miss @60", result: makeResult(bpm: 60, accuracy: 0.40, perfect: 6, early: 2, miss: 8))
    ]
}

private struct FeedbackScenarioBrowserPreview: View {
    @State private var index: Int = 0
    @State private var showOverlay: Bool = true

    private var scenario: FeedbackScenario {
        FeedbackScenario.all[index]
    }

    var body: some View {
        ZStack(alignment: .top) {
            SummaryView(
                viewModel: SummaryViewModel(
                    result: scenario.result,
                    repository: OverlayPreviewSessionRepository()
                ),
                showIntroOverlay: showOverlay
            )
            .id("\(scenario.id)-\(showOverlay)")

            HStack(spacing: 10) {
                Button("◀") {
                    index = (index - 1 + FeedbackScenario.all.count) % FeedbackScenario.all.count
                }
                .buttonStyle(.borderedProminent)

                Text("\(index + 1)/\(FeedbackScenario.all.count): \(scenario.label)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                Button("▶") {
                    index = (index + 1) % FeedbackScenario.all.count
                }
                .buttonStyle(.borderedProminent)

                Button(showOverlay ? "View: Overlay" : "View: Board") {
                    showOverlay.toggle()
                }
                .buttonStyle(.bordered)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.top, 14)
        }
    }
}

#Preview("All Feedback Scenarios", traits: .landscapeLeft) {
    FeedbackScenarioBrowserPreview()
}

#Preview("Purrfect - 100%", traits: .landscapeLeft) {
    SummaryFeedbackOverlay(result: FeedbackScenario.all[0].result)
}

#Preview("Nice!! - Extra Strums", traits: .landscapeLeft) {
    SummaryFeedbackOverlay(result: FeedbackScenario.all[6].result)
}

#Preview("You Good? - Too Fast (>60 BPM)", traits: .landscapeLeft) {
    SummaryFeedbackOverlay(result: FeedbackScenario.all[10].result)
}
#endif
