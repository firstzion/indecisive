import SwiftUI

/// Falling confetti behind the reveal screen — the mockup's `pfm-fall`. Each piece
/// drops from just above the top edge to just below the bottom, spinning about its
/// own centre and fading in, then out, on the way; then it starts over from the top.
/// Colours, corner radius and outline are the skin's own (`skin.reveal.confetti`). A skin whose
/// confetti `motion` is `.twinkling` gets its stars (`Twinkles`) here instead of any of this.
///
/// Where a piece is at any moment is a pure function of the clock
/// (`ConfettiMotion.pose(of:at:containerHeight:)`), drawn by `ConfettiField` — it isn't
/// a SwiftUI animation. That is deliberate. It used to be one (`.offset(y:)` and then
/// `.rotationEffect(_:)` under a `repeatForever`), and the order was wrong: modifiers
/// apply in sequence, so the rotation turned the already-offset piece about the point it
/// started from, and every piece spiralled off the screen within a fraction of a second
/// instead of falling. That left the shower nearly invisible, and nothing could catch it:
/// the confetti is hidden under Reduce Motion, which is how the snapshot tests run, and an
/// implicit animation can't be inspected. A pure function can, and `ConfettiTests` does.
///
/// Pieces are generated once into `@State` rather than recomputed in `body` — a computed
/// property re-randomizing on every redraw would make the whole shower jitter.
struct Confetti: View {
    let skin: Skin
    @State private var pieces: [Piece] = []
    /// When this shower began; every piece's position is a function of the time since.
    @State private var start = Date()
    @Environment(\.indReducedMotion) private var reduceMotion

    struct Piece: Identifiable {
        let id = UUID()
        let xFraction: CGFloat
        let size: CGFloat
        let isRound: Bool
        let color: Color
        /// How long one fall takes, seconds.
        let duration: Double
        /// How long after the shower begins this piece first sets off. Applies to the
        /// first fall only, as a CSS `animation-delay` does — later falls follow straight on.
        let delay: Double
    }

    var body: some View {
        switch skin.reveal.confetti.motion {
        case .falling: falling
        case .twinkling: Twinkles(style: skin.reveal.confetti)
        }
    }

    @ViewBuilder
    private var falling: some View {
        // Purely decorative, endlessly-repeating motion — exactly what
        // Reduce Motion asks apps to cut. No static fallback either: a
        // frozen field of confetti mid-fall doesn't read as "confetti".
        if !reduceMotion {
            GeometryReader { proxy in
                TimelineView(.animation) { timeline in
                    ConfettiField(
                        pieces: pieces,
                        style: skin.reveal.confetti,
                        size: proxy.size,
                        elapsed: timeline.date.timeIntervalSince(start)
                    )
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                if pieces.isEmpty {
                    var generator = SystemRandomNumberGenerator()
                    pieces = Self.makePieces(for: skin, using: &generator)
                }
            }
        }
    }

    /// Ten pieces, one per column, each with its own size, fall time and start delay.
    /// Takes the generator so a test can seed it.
    static func makePieces(for skin: Skin, using generator: inout some RandomNumberGenerator) -> [Piece] {
        let colors = skin.reveal.confetti.colors
        // `colors[i % colors.count]` below would trap on an empty list.
        guard !colors.isEmpty else { return [] }
        var pieces: [Piece] = []
        for i in 0..<10 {
            let xFraction: CGFloat = CGFloat(i) / 10 + 0.03
            let size: CGFloat = CGFloat.random(in: 8...14, using: &generator)
            let isRound: Bool = i % 2 == 0
            let color: Color = colors[i % colors.count]
            let duration: Double = Double.random(in: 3.0...4.5, using: &generator)
            let delay: Double = Double(i) * 0.25
            let piece = Piece(
                xFraction: xFraction,
                size: size,
                isRound: isRound,
                color: color,
                duration: duration,
                delay: delay
            )
            pieces.append(piece)
        }
        return pieces
    }
}

/// The mockup's `pfm-fall` keyframes, as a function of time:
///
///     0%   translateY(-40px)   rotate(0)       opacity 0
///     15%                                      opacity 1
///     100% translateY(bottom)  rotate(520deg)  opacity 0
///
/// Pure, so tests can pin the path of a piece without rendering anything.
enum ConfettiMotion {
    /// How far past the top and bottom edges a fall starts and ends, so a piece
    /// enters and leaves off screen.
    static let overscan: CGFloat = 40
    /// A piece fades in over this share of its fall, and out over the rest.
    static let fadeInFraction = 0.15
    /// Total spin over one fall.
    static let spinDegrees = 520.0

    struct Pose: Equatable {
        /// Distance of the piece's centre below the top edge; negative is above the screen.
        let y: CGFloat
        let degrees: Double
        let opacity: Double
    }

    /// Where `piece` is `elapsed` seconds after the shower began, in a container
    /// `containerHeight` tall — or `nil` before its turn to set off.
    static func pose(of piece: Confetti.Piece, at elapsed: Double, containerHeight: CGFloat) -> Pose? {
        guard elapsed >= piece.delay, piece.duration > 0 else { return nil }
        let phase = ((elapsed - piece.delay) / piece.duration).truncatingRemainder(dividingBy: 1)
        let opacity = phase < fadeInFraction
            ? phase / fadeInFraction
            : (1 - phase) / (1 - fadeInFraction)
        return Pose(
            y: -overscan + CGFloat(phase) * (containerHeight + 2 * overscan),
            degrees: spinDegrees * phase,
            opacity: opacity
        )
    }
}

/// The confetti at one instant: every piece placed by `ConfettiMotion`. Takes the time
/// as a plain number, so a test can render any moment.
struct ConfettiField: View {
    let pieces: [Confetti.Piece]
    let style: SkinRevealStyle.ConfettiStyle
    let size: CGSize
    let elapsed: Double

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                if let pose = ConfettiMotion.pose(of: piece, at: elapsed, containerHeight: size.height) {
                    ConfettiPieceView(style: style, piece: piece)
                        // Spin first, then place: the spin is about the piece's own centre.
                        // Rotating after an offset swings it round where it started (see `Confetti`).
                        .rotationEffect(.degrees(pose.degrees))
                        .opacity(pose.opacity)
                        .position(x: piece.xFraction * size.width, y: pose.y)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct ConfettiPieceView: View {
    let style: SkinRevealStyle.ConfettiStyle
    let piece: Confetti.Piece

    var body: some View {
        pieceShape
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * (piece.isRound ? 1 : 1.6))
            .overlay {
                if let outline = style.outline {
                    pieceShape.stroke(outline, lineWidth: 2)
                }
            }
    }

    private var pieceShape: AnyShape {
        if piece.isRound {
            return AnyShape(Circle())
        }
        return AnyShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
}
