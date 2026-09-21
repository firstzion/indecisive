import XCTest
import SwiftUI
@testable import IndecisiveKit

/// The confetti's motion — what the snapshot tests can't see (Reduce Motion hides the
/// confetti entirely) and what an implicit animation wouldn't let a test inspect. Its
/// pieces used to spiral off the screen within a fraction of a second instead of falling
/// (`.rotationEffect` applied after `.offset`, so the spin swung each piece round the point
/// it started from), and nothing noticed: these tests are what would have.
@MainActor
final class ConfettiTests: XCTestCase {

    private let height: CGFloat = 800
    private let style = SkinRevealStyle.ConfettiStyle(motion: .falling, colors: [.red], cornerRadius: 3, outline: nil)

    private func piece(
        x: CGFloat = 0.3, size: CGFloat = 12, round: Bool = true, duration: Double = 4, delay: Double = 1
    ) -> Confetti.Piece {
        Confetti.Piece(xFraction: x, size: size, isRound: round, color: .red, duration: duration, delay: delay)
    }

    private func pose(_ piece: Confetti.Piece, _ elapsed: Double) throws -> ConfettiMotion.Pose {
        try XCTUnwrap(ConfettiMotion.pose(of: piece, at: elapsed, containerHeight: height), "no pose at \(elapsed)s")
    }

    // MARK: The path of one piece (the mockup's `pfm-fall`)

    func testAPieceWaitsForItsDelayBeforeSettingOff() {
        let p = piece(delay: 1)
        XCTAssertNil(ConfettiMotion.pose(of: p, at: 0, containerHeight: height))
        XCTAssertNil(ConfettiMotion.pose(of: p, at: 0.99, containerHeight: height))
        XCTAssertNotNil(ConfettiMotion.pose(of: p, at: 1, containerHeight: height))
    }

    func testAFallRunsFromAboveTheTopEdgeToBelowTheBottomOne() throws {
        let p = piece(duration: 4, delay: 0)
        XCTAssertEqual(try pose(p, 0).y, -40, accuracy: 1e-9, "starts above the screen")
        XCTAssertEqual(try pose(p, 2).y, height / 2, accuracy: 1e-9, "halfway through, halfway down")
        XCTAssertEqual(try pose(p, 3.999).y, height + 40, accuracy: 1, "ends below the screen")
    }

    func testAPieceNeverMovesUpDuringAFall() throws {
        let p = piece(duration: 4, delay: 0)
        var last = -Double.infinity
        for step in 0..<200 {
            let y = Double(try pose(p, Double(step) / 200 * 3.99).y)
            XCTAssertGreaterThan(y, last, "went back up at step \(step)")
            last = y
        }
    }

    func testAPieceFadesInThenOutAndSpinsOnTheWayDown() throws {
        let p = piece(duration: 4, delay: 0)
        XCTAssertEqual(try pose(p, 0).opacity, 0, accuracy: 1e-9)
        XCTAssertEqual(try pose(p, 0.15 * 4).opacity, 1, accuracy: 1e-9, "fully in by 15 % of the fall")
        XCTAssertEqual(try pose(p, 0.575 * 4).opacity, 0.5, accuracy: 1e-9, "fading out linearly after that")
        XCTAssertEqual(try pose(p, 3.999).opacity, 0, accuracy: 0.01)
        XCTAssertEqual(try pose(p, 0).degrees, 0, accuracy: 1e-9)
        XCTAssertEqual(try pose(p, 2).degrees, 260, accuracy: 1e-9)
        XCTAssertEqual(try pose(p, 3.999).degrees, 520, accuracy: 0.5)
    }

    func testLaterFallsFollowStraightOnWithoutWaitingAgain() throws {
        // A CSS `animation-delay` applies to the first pass only. The SwiftUI animation this
        // replaced (`.delay(_:).repeatForever()`) repeated it every cycle, leaving each piece
        // out of sight for `delay` seconds between falls.
        let p = piece(duration: 4, delay: 2)
        XCTAssertEqual(try pose(p, 2 + 1), try pose(p, 2 + 4 + 1), "the second fall repeats the first")
        XCTAssertEqual(try pose(p, 2 + 4).y, -40, accuracy: 1e-9, "the next fall starts the instant the last ends")
    }

    // MARK: The whole shower

    func testTenPiecesOnePerColumnEachSettingOffInTurn() {
        var generator = SeededGenerator(seed: 1)
        let pieces = Confetti.makePieces(for: .gashapon, using: &generator)
        XCTAssertEqual(pieces.count, 10)
        XCTAssertEqual(pieces.map(\.xFraction), (0..<10).map { CGFloat($0) / 10 + 0.03 })
        XCTAssertEqual(pieces.map(\.delay), (0..<10).map { Double($0) * 0.25 })
        XCTAssertTrue(pieces.allSatisfy { (3.0...4.5).contains($0.duration) && (8...14).contains($0.size) })
    }

    /// "It doesn't really fall across the screen": at the worst, one piece in a handful was
    /// on screen at all, nearly all of them within the top few dozen points.
    func testTheShowerCoversTheWholeScreenAtEveryMoment() {
        // Only a skin whose confetti falls has a shower: Crystal Ball's stars twinkle in place
        // (below).
        for skin in Skin.all where skin.reveal.confetti.motion == .falling {
            var generator = SeededGenerator(seed: 7)
            let pieces = Confetti.makePieces(for: skin, using: &generator)
            var perFifth = [Double](repeating: 0, count: 5)
            var samples = 0.0
            var time = 6.0  // by 2.25s every piece has set off
            while time <= 30 {
                let visible =
                    pieces
                    .compactMap { ConfettiMotion.pose(of: $0, at: time, containerHeight: height) }
                    .filter { $0.y >= 0 && $0.y <= height && $0.opacity >= 0.15 }
                XCTAssertGreaterThanOrEqual(visible.count, 5, "\(skin.name): only \(visible.count) pieces visible at \(time)s")
                for pose in visible { perFifth[min(4, Int(pose.y / height * 5))] += 1 }
                samples += 1
                time += 0.25
            }
            for (fifth, total) in perFifth.enumerated() {
                XCTAssertGreaterThan(
                    total / samples, 0.5,
                    "\(skin.name): fifth \(fifth + 1) of the screen (top to bottom) is nearly always empty"
                )
            }
        }
    }

    // MARK: What is actually drawn

    /// The middle of the bounding box of everything drawn (anything with a whisker of alpha),
    /// or `nil` if nothing was.
    private func drawnCentre(of field: ConfettiField) throws -> CGPoint? {
        let renderer = ImageRenderer(content: field)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        let width = image.width
        let rows = image.height
        var pixels = [UInt8](repeating: 0, count: width * rows * 4)
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels, width: width, height: rows, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: rows))
        var minX = width
        var maxX = -1
        var minY = rows
        var maxY = -1
        for y in 0..<rows {
            for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 12 {
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
            }
        }
        guard maxX >= 0 else { return nil }
        return CGPoint(x: Double(minX + maxX + 1) / 2, y: Double(minY + maxY + 1) / 2)
    }

    /// The bug itself: a piece has to come out of the view straight below its own column, at
    /// the height `ConfettiMotion` says — however far through its spin it is. Rotating after
    /// offsetting put it on a spiral round the top of the screen instead (at a quarter of the
    /// way down it was drawn *above* the screen).
    func testAPieceIsDrawnStraightBelowItsColumnNotSwungRoundIt() throws {
        let size = CGSize(width: 400, height: height)
        for isRound in [true, false] {
            let p = piece(x: 0.3, size: 14, round: isRound, duration: 4, delay: 0)
            for phase in [0.2, 0.35, 0.5, 0.65, 0.8] {
                let elapsed = phase * 4
                let expectedY = try pose(p, elapsed).y
                let field = ConfettiField(pieces: [p], style: style, size: size, elapsed: elapsed)
                let centre = try XCTUnwrap(
                    try drawnCentre(of: field),
                    "\(isRound ? "round" : "rectangular") piece nowhere on screen \(Int(phase * 100)) % of the way through its fall"
                )
                XCTAssertEqual(centre.x, 0.3 * size.width, accuracy: 2, "drifted sideways at \(Int(phase * 100)) %")
                XCTAssertEqual(centre.y, expectedY, accuracy: 2, "wrong height at \(Int(phase * 100)) %")
            }
        }
    }

    func testAPieceThatHasNotSetOffIsNotDrawn() throws {
        // A second piece that *is* falling keeps the render from being empty: `ImageRenderer` can
        // hand back the previous render's pixels when there is nothing at all to draw.
        let size = CGSize(width: 400, height: height)
        let waiting = piece(x: 0.3, delay: 1)
        let falling = piece(x: 0.7, delay: 0)
        let field = ConfettiField(pieces: [waiting, falling], style: style, size: size, elapsed: 0.5)
        let centre = try XCTUnwrap(try drawnCentre(of: field))
        XCTAssertEqual(centre.x, 0.7 * size.width, accuracy: 2, "the piece that hasn't set off was drawn too")
    }
}
