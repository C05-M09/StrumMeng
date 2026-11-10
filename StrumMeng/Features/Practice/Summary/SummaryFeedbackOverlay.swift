//
//  SummaryFeedbackOverlay.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import SwiftUI

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

    private var offTempoCount: Int {
        result.tooEarlyCount + result.missCount
    }

    private var headlineText: String {
        if result.accuracy >= 0.85 {
            return "PURRFECT!"
        } else if result.accuracy >= 0.65 {
            return "NICE!!"
        } else {
            return "YOU GOOD?"
        }
    }

    private var charaImage: String {
        if result.accuracy >= 0.85 {
            return "cat_purfect"
        } else if result.accuracy >= 0.65 {
            return "cat_oke"
        } else {
            return "cat_you good"
        }
    }

    private var feedbackText: String {
        if offTempoCount > 0 {
            return "BUT YOU OFF TEMPO \(offTempoCount) \(offTempoCount == 1 ? "TIME" : "TIMES"). KEEP PRACTICING TO LOCK IN THE GROOVE!"
        } else {
            return "ALL ON TEMPO! PERFECT RHYTHM. wdjaw  wa aw wa wdaw daaw dwad awdw awd awd awd awd wa wadawdaw"
        }
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
                Text(headlineText)
                    .font(AppTypography.bungee(size: 55))
                    .foregroundStyle(AppColors.white)
            }
            .frame(width: 400, height: 400, alignment:.leading)
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
                    
                    Text(feedbackText)
                        .font(AppTypography.dmMono(size: 30))
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.brownInk)
                        .lineSpacing(4)
                        .frame(width: 480, height: 190, alignment: .leading)
                        .padding(.leading, 240)
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
                Image(charaImage)
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

#Preview("Feedback Overlay over SummaryView", traits: .landscapeLeft) {
    let repo = OverlayPreviewSessionRepository()
    let sampleResult = SessionResult(
        id: UUID(),
        patternID: "syncopation",
        songID: nil,
        bpm: 100,
        accuracy: 0.2,
        perfectCount: 20,
        tooEarlyCount: 9,
        missCount: 2,
        createdAt: Date(),
        beatEvents: []
    )
    let vm = SummaryViewModel(result: sampleResult, repository: repo)
    SummaryView(viewModel: vm, showIntroOverlay: true)
}

#Preview("Overlay Standalone - Off Tempo", traits: .landscapeLeft) {
    let sampleResult = SessionResult(
        id: UUID(),
        patternID: "syncopation",
        songID: nil,
        bpm: 80,
        accuracy: 0.55,
        perfectCount: 10,
        tooEarlyCount: 3,
        missCount: 2,
        createdAt: Date(),
        beatEvents: []
    )
    SummaryFeedbackOverlay(result: sampleResult)
}
