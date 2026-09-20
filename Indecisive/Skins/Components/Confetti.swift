import SwiftUI

/// Falling confetti overlay for the reveal screen. Shapes and colors match
/// each skin: tiny diamonds/dots for the 8-Ball and ink-outlined shapes for
/// the Wheel.
///
/// Pieces are generated once into `@State` rather than recomputed in `body`
/// — a computed property re-randomizing on every redraw would both jitter
/// visually and, worse, hand every piece a fresh `UUID` each time, which
/// resets its animation from scratch on every re-render.
struct Confetti: View {
    let skin: Skin
    @State private var pieces: [Piece] = []
    @Environment(\.indReducedMotion) private var reduceMotion

    struct Piece: Identifiable {
        let id = UUID()
        let xFraction: CGFloat
        let size: CGFloat
        let isRound: Bool
        let color: Color
        let duration: Double
        let delay: Double
    }

    var body: some View {
        // Purely decorative, endlessly-repeating motion — exactly what
        // Reduce Motion asks apps to cut. No static fallback either: a
        // frozen field of confetti mid-fall doesn't read as "confetti".
        if !reduceMotion {
            GeometryReader { proxy in
                ZStack {
                    ForEach(pieces) { piece in
                        ConfettiPieceView(style: skin.reveal.confetti, piece: piece, containerHeight: proxy.size.height)
                            .position(x: piece.xFraction * proxy.size.width, y: 0)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                if pieces.isEmpty { pieces = Self.makePieces(for: skin) }
            }
        }
    }

    private static func makePieces(for skin: Skin) -> [Piece] {
        let colors = skin.reveal.confetti.colors
        // `colors[i % colors.count]` below would trap on an empty list.
        guard !colors.isEmpty else { return [] }
        var pieces: [Piece] = []
        for i in 0..<10 {
            let xFraction: CGFloat = CGFloat(i) / 10 + 0.03
            let size: CGFloat = CGFloat.random(in: 8...14)
            let isRound: Bool = i % 2 == 0
            let color: Color = colors[i % colors.count]
            let duration: Double = Double.random(in: 3.0...4.5)
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

private struct ConfettiPieceView: View {
    let style: SkinRevealStyle.ConfettiStyle
    let piece: Confetti.Piece
    let containerHeight: CGFloat
    @State private var fallen = false

    var body: some View {
        pieceShape
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * (piece.isRound ? 1 : 1.6))
            .overlay {
                if let outline = style.outline {
                    pieceShape.stroke(outline, lineWidth: 2)
                }
            }
            .opacity(fallen ? 0 : 1)
            .offset(y: fallen ? containerHeight + 40 : -40)
            .rotationEffect(.degrees(fallen ? 520 : 0))
            .onAppear {
                withAnimation(.linear(duration: piece.duration).delay(piece.delay).repeatForever(autoreverses: false)) {
                    fallen = true
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
