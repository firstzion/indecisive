import SwiftUI

/// The mist that drifts through Crystal Ball's reveal: two soft white bands, low in the ball,
/// sliding to and fro behind the name. The mockup's `pfm-mist` keyframes, as a function of time:
///
///     0%    translateX(-14px)  scaleY(1)     opacity .5
///     50%   translateX(14px)   scaleY(1.15)  opacity .9
///     100%  translateX(-14px)  scaleY(1)     opacity .5
enum MistMotion {
    /// One band of mist, in the ball's own coordinates.
    struct Band: Equatable {
        /// Where its top edge sits, as a fraction of the ball's height.
        let top: CGFloat
        let height: CGFloat
        /// How white it is at its densest, before the drift dims it.
        let alpha: Double
        /// Seconds for one full drift there and back.
        let period: Double
        /// How far round its loop it starts, seconds (the mockup's `animation-delay`).
        let phaseOffset: Double
    }

    /// The mockup's two bands: 34pt at 52 % down the ball, and 26pt at 70 %.
    static let bands: [Band] = [
        Band(top: 0.52, height: 34, alpha: 0.28, period: 5, phaseOffset: 0),
        Band(top: 0.70, height: 26, alpha: 0.20, period: 6.4, phaseOffset: 1),
    ]

    /// The mockup blurs each band by this much (`filter: blur(7px)`, a standard deviation).
    static let blur: CGFloat = 7

    struct Pose: Equatable {
        let offsetX: CGFloat
        let scaleY: CGFloat
        let opacity: Double
    }

    static func pose(of band: Band, at elapsed: Double) -> Pose {
        let swing = Swing.value(at: elapsed, period: band.period, phaseOffset: band.phaseOffset)
        return Pose(
            offsetX: -14 + 28 * CGFloat(swing),
            scaleY: 1 + 0.15 * CGFloat(swing),
            opacity: 0.5 + 0.4 * swing
        )
    }

    /// How tall the painted rectangle is: the band plus three standard deviations of blur above
    /// and below, past which a Gaussian is too faint to see.
    static func paintedHeight(of band: Band) -> CGFloat {
        band.height + 6 * blur
    }

    /// The band's vertical profile, top to bottom of its painted rectangle: the band as a box of
    /// `alpha`-white, blurred by a Gaussian of standard deviation `blur`.
    ///
    /// SwiftUI's `.blur` would do this, but the snapshot renderer doesn't draw it — a blurred
    /// band showed there as a hard-edged slab while the device looked right — so the blur is a
    /// gradient instead. Blurring a box gives, at distance `y` below its top edge, the share of
    /// the Gaussian that falls inside the box: `½ (erf(y/σ√2) + erf((h − y)/σ√2))`.
    static func profile(of band: Band) -> [Gradient.Stop] {
        let sigma = Double(blur)
        let height = Double(band.height)
        let margin = 3 * sigma
        let steps = 16
        return (0...steps).map { step in
            let location = Double(step) / Double(steps)
            let y = location * (height + 2 * margin) - margin
            let covered = 0.5 * (erf(y / (sigma * 2.0.squareRoot())) + erf((height - y) / (sigma * 2.0.squareRoot())))
            return Gradient.Stop(color: .white.opacity(band.alpha * covered), location: location)
        }
    }
}

/// Crystal Ball's reveal centrepiece: a glowing ball on a gold stand, mist drifting through it and
/// the winner's name inside. Laid out at the mockup's 256 × 276. The name is the ball's own — as
/// the 8-Ball's is — and `nameVisible` fades it in once the mist has parted; the caller animates
/// that, so the same view is the veiled ball, the answered one, or anything between.
struct CrystalBallOnStand: View {
    let skin: Skin
    let winnerName: String
    let nameVisible: Bool

    @Environment(\.indReducedMotion) private var reduceMotion
    /// When the mist began to drift; each band's place is a function of the time since.
    @State private var start = Date()
    /// Bagel Fat One's natural line is 1.448 em; the mockup sets the name at `line-height: 1.12`.
    /// This closes the difference, so a name on two or three lines is as tightly stacked as the
    /// mockup's, and the block still centres in the ball the same way.
    @ScaledMetric(relativeTo: .largeTitle) private var nameLineSpacing: CGFloat = -9.8

    private static let diameter: CGFloat = 240

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Painted in the mockup's order: the stand, then its base bar, then the ball over both.
            Pedestal()
                .fill(skin.palette.accent)
                .frame(width: 116, height: 44)
                .offset(x: 70, y: 232)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(CrystalPaint.standBar)
                .frame(width: 126, height: 14)
                .offset(x: 65, y: 226)
            ball
                .frame(width: Self.diameter, height: Self.diameter)
                .offset(x: 8, y: 0)
        }
        .frame(width: 256, height: 276, alignment: .topLeading)
    }

    private var ball: some View {
        let d = Self.diameter
        return ZStack {
            Circle().fill(
                cssRadialGradient(
                    stops: [
                        .init(color: CrystalPaint.pink, location: 0),
                        .init(color: CrystalPaint.ballMid, location: 0.66),
                        .init(color: CrystalPaint.ballRim, location: 1),
                    ],
                    centre: UnitPoint(x: 0.62, y: 0.74),
                    in: d
                )
            )
            Circle().fill(
                cssRadialGradient(
                    stops: [
                        .init(color: .white.opacity(0.55), location: 0),
                        .init(color: .white.opacity(0), location: 0.46),
                    ],
                    centre: UnitPoint(x: 0.34, y: 0.26),
                    in: d
                )
            )
            mist
            name
        }
        .frame(width: d, height: d)
        .background {
            // The mockup's `0 0 56px -8px` halo: the ball's outline pulled in 8pt, then blurred.
            // A SwiftUI shadow's radius is half a CSS blur radius.
            Circle()
                .fill(CrystalPaint.pink)
                .padding(8)
                .shadow(color: CrystalPaint.pink.opacity(0.75), radius: 28)
        }
    }

    private var mist: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let elapsed = reduceMotion ? 0 : timeline.date.timeIntervalSince(start)
            ZStack {
                ForEach(MistMotion.bands.indices, id: \.self) { index in
                    let band = MistMotion.bands[index]
                    let pose = MistMotion.pose(of: band, at: elapsed)
                    Rectangle()
                        .fill(LinearGradient(stops: MistMotion.profile(of: band), startPoint: .top, endPoint: .bottom))
                        // 140 % of the ball's width, so the drift never shows an end.
                        .frame(width: Self.diameter * 1.4, height: MistMotion.paintedHeight(of: band))
                        .scaleEffect(x: 1, y: pose.scaleY)
                        .opacity(pose.opacity)
                        .offset(x: pose.offsetX, y: band.top * Self.diameter + band.height / 2 - Self.diameter / 2)
                }
            }
        }
        // The frame first: a `Circle` clips to a circle sized to *its view*, and the bands alone
        // are 336 wide and under 80 tall — which clipped them to a small disc in the middle.
        .frame(width: Self.diameter, height: Self.diameter)
        .clipShape(Circle())
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var name: some View {
        Text(winnerName)
            .font(skin.type.display(30))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(nameLineSpacing)
            .minimumScaleFactor(0.5)
            .lineLimit(3)
            .frame(width: 196)
            // The mockup's `0 2px 14px` plum halo, which keeps the white legible over the pink.
            .shadow(color: CrystalPaint.ballRim.opacity(0.85), radius: 7, x: 0, y: 2)
            .opacity(nameVisible ? 1 : 0)
    }
}

/// The stand's triangle: apex at the top, base along the bottom.
private struct Pedestal: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
