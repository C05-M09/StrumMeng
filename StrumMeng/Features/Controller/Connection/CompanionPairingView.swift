import SwiftUI

/// iPhone, portrait: the walkie-talkie from the hi-fi, with the code on its orange screen and a
/// keypad below. Laid out on the hi-fi's own artboard and scaled to the phone.
struct CompanionPairingView: View {
    let viewModel: CompanionViewModel

    /// The hi-fi's artboard (iPhone 17 Pro). Every position below is measured on it.
    private static let referenceSize = CGSize(width: 402, height: 874)
    private static let keySize = CGSize(width: 83.91, height: 88.92)
    /// The delete and clear keys are drawn slightly wider than the digits.
    private static let sideKeySize = CGSize(width: 84.42, height: 88.92)

    private let keyRows = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    var body: some View {
        GeometryReader { proxy in
            let size = Self.referenceSize
            // Fit, so a shorter phone (iPhone SE) never crops the keypad. Recent iPhones share the
            // artboard's shape, so the filled copy behind only shows on the SE.
            let scale = min(proxy.size.width / size.width, proxy.size.height / size.height)

            ZStack {
                Image("Companion_Pair_BG").resizable()
                title.position(x: size.width / 2, y: 76.8)
                lines(prompt, font: AppTypography.bungee(size: 22), spacing: -7.4)
                    .position(x: size.width / 2, y: 252)
                PairCodeSlotsView(code: typedCode, slotSize: CGSize(width: 46.8, height: 62.2),
                                  fill: AppColors.white, borderWidth: 3, spacing: 3.9)
                    .position(x: size.width / 2, y: 312)
                lines(hint, font: AppTypography.dmMono(size: 18), spacing: -2)
                    .position(x: size.width / 2, y: 376.7)
                keypad.position(x: 201.2, y: 634.7)
            }
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background {
            Image("Companion_Pair_BG")
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }

    private var title: some View {
        OutlinedText(text: "PAIR DEVICE", font: AppTypography.bungee(size: 40),
                     foregroundColor: AppColors.white, outlineColor: AppColors.brownInk,
                     outlineWidth: 6, shadowColor: AppColors.brownInk, shadowOffset: .zero,
                     alignment: .center)
    }

    /// One Text per line, so the tight line gap of the hi-fi does not rely on negative line spacing.
    private func lines(_ lines: [String], font: Font, spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            ForEach(lines, id: \.self) { line in
                Text(line).font(font)
            }
        }
        .foregroundStyle(AppColors.white)
        .multilineTextAlignment(.center)
        .fixedSize()
        .accessibilityElement(children: .combine)
    }

    // MARK: Keypad

    private var keypad: some View {
        VStack(spacing: 9.1) {
            ForEach(keyRows, id: \.self) { row in
                HStack(spacing: 8.3) {
                    ForEach(row, id: \.self) { digitKey($0) }
                }
            }
            HStack(spacing: 8.3) {
                key("Companion_Key_Delete", size: Self.sideKeySize, label: "Delete") {
                    viewModel.send(.deleteDigit)
                }
                .keypadLocked(isConnecting)
                digitKey(0)
                cornerKey
            }
        }
    }

    /// The check sends the code and is dimmed until all six digits are in. While connecting it turns
    /// into the cross, the one live key then, which stops looking for the iPad.
    @ViewBuilder
    private var cornerKey: some View {
        if isConnecting {
            key("Companion_Key_Clear", size: Self.sideKeySize, label: "Cancel") {
                viewModel.send(.disconnect)
            }
        } else {
            key("Companion_Key_Confirm", size: Self.sideKeySize, label: "Connect") {
                viewModel.send(.confirmCode)
            }
            .keypadLocked(!isCodeComplete)
        }
    }

    private func digitKey(_ digit: Int) -> some View {
        key("Companion_Key_\(digit)", size: Self.keySize, label: String(digit)) {
            viewModel.send(.typeDigit(digit))
        }
        .keypadLocked(isConnecting)
    }

    /// The key art has no pressed version, so the press shows as the button's shrink alone.
    private func key(_ asset: String, size: CGSize, label: String, action: @escaping () -> Void) -> some View {
        AssetPressButton(normalAsset: asset, pressedAsset: asset, size: size, accessibilityLabel: label,
                         action: action)
    }

    // MARK: Text per state

    private var prompt: [String] {
        switch viewModel.state {
        case .connecting: ["CONNECTING..."]
        case .notFound: ["IPAD NOT FOUND"]
        default: ["ENTER THE CODE", "ON YOUR IPAD"]
        }
    }

    private var hint: [String] {
        switch viewModel.state {
        case .connecting: ["looking for your ipad", "tap x to cancel"]
        case .notFound: ["check the code", "and the wifi"]
        default: ["use the same wifi", "with your ipad"]
        }
    }

    /// A full code not being sent yet: typed, or left from an attempt that found no iPad.
    private var isCodeComplete: Bool {
        switch viewModel.state {
        case let .enteringCode(code), let .notFound(code): code.count == PairCode.length
        case .connecting, .connected, .reconnecting: false
        }
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

private extension View {
    /// Dims a key and stops it taking touches while the iPhone is looking for the iPad.
    func keypadLocked(_ locked: Bool) -> some View {
        opacity(locked ? 0.45 : 1)
            .allowsHitTesting(!locked)
            .accessibilityHidden(locked)
    }
}

#Preview("Empty code") {
    CompanionPairingView(viewModel: .preview(state: .enteringCode("")))
}

#Preview("Entering code") {
    CompanionPairingView(viewModel: .preview(state: .enteringCode("48")))
}

#Preview("Full code, ready to connect") {
    CompanionPairingView(viewModel: .preview(state: .enteringCode("482913")))
}

#Preview("Connecting") {
    CompanionPairingView(viewModel: .preview(state: .connecting("482913")))
}

#Preview("iPad not found") {
    CompanionPairingView(viewModel: .preview(state: .notFound("482913")))
}
