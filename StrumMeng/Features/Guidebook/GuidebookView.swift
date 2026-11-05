//
//  GuidebookView.swift
//  StrumMeng
//
//  Created by sharon on 30/10/26.
//

import SwiftUI

/// The Guidebook screen: 3 educational pages presented as an overlay on Home.
/// Laid out in `AppLayout.referenceSize` and scaled to the device, like OptionView and PatternListView.
struct GuidebookView: View {
    @Bindable var viewModel: GuidebookViewModel

    @State private var dragOffset: CGFloat = 0
    @State private var isShuffling: Bool = false
    @State private var shufflingCardIndex: Int? = nil
    @State private var shuffleOffset: CGFloat = 0
    @State private var shuffleRotation: Double = 0
    @State private var shuffleZIndex: Double = 10
    @State private var shuffleScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { proxy in
            let scale = max(
                proxy.size.width / AppLayout.referenceSize.width,
                proxy.size.height / AppLayout.referenceSize.height
            )

            ZStack {
                // Dimmed brown backdrop
                AppColors.brownPrimary
                    .ignoresSafeArea()
                    .opacity(0.85)

                content
                    .frame(
                        width: AppLayout.referenceSize.width,
                        height: AppLayout.referenceSize.height
                    )
                    .scaleEffect(scale)
                    .frame(
                        width: AppLayout.referenceSize.width * scale,
                        height: AppLayout.referenceSize.height * scale
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var content: some View {
        ZStack {
            // Side tap areas for left and right margins outside card stack
            sideTapAreas

            // Interactive stacked paper deck
            cardStack

            // Pager dots indicator
            pageDotsIndicator

            // Back button
            BackButton(action: viewModel.dismiss)
                .position(BackButton.referenceCenter)
        }
        .frame(
            width: AppLayout.referenceSize.width,
            height: AppLayout.referenceSize.height
        )
        .clipped()
    }

    private var sideTapAreas: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isShuffling else { return }
                    pullFromBackToFront(direction: 1)
                }

            Spacer()
                .frame(width: 685)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isShuffling else { return }
                    shuffleToBack(direction: -1)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cardStack: some View {
        ZStack {
            // Solid paper rectangle base behind the entire deck so the background never shows through
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.97, green: 0.89, blue: 0.75))
                .frame(width: 660, height: 780)
                .shadow(color: Color.black.opacity(0.18), radius: 10, y: 6)
                .offset(y: 12)
                .zIndex(-10)

            ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                cardView(for: page)
                    .scaleEffect(stackScale(for: index))
                    .offset(x: stackOffsetX(for: index), y: stackOffsetY(for: index))
                    .rotationEffect(stackRotation(for: index))
                    .zIndex(stackZIndex(for: index))
                    .allowsHitTesting(index == viewModel.currentPageIndex && !isShuffling)
            }
        }
        .frame(width: 685, height: 805)
        .position(
            x: AppLayout.referenceSize.width / 2,
            y: 510
        )
        .contentShape(Rectangle())
        .onTapGesture { location in
            guard !isShuffling else { return }
            if location.x < 685 / 2 {
                pullFromBackToFront(direction: 1)
            } else {
                shuffleToBack(direction: -1)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 15)
                .onChanged { gesture in
                    guard !isShuffling else { return }
                    dragOffset = gesture.translation.width
                }
                .onEnded { gesture in
                    guard !isShuffling else { return }
                    let translation = gesture.translation.width
                    if translation < -60 {
                        // Slide Next: current card tucks behind
                        shuffleToBack(direction: -1)
                    } else if translation > 60 {
                        // Slide Back: previous card pulls from behind to front
                        pullFromBackToFront(direction: 1)
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    /// When sliding next: Top active card slides out and tucks behind the deck
    private func shuffleToBack(direction: CGFloat) {
        guard !isShuffling else { return }
        isShuffling = true

        let activeIndex = viewModel.currentPageIndex
        shufflingCardIndex = activeIndex
        shuffleOffset = dragOffset
        shuffleRotation = Double(dragOffset) / 28.0
        shuffleZIndex = 10
        dragOffset = 0

        // Step 1: Slide top card out to the side with realistic tilt
        withAnimation(.easeOut(duration: 0.22)) {
            shuffleOffset = direction * 420
            shuffleRotation = Double(direction) * 9.0
        }

        // Step 2: Drop behind the stack and tuck into the bottom
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            shuffleZIndex = -1 // Drops behind all cards in the stack

            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                viewModel.nextPage()
                shuffleOffset = stackRestingOffsetX(forOrder: viewModel.pages.count - 1)
                shuffleRotation = stackRestingRotation(forOrder: viewModel.pages.count - 1)
            }

            try? await Task.sleep(nanoseconds: 420_000_000)
            shufflingCardIndex = nil
            isShuffling = false
        }
    }

    /// When sliding back: The previous card pulls out from the back and lands on top
    private func pullFromBackToFront(direction: CGFloat) {
        guard !isShuffling else { return }
        isShuffling = true

        let prevIndex = (viewModel.currentPageIndex - 1 + viewModel.pages.count) % viewModel.pages.count
        shufflingCardIndex = prevIndex

        // Start from where the user dragged the back card
        shuffleZIndex = 0
        shuffleScale = 0.94 + min(max(dragOffset / 200.0, 0), 1.0) * 0.04
        shuffleOffset = stackRestingOffsetX(forOrder: 2) + dragOffset
        shuffleRotation = stackRestingRotation(forOrder: 2) + (Double(dragOffset) / 25.0)
        dragOffset = 0

        // Phase 1: Card smoothly pulls all the way OUT to the right
        withAnimation(.easeOut(duration: 0.20)) {
            shuffleOffset = direction * 420
            shuffleRotation = Double(direction) * 9.0
            shuffleScale = 0.98
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            // Phase 2: Elevate to very top above the deck
            shuffleZIndex = 15
            shuffleScale = 1.0
            viewModel.previousPage()

            // Phase 3: Land smoothly onto the top of the deck
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                shuffleOffset = 0
                shuffleRotation = 0
            }

            try? await Task.sleep(nanoseconds: 420_000_000)
            shufflingCardIndex = nil
            isShuffling = false
        }
    }

    private func stackOrder(for index: Int) -> Int {
        (index - viewModel.currentPageIndex + viewModel.pages.count) % viewModel.pages.count
    }

    private func stackZIndex(for index: Int) -> Double {
        if index == shufflingCardIndex {
            return shuffleZIndex
        }
        return Double(viewModel.pages.count - stackOrder(for: index))
    }

    /// Back card index in the stack (the card resting at the very bottom/behind)
    private var backCardIndex: Int {
        (viewModel.currentPageIndex - 1 + viewModel.pages.count) % viewModel.pages.count
    }

    private func stackScale(for index: Int) -> CGFloat {
        if index == shufflingCardIndex {
            return shuffleScale
        }
        // When dragging right, the back card starts enlarging slightly as it peeks out
        if dragOffset > 0 && index == backCardIndex {
            let progress = min(dragOffset / 200.0, 1.0)
            return 0.94 + (0.04 * progress)
        }
        switch stackOrder(for: index) {
        case 0: return 1.0
        case 1: return 0.97
        default: return 0.94
        }
    }

    private func stackOffsetY(for index: Int) -> CGFloat {
        if index == shufflingCardIndex {
            return 0
        }
        switch stackOrder(for: index) {
        case 0: return 0
        case 1: return 8
        default: return 16
        }
    }

    private func stackOffsetX(for index: Int) -> CGFloat {
        if index == shufflingCardIndex {
            return shuffleOffset
        }
        // When dragging left (Next): front card moves
        if index == viewModel.currentPageIndex {
            return dragOffset < 0 ? dragOffset : 0
        }
        // When dragging right (Back): back card peeks and follows the drag!
        if index == backCardIndex && dragOffset > 0 {
            return stackRestingOffsetX(forOrder: 2) + dragOffset
        }
        return stackRestingOffsetX(forOrder: stackOrder(for: index))
    }

    private func stackRotation(for index: Int) -> Angle {
        if index == shufflingCardIndex {
            return .degrees(shuffleRotation)
        }
        // When dragging left: front card tilts
        if index == viewModel.currentPageIndex {
            return dragOffset < 0 ? .degrees(Double(dragOffset) / 28.0) : .zero
        }
        // When dragging right: back card tilts as it's pulled out
        if index == backCardIndex && dragOffset > 0 {
            return .degrees(stackRestingRotation(forOrder: 2) + (Double(dragOffset) / 25.0))
        }
        return .degrees(stackRestingRotation(forOrder: stackOrder(for: index)))
    }

    private func stackRestingOffsetX(forOrder order: Int) -> CGFloat {
        switch order {
        case 1: return 4
        case 2: return -3
        default: return 0
        }
    }

    private func stackRestingRotation(forOrder order: Int) -> Double {
        switch order {
        case 1: return 1.2
        case 2: return -0.8
        default: return 0.0
        }
    }

    private func cardView(for page: GuidebookPage) -> some View {
        ZStack(alignment: .top) {
            Image(page.backgroundAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 685, height: 805)

            if page.isInteractiveTempo {
                GuidebookTempoControlView(viewModel: viewModel)
                    .padding(.top, 130)
            }
        }
        .frame(width: 685, height: 805)
    }

    private var pageDotsIndicator: some View {
        HStack(spacing: 16) {
            ForEach(0..<viewModel.pages.count, id: \.self) { index in
                Button {
                    let target = index
                    guard target != viewModel.currentPageIndex, !isShuffling else { return }
                    if target > viewModel.currentPageIndex {
                        shuffleToBack(direction: -1)
                    } else {
                        pullFromBackToFront(direction: 1)
                    }
                } label: {
                    Circle()
                        .fill(viewModel.currentPageIndex == index ? AppColors.cream : AppColors.cream.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(AppColors.cream.opacity(0.6), lineWidth: 1)
                        )
                }
                .accessibilityLabel("Guidebook page \(index + 1) of \(viewModel.pages.count)")
            }
        }
        .position(
            x: AppLayout.referenceSize.width / 2,
            y: 960
        )
    }
}

#Preview {
    GuidebookView(
        viewModel: GuidebookViewModel(
            onBackRequested: {}
        )
    )
}
