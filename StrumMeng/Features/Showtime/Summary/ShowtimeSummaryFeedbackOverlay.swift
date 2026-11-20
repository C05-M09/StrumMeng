//
//  ShowtimeSummaryFeedbackOverlay.swift
//  StrumMeng
//
//  Created by Sharon Tan on 12/11/26.
//

import SwiftUI

/// An intro overlay presented before the main Showtime Summary board is revealed.
///
/// Mirrors Practice's `SummaryFeedbackOverlay` layout and animations while displaying
/// Showtime's star rating and off-tempo feedback message.
struct ShowtimeSummaryFeedbackOverlay: View {
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

    private var content: ShowtimeSummaryFeedbackContent {
        ShowtimeSummaryFeedbackContent(result: result)
    }

    var body: some View {
        GeometryReader { proxy in
            let sx = proxy.size.width / AppLayout.referenceSize.width
            let sy = proxy.size.height / AppLayout.referenceSize.height

            ZStack {
                AppColor.dim.opacity(0.95)
                    .ignoresSafeArea()

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
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(3.0)) {
            buttonEntered = true
        }
    }

    // MARK: - Overlay Canvas (1376 x 1032)
    @ViewBuilder
    private var overlayCanvas: some View {
        ZStack {
            // 1. Banner Background Chatbox
            VStack {
                Image("Summary_Title chatbox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 610)
            }
            .position(x: 480, y: 685)
            .offset(x: bannerEntered ? 0 : 200)
            .opacity(bannerEntered ? 1.0 : 0.0)

            // 1b. Headline ("AWESOME!", "NICE!!", "YOU GOOD?")
            VStack(alignment: .leading) {
                Text(content.headline)
                    .font(AppTypography.bungee(size: 55))
                    .foregroundStyle(AppColors.white)
            }
            .frame(width: 400, height: 100, alignment: .leading)
            .position(x: 595, y: 680)
            .offset(x: bannerEntered ? 0 : 200)
            .opacity(bannerEntered ? 1.0 : 0.0)

            // 2. Feedback Chatbox
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

            // 3. Tombol NEXT
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

            // 4. Ekspresi Maskot Karakter
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

