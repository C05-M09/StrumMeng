import SwiftUI

/// The header box that hangs from the top edge of the screen and carries the level title
/// (Listen, Play, Replay). Long titles wrap onto two lines, as in the hi-fi.
struct TitleBanner: View {
    let title: String
    var fontSize: CGFloat = 46
    var width: CGFloat = 590
    var height: CGFloat = 150

    var body: some View {
        let border = max(2, height * 0.035)
        ZStack {
            // An inside stroke clipped to the shape gives the same border on the slanted sides and the
            // rounded bottom. The shape starts above the screen so the top edge has no border.
            BannerShape()
                .fill(AppColor.bannerBrown)
                .overlay {
                    BannerShape().stroke(AppColor.ink, lineWidth: border * 2)
                }
                .clipShape(BannerShape())
                .frame(width: width, height: height + border)
                .offset(y: -border / 2)

            OutlinedText(text: title.uppercased(), font: AppFont.display(fontSize),
                         foregroundColor: AppColor.titleText, outlineColor: AppColor.ink,
                         outlineWidth: fontSize * 0.085, shadowColor: .clear, shadowOffset: .zero,
                         alignment: .center)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: width * 0.78)
        }
        .frame(width: width, height: height)
    }
}

#Preview {
    VStack {
        TitleBanner(title: "Subdivision Strum")
        Spacer()
    }
    .frame(width: 994, height: 300)
    .background(AppColor.practiceBackground)
}
