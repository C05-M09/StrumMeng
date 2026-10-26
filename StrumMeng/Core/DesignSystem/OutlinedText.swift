import SwiftUI

struct OutlinedText: View {
    let text: String
    let font: Font
    let foregroundColor: Color
    let outlineColor: Color
    let outlineWidth: CGFloat
    let shadowColor: Color
    let shadowOffset: CGSize
    var alignment: TextAlignment = .leading

    var body: some View {
        ZStack {
            outlinedLayer
                .offset(shadowOffset)
                .foregroundStyle(shadowColor)

            outlinedLayer
                .foregroundStyle(outlineColor)

            textLayer
                .foregroundStyle(foregroundColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private var outlinedLayer: some View {
        ZStack {
            ForEach(offsets, id: \.self) { offset in
                textLayer.offset(offset)
            }
        }
    }

    private var textLayer: some View {
        Text(text)
            .font(font)
            .multilineTextAlignment(alignment)
            .lineSpacing(-6)
    }

    private var offsets: [CGSize] {
        let diagonal = outlineWidth * 0.72
        return [
            CGSize(width: -outlineWidth, height: 0),
            CGSize(width: outlineWidth, height: 0),
            CGSize(width: 0, height: -outlineWidth),
            CGSize(width: 0, height: outlineWidth),
            CGSize(width: -diagonal, height: -diagonal),
            CGSize(width: diagonal, height: -diagonal),
            CGSize(width: -diagonal, height: diagonal),
            CGSize(width: diagonal, height: diagonal),
        ]
    }
}
