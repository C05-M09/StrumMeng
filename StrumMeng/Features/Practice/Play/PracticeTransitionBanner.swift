import SwiftUI

/// Full-screen arcade transition banner shown immediately after a Practice Play session finishes:
/// - "PURRFECT!" (`Showtime_Box`) + full celebratory confetti & star explosion for accuracy >= 85%
/// - "GETTING THERE!" (`Replay_Box`) + warm sparkle & confetti burst for accuracy >= 65%
/// - "NICE TRY" (`Retry_Box`) + comic impact shake & puff particles for accuracy < 65%
struct PracticeTransitionBanner: View {
    let result: SessionResult

    @State private var bannerEntered: Bool = false
    @State private var textEntered: Bool = false
    @State private var badgeEntered: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var impactShake: CGFloat = 0
    @State private var startTime: Date = .now

    fileprivate enum Tier {
        case purrfect
        case gettingThere
        case niceTry
    }

    private var tier: Tier {
        if result.accuracy >= 0.85 {
            return .purrfect
        } else if result.accuracy >= 0.65 {
            return .gettingThere
        } else {
            return .niceTry
        }
    }

    private var bannerText: String {
        switch tier {
        case .purrfect: return "PURRFECT!"
        case .gettingThere: return "GETTING THERE!"
        case .niceTry: return "NICE TRY"
        }
    }

    private var boxAssetName: String {
        switch tier {
        case .purrfect: return "Showtime_Box"
        case .gettingThere: return "Replay_Box"
        case .niceTry: return "Retry_Box"
        }
    }

    private var fontSize: CGFloat {
        switch tier {
        case .purrfect: return 108
        case .gettingThere: return 88
        case .niceTry: return 108
        }
    }

    private var accuracyPercent: Int {
        Int((result.accuracy * 100).rounded())
    }

    private var particles: [ConfettiParticle] {
        ConfettiParticle.generate(for: tier)
    }

    var body: some View {
        GeometryReader { proxy in
            let sx = proxy.size.width / AppLayout.referenceSize.width
            let sy = proxy.size.height / AppLayout.referenceSize.height

            ZStack {
                // 1. Semi-transparent dark comic dim layer
                AppColor.dim.opacity(bannerEntered ? 0.62 : 0.0)
                    .ignoresSafeArea()

                // 2. Main banner canvas scaled to reference size (1376 x 1032)
                ZStack {
                    // Radial comic burst rays for PURRFECT tier
                    if tier == .purrfect && bannerEntered {
                        ComicBurstRays()
                            .position(
                                x: AppLayout.referenceSize.width / 2,
                                y: AppLayout.referenceSize.height / 2
                            )
                            .transition(.opacity)
                    }

                    // Angled comic slash banner (Showtime_Box / Replay_Box / Retry_Box)
                    Image(boxAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 1680)
                        .shadow(color: AppColors.brownInk.opacity(0.55), radius: 0, x: 0, y: 14)
                        .position(
                            x: AppLayout.referenceSize.width / 2,
                            y: AppLayout.referenceSize.height / 2
                        )
                        .offset(
                            x: (bannerEntered ? 0 : AppLayout.referenceSize.width + 400) + impactShake
                        )

                    // Center content stack rotated to match the +4.02° clockwise slant of the banner
                    VStack(spacing: 14) {
                        // Outlined comic headline text
                        OutlinedText(
                            text: bannerText,
                            font: AppTypography.bungee(size: fontSize),
                            foregroundColor: AppColors.white,
                            outlineColor: AppColors.brownInk,
                            outlineWidth: 6,
                            shadowColor: AppColors.brownInk,
                            shadowOffset: CGSize(width: 0, height: 8),
                            alignment: .center
                        )
                        .scaleEffect(textEntered ? pulseScale : 0.25)
                        .opacity(textEntered ? 1.0 : 0.0)

                        // Accuracy pill badge
                        HStack(spacing: 10) {
                            Text("ACCURACY")
                                .font(AppTypography.dmMono(size: 24))
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.cream)

                            Text("\(accuracyPercent)%")
                                .font(AppTypography.bungee(size: 30))
                                .foregroundStyle(AppColors.yellowAccent)
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(AppColors.brownInk)
                                .shadow(color: AppColors.brownInk.opacity(0.4), radius: 0, x: 0, y: 4)
                        )
                        .overlay(
                            Capsule()
                                .stroke(AppColors.cream, lineWidth: 3)
                        )
                        .scaleEffect(badgeEntered ? 1.0 : 0.2)
                        .opacity(badgeEntered ? 1.0 : 0.0)
                    }
                    .rotationEffect(.degrees(4.02))
                    .offset(x: impactShake, y: -6)
                    .position(
                        x: AppLayout.referenceSize.width / 2,
                        y: AppLayout.referenceSize.height / 2
                    )

                    // 3. Accuracy-driven Confetti / Sparkle / Puff Particle Layer
                    ConfettiCanvasView(particles: particles, startTime: startTime)
                        .frame(
                            width: AppLayout.referenceSize.width,
                            height: AppLayout.referenceSize.height
                        )
                }
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
        .allowsHitTesting(false)
        .onAppear {
            startTime = .now
            triggerEntranceAnimation()
        }
    }

    private func triggerEntranceAnimation() {
        // Step 1: Comic slash banner slashes in from right to left
        withAnimation(.spring(response: 0.40, dampingFraction: 0.74)) {
            bannerEntered = true
        }

        // Step 2: Headline text pops in with comic bounce
        withAnimation(.spring(response: 0.36, dampingFraction: 0.58).delay(0.10)) {
            textEntered = true
        }

        // Step 3: Stars and Accuracy pill pop in
        withAnimation(.spring(response: 0.38, dampingFraction: 0.65).delay(0.20)) {
            badgeEntered = true
        }

        // Step 4: Tier-specific secondary motion (heartbeat pulse vs comic impact shake)
        if tier == .purrfect || tier == .gettingThere {
            withAnimation(
                .easeInOut(duration: 0.45)
                .repeatForever(autoreverses: true)
                .delay(0.45)
            ) {
                pulseScale = 1.05
            }
        } else {
            // Subtle comic shake on impact for Nice Try
            Task {
                try? await Task.sleep(for: .milliseconds(180))
                for offset in [CGFloat(-14), 12, -8, 6, 0] {
                    withAnimation(.linear(duration: 0.045)) {
                        impactShake = offset
                    }
                    try? await Task.sleep(for: .milliseconds(45))
                }
            }
        }
    }
}

// MARK: - Rotating Comic Sunburst (Purrfect Tier)
private struct ComicBurstRays: View {
    @State private var angle: Double = 0

    var body: some View {
        Image("Effect_Sunburst")
            .resizable()
            .scaledToFit()
            .frame(width: 1750, height: 1750)
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

// MARK: - Particle Physics Model & Canvas
private struct ConfettiParticle {
    enum ShapeKind {
        case ribbon
        case diamond
        case circle
        case drop
    }

    let x0: CGFloat
    let y0: CGFloat
    let vx: CGFloat
    let vy: CGFloat
    let gravity: CGFloat
    let size: CGFloat
    let color: Color
    let shape: ShapeKind
    let spinSpeed: Double
    let initialAngle: Double
    let delay: Double

    static func generate(for tier: PracticeTransitionBanner.Tier) -> [ConfettiParticle] {
        let centerX = AppLayout.referenceSize.width / 2
        let centerY = AppLayout.referenceSize.height / 2

        switch tier {
        case .purrfect:
            let palette: [Color] = [
                AppColors.yellowAccent,
                AppColors.teal,
                AppColors.orange,
                AppColors.redAccent,
                AppColors.white,
                AppColors.cream
            ]
            let shapes: [ShapeKind] = [.ribbon, .diamond, .ribbon, .circle]
            return (0..<72).map { i in
                let seed = Double(i)
                // Burst in all directions + side cannons
                let angle = (seed * 137.5).truncatingRemainder(dividingBy: 360) * .pi / 180
                let speed = 380 + CGFloat((i * 53) % 520)
                let spreadX = CGFloat(((i * 97) % 700) - 350)
                return ConfettiParticle(
                    x0: centerX + spreadX * 0.5,
                    y0: centerY + CGFloat(((i * 31) % 120) - 60),
                    vx: cos(angle) * speed,
                    vy: -abs(sin(angle)) * speed - 220,
                    gravity: 560,
                    size: 16 + CGFloat((i * 19) % 18),
                    color: palette[i % palette.count],
                    shape: shapes[i % shapes.count],
                    spinSpeed: Double((i % 2 == 0 ? 1 : -1) * (180 + (i * 41) % 240)),
                    initialAngle: Double((i * 67) % 360),
                    delay: Double(i % 6) * 0.025
                )
            }

        case .gettingThere:
            let palette: [Color] = [
                AppColors.yellowAccent,
                AppColors.orange,
                AppColors.cream,
                AppColors.teal
            ]
            let shapes: [ShapeKind] = [.diamond, .ribbon, .circle]
            return (0..<38).map { i in
                let seed = Double(i)
                let angle = (seed * 137.5).truncatingRemainder(dividingBy: 360) * .pi / 180
                let speed = 260 + CGFloat((i * 47) % 360)
                let spreadX = CGFloat(((i * 83) % 600) - 300)
                return ConfettiParticle(
                    x0: centerX + spreadX * 0.5,
                    y0: centerY + CGFloat(((i * 29) % 100) - 50),
                    vx: cos(angle) * speed,
                    vy: -abs(sin(angle)) * speed - 140,
                    gravity: 460,
                    size: 14 + CGFloat((i * 17) % 14),
                    color: palette[i % palette.count],
                    shape: shapes[i % shapes.count],
                    spinSpeed: Double((i % 2 == 0 ? 1 : -1) * (120 + (i * 37) % 180)),
                    initialAngle: Double((i * 59) % 360),
                    delay: Double(i % 5) * 0.03
                )
            }

        case .niceTry:
            // Subtle comic sweat drops & impact puffs drifting outward
            let palette: [Color] = [
                AppColors.cream,
                AppColors.tan,
                AppColors.redAccent
            ]
            let shapes: [ShapeKind] = [.drop, .circle, .diamond]
            return (0..<18).map { i in
                let side: CGFloat = (i % 2 == 0) ? -1 : 1
                let speedX = side * (120 + CGFloat((i * 43) % 220))
                let speedY = -80 - CGFloat((i * 37) % 160)
                return ConfettiParticle(
                    x0: centerX + side * CGFloat(180 + (i * 29) % 240),
                    y0: centerY + CGFloat(((i * 23) % 140) - 70),
                    vx: speedX,
                    vy: speedY,
                    gravity: 420,
                    size: 12 + CGFloat((i * 13) % 10),
                    color: palette[i % palette.count],
                    shape: shapes[i % shapes.count],
                    spinSpeed: Double(side * 90),
                    initialAngle: Double((i * 45) % 360),
                    delay: 0.08 + Double(i % 4) * 0.04
                )
            }
        }
    }
}

private struct ConfettiCanvasView: View {
    let particles: [ConfettiParticle]
    let startTime: Date

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)
            Canvas { context, _ in
                for particle in particles {
                    let t = elapsed - particle.delay
                    guard t > 0 else { continue }

                    let dt = CGFloat(t)
                    let drag = max(0.25, 1.0 - dt * 0.30)
                    let x = particle.x0 + particle.vx * dt * drag
                    let y = particle.y0 + particle.vy * dt + 0.5 * particle.gravity * dt * dt
                    let fade = max(0.0, min(1.0, 1.0 - (t - 1.95) / 0.85))
                    guard fade > 0 else { continue }

                    let angle = Angle.degrees(particle.initialAngle + particle.spinSpeed * t)
                    let tumble = CGFloat(0.45 + 0.55 * abs(cos(t * 5.0 + Double(particle.size))))

                    var local = context
                    local.opacity = fade
                    local.translateBy(x: x, y: y)
                    local.rotate(by: angle)
                    local.scaleBy(x: 1.0, y: tumble)

                    let s = particle.size
                    let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                    let path = Self.path(for: particle.shape, in: rect)

                    local.fill(path, with: .color(particle.color))
                    local.stroke(path, with: .color(AppColors.brownInk), lineWidth: 2.2)
                }
            }
        }
    }

    private static func path(for shape: ConfettiParticle.ShapeKind, in rect: CGRect) -> Path {
        switch shape {
        case .ribbon:
            let r = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.2, width: rect.width, height: rect.height * 0.6)
            return Path(roundedRect: r, cornerRadius: 3)

        case .circle, .drop:
            return Path(ellipseIn: rect)

        case .diamond:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
            return path
        }
    }
}

#if DEBUG
#Preview("Purrfect", traits: .landscapeLeft) {
    let result = SessionResult(
        id: UUID(), patternID: "foundation", songID: nil, bpm: 80, accuracy: 0.95,
        perfectCount: 9, tooEarlyCount: 1, missCount: 0,
        createdAt: .now, beatEvents: []
    )
    PracticeTransitionBanner(result: result)
}

#Preview("Getting There", traits: .landscapeLeft) {
    let result = SessionResult(
        id: UUID(), patternID: "foundation", songID: nil, bpm: 80, accuracy: 0.75,
        perfectCount: 7, tooEarlyCount: 2, missCount: 1,
        createdAt: .now, beatEvents: []
    )
    PracticeTransitionBanner(result: result)
}

#Preview("Nice Try", traits: .landscapeLeft) {
    let result = SessionResult(
        id: UUID(), patternID: "foundation", songID: nil, bpm: 80, accuracy: 0.40,
        perfectCount: 4, tooEarlyCount: 2, missCount: 4,
        createdAt: .now, beatEvents: []
    )
    PracticeTransitionBanner(result: result)
}
#endif
