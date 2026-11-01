import SwiftUI

/// Stand-in for the companion guitar artwork: the neck runs up the portrait screen, the sound hole
/// sits at the bottom and the strings are vertical, so strumming crosses them left and right.
struct CompanionGuitarPlaceholderView: View {
    private static let stringCount = 6
    private static let fretCount = 6

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let neckWidth = size.width * 0.72
            let holeSize = size.width * 0.86

            ZStack {
                AppColor.progressStroke

                Circle()
                    .fill(AppColor.laneBackground)
                    .frame(width: holeSize, height: holeSize)
                    .overlay(Circle().strokeBorder(AppColor.track, lineWidth: holeSize * 0.05))
                    .overlay(Circle().strokeBorder(AppColor.ink, lineWidth: AppSpacing.outline))
                    .position(x: size.width / 2, y: size.height - holeSize * 0.4)

                neck
                    .frame(width: neckWidth, height: size.height * 0.84)
                    .position(x: size.width / 2, y: size.height * 0.42)

                strings
                    .frame(width: neckWidth * 0.8, height: size.height)
                    .position(x: size.width / 2, y: size.height / 2)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var neck: some View {
        ZStack {
            Rectangle().fill(AppColor.bannerBrown)
            VStack(spacing: 0) {
                ForEach(0..<Self.fretCount, id: \.self) { _ in
                    Spacer()
                    Rectangle().fill(AppColor.practiceBackground).frame(height: AppSpacing.s)
                }
                Spacer()
            }
        }
        .overlay(Rectangle().strokeBorder(AppColor.ink, lineWidth: AppSpacing.outline))
    }

    private var strings: some View {
        HStack(spacing: 0) {
            ForEach(0..<Self.stringCount, id: \.self) { index in
                if index > 0 { Spacer() }
                Rectangle()
                    .fill(AppColor.track)
                    .frame(width: AppSpacing.xs + 2)
                    .overlay(Rectangle().strokeBorder(AppColor.ink, lineWidth: 1))
            }
        }
    }
}

#Preview {
    CompanionGuitarPlaceholderView()
}
