import SwiftUI

/// iPhone, portrait: the same banner, red board and dark lane as Play, with a keypad for the code.
struct CompanionPairingView: View {
    let viewModel: CompanionViewModel

    private let keyRows = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    var body: some View {
        ZStack(alignment: .top) {
            AppColor.practiceBackground.ignoresSafeArea()

            // The banner hangs from the very top of the screen, past the safe area.
            VStack(spacing: AppSpacing.l) {
                TitleBanner(title: "Pair Device", fontSize: 30, width: 300, height: 110)
                board
                    .padding(.horizontal, AppSpacing.m)
                    .padding(.bottom, AppSpacing.l)
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private var board: some View {
        VStack(spacing: 0) {
            lane
            Spacer(minLength: AppSpacing.m)
            keypad
            Spacer(minLength: AppSpacing.m)
        }
        .padding(AppSpacing.m)
        .background(AppColor.paper, in: RoundedRectangle(cornerRadius: AppSpacing.radiusM))
        .padding(AppSpacing.s + AppSpacing.xs)
        .background(AppColor.boardRed, in: RoundedRectangle(cornerRadius: AppSpacing.radiusL))
    }

    private var lane: some View {
        VStack(spacing: AppSpacing.m) {
            Text(prompt)
                .font(AppFont.display(16))
                .foregroundStyle(AppColor.titleText)
                .multilineTextAlignment(.center)
            PairCodeSlotsView(code: typedCode, slotSize: CGSize(width: 38, height: 50))
            if isConnecting {
                ChunkyButton(title: "Cancel", style: .secondary, fontSize: 14, width: 110, height: 34,
                             hasDropShadow: true) {
                    viewModel.send(.disconnect)
                }
            } else {
                Text(hint)
                    .font(AppFont.mono(13))
                    .foregroundStyle(AppColor.titleText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.l)
        .background(AppColor.laneBackground, in: RoundedRectangle(cornerRadius: AppSpacing.radiusS))
        .padding(AppSpacing.s)
        .background(AppColor.laneBorderTeal, in: RoundedRectangle(cornerRadius: AppSpacing.radiusM))
    }

    private var keypad: some View {
        VStack(spacing: AppSpacing.m) {
            ForEach(keyRows, id: \.self) { row in
                HStack(spacing: AppSpacing.m) {
                    ForEach(row, id: \.self) { digitKey($0) }
                }
            }
            HStack(spacing: AppSpacing.m) {
                Color.clear.frame(width: 84, height: 68)
                digitKey(0)
                ChunkyButton(title: "Del", style: .danger, fontSize: 20, width: 84, height: 68,
                             hasDropShadow: true) {
                    viewModel.send(.deleteDigit)
                }
            }
        }
        .disabled(isConnecting)
        .opacity(isConnecting ? 0.45 : 1)
    }

    private func digitKey(_ digit: Int) -> some View {
        ChunkyButton(title: String(digit), fontSize: 28, width: 84, height: 68, hasDropShadow: true) {
            viewModel.send(.typeDigit(digit))
        }
    }

    private var prompt: String {
        switch viewModel.state {
        case .connecting: "CONNECTING..."
        case .notFound: "IPAD NOT FOUND"
        default: "ENTER THE CODE\nON YOUR IPAD"
        }
    }

    private var hint: String {
        if case .notFound = viewModel.state { return "Check the code and the Wi-Fi" }
        return "Same Wi-Fi as your iPad"
    }

    private var isConnecting: Bool {
        if case .connecting = viewModel.state { return true }
        return false
    }

    private var typedCode: String {
        switch viewModel.state {
        case let .enteringCode(code), let .connecting(code), let .notFound(code): code
        case .connected, .reconnecting: ""
        }
    }
}

#Preview("Entering code") {
    CompanionPairingView(viewModel: .preview(state: .enteringCode("48")))
}

#Preview("Connecting") {
    CompanionPairingView(viewModel: .preview(state: .connecting("482913")))
}

#Preview("iPad not found") {
    CompanionPairingView(viewModel: .preview(state: .notFound("482913")))
}
