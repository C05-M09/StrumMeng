import SwiftUI

struct PatternWheelView: View {
    let patterns: [StrumPattern]
    let selectedPatternID: String
    let onSelect: (String) -> Void

    @State private var dragAngle = 0.0
    @State private var isRotating = false
    @State private var isDragging = false
    @State private var interactionGeneration = 0

    private let pivot = CGPoint(x: -260, y: 516)
    private let highlightRadius: CGFloat = 730
    private let angleBetweenPatterns = 30.0
    private let lineInnerRadius: CGFloat = 555
    private let lineOuterRadius: CGFloat = 930
    private let lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            rotatingWheel
                .rotationEffect(
                    .degrees(wheelRotation),
                    anchor: UnitPoint(
                        x: pivot.x / AppLayout.referenceSize.width,
                        y: pivot.y / AppLayout.referenceSize.height
                    )
                )
        }
        .frame(
            width: AppLayout.referenceSize.width,
            height: AppLayout.referenceSize.height
        )
        .contentShape(Rectangle())
        .gesture(dragGesture.exclusively(before: sectorTapGesture))
        .clipped()
    }

    private var rotatingWheel: some View {
        ZStack {
            ForEach(Array(patterns.enumerated()), id: \.element.id) { index, pattern in
                patternHighlight(for: pattern, at: index)
            }

            generatedPatternLines

            Image("Practice_Circle")
                .resizable()
                .scaledToFit()
                .frame(width: 1_146.62, height: 1_146.6)
                .position(pivot)

            ForEach(Array(patterns.enumerated()), id: \.element.id) { index, pattern in
                patternLabel(pattern, at: index)
            }
        }
        .frame(
            width: AppLayout.referenceSize.width,
            height: AppLayout.referenceSize.height
        )
    }

    private var selectedIndex: Int {
        patterns.firstIndex { $0.id == selectedPatternID } ?? 0
    }

    private var wheelRotation: Double {
        -Double(selectedIndex) * angleBetweenPatterns + dragAngle
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    interactionGeneration += 1

                    withAnimation(.linear(duration: 0.02)) {
                        isRotating = true
                    }
                }

                let proposedAngle = Double(value.translation.height / 5)
                let minimumAngle = -Double(max(patterns.count - 1 - selectedIndex, 0))
                    * angleBetweenPatterns
                let maximumAngle = Double(selectedIndex) * angleBetweenPatterns
                dragAngle = min(
                    max(proposedAngle, minimumAngle),
                    maximumAngle
                )
            }
            .onEnded { value in
                isDragging = false

                guard !patterns.isEmpty else { return }

                let projectedAngle = Double(value.predictedEndTranslation.height / 5)
                let projectedIndex = Double(selectedIndex) - projectedAngle / angleBetweenPatterns
                let targetIndex = Int(
                    min(max(projectedIndex, 0), Double(patterns.count - 1)).rounded()
                )

                selectPattern(at: targetIndex, duration: 0.28)
            }
    }

    private func patternHighlight(for pattern: StrumPattern, at index: Int) -> some View {
        let angle = Double(index) * angleBetweenPatterns
        let position = point(radius: highlightRadius, angle: angle)
        let isSelected = pattern.id == selectedPatternID

        return Image("Highlight")
            .resizable()
            .scaledToFit()
            .frame(width: 370, height: 472.5)
            .rotationEffect(.degrees(angle))
            .position(position)
            .opacity(isSelected && !isRotating ? 1 : 0)
            .scaleEffect(isSelected && !isRotating ? 1 : 0.98)
            .animation(.linear(duration: 0.02), value: isRotating)
            .animation(.linear(duration: 0.02), value: selectedPatternID)
            .allowsHitTesting(false)
    }

    private func patternLabel(_ pattern: StrumPattern, at index: Int) -> some View {
        let angle = Double(index) * angleBetweenPatterns
        let labelCenterRadius = AppLayout.patternLabelInnerRadius
            + (AppLayout.patternLabelWidth / 2)
        let position = point(radius: labelCenterRadius, angle: angle)
        let isSelected = pattern.id == selectedPatternID

        return VStack(alignment: .leading, spacing: AppLayout.patternOrderSpacing) {
            Text(String(format: "%02d", pattern.suggestedOrder))
                .font(AppTypography.bungee(size: 30))
                .foregroundStyle(isSelected ? AppColors.yellowAccent : AppColors.tan)

            VStack(alignment: .leading, spacing: AppLayout.patternNameLineSpacing) {
                ForEach(patternNameLines(for: pattern), id: \.self) { line in
                    OutlinedText(
                        text: line,
                        font: AppTypography.bungee(size: 40),
                        foregroundColor: isSelected ? AppColors.white : AppColors.tan,
                        outlineColor: AppColors.brownInk,
                        outlineWidth: 3,
                        shadowColor: AppColors.brownInk,
                        shadowOffset: CGSize(width: 0, height: 7)
                    )
                }
            }
        }
        .frame(width: AppLayout.patternLabelWidth, alignment: .leading)
        .rotationEffect(.degrees(angle))
        .position(position)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(pattern.name)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { selectPattern(at: index) }
    }

    private var sectorTapGesture: some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                guard !isDragging, !isRotating else { return }

                let dx = value.location.x - pivot.x
                let dy = value.location.y - pivot.y
                let radius = hypot(dx, dy)
                let outerRadius = max(
                    lineOuterRadius,
                    AppLayout.patternLabelInnerRadius + AppLayout.patternLabelWidth
                )
                guard radius >= lineInnerRadius + 25, radius <= outerRadius else { return }

                let screenAngle = atan2(dy, dx) * 180 / .pi
                let relativeAngle = screenAngle - wheelRotation
                let normalizedAngle = (relativeAngle + 360)
                    .truncatingRemainder(dividingBy: 360)
                let signedAngle = normalizedAngle > 360 - angleBetweenPatterns / 2
                    ? normalizedAngle - 360 : normalizedAngle
                let index = Int((signedAngle / angleBetweenPatterns).rounded())
                selectPattern(at: index)
            }
    }

    private var generatedPatternLines: some View {
        ForEach(0...patterns.count, id: \.self) { index in
            let angle = (Double(index) - 0.5) * angleBetweenPatterns
            patternLine(at: angle)
        }
    }

    private func patternLine(at angle: Double) -> some View {
        let length = lineOuterRadius - lineInnerRadius
        let position = point(
            radius: lineInnerRadius + (length / 2),
            angle: angle
        )

        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.recordOutline,
                        AppColors.recordOutline.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: length, height: lineWidth)
            .rotationEffect(.degrees(angle))
            .position(position)
            .allowsHitTesting(false)
    }

    private func selectPattern(at index: Int, duration: Double = 0.14) {
        guard patterns.indices.contains(index) else { return }
        interactionGeneration += 1
        let generation = interactionGeneration

        withAnimation(.linear(duration: 0.02)) {
            isRotating = true
        }

        withAnimation(
            .easeOut(duration: duration),
            completionCriteria: .logicallyComplete
        ) {
            dragAngle = 0
            onSelect(patterns[index].id)
        } completion: {
            guard generation == interactionGeneration, !isDragging else { return }

            withAnimation(.linear(duration: 0.02)) {
                isRotating = false
            }
        }
    }

    private func point(radius: CGFloat, angle: Double) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: pivot.x + cos(radians) * radius,
            y: pivot.y + sin(radians) * radius
        )
    }

    private func displayName(for pattern: StrumPattern) -> String {
        pattern.name.uppercased().replacingOccurrences(of: " STRUM", with: "\nSTRUM")
    }

    private func patternNameLines(for pattern: StrumPattern) -> [String] {
        displayName(for: pattern).components(separatedBy: "\n")
    }
}

#Preview {
    PatternWheelView(
        patterns: PatternCatalog.all,
        selectedPatternID: "subdivision",
        onSelect: { _ in }
    )
    .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
    .background(AppColors.brownPrimary)
}
