import XCTest
import SwiftUI
@testable import IndecisiveKit

/// Crystal Ball's moving parts — the twinkling stars and the drifting mist — and where they
/// are actually drawn. The snapshots run under Reduce Motion, which freezes both at their first
/// instant, so nothing else would notice one of them going wrong in motion; and, like the falling
/// confetti, they are pure functions of the clock precisely so a test can ask.
@MainActor
final class TwinkleTests: XCTestCase {

    private func alpha(of color: Color) -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(a)
    }

    // MARK: The clock (`Swing`)

    func testASwingIsZeroAtTheStartOneHalfwayAndZeroAgainAtTheEnd() {
        XCTAssertEqual(Swing.value(at: 0, period: 4), 0, accuracy: 1e-9)
        XCTAssertEqual(Swing.value(at: 2, period: 4), 1, accuracy: 1e-9)
        XCTAssertEqual(Swing.value(at: 4, period: 4), 0, accuracy: 1e-9)
    }

    func testASwingEasesInAndOutInsteadOfMovingAtASteadyPace() {
        // A tenth of the way through the swelling half it has moved well under a tenth of the
        // way (an ease-in), and at its midpoint it is exactly half way.
        XCTAssertLessThan(Swing.value(at: 0.2, period: 4), 0.05)
        XCTAssertEqual(Swing.value(at: 1, period: 4), 0.5, accuracy: 1e-9)
        XCTAssertGreaterThan(Swing.value(at: 1.8, period: 4), 0.95)
    }

    func testASwingIsSymmetricalAndRepeatsEveryPeriod() {
        for step in 0...20 {
            let t = Double(step) / 20 * 4
            XCTAssertEqual(Swing.value(at: t, period: 4), Swing.value(at: 4 - t, period: 4), accuracy: 1e-9, "mirror at \(t)")
            XCTAssertEqual(Swing.value(at: t, period: 4), Swing.value(at: t + 12, period: 4), accuracy: 1e-9, "repeat at \(t)")
        }
    }

    func testAPhaseOffsetStartsALoopPartWayRoundRatherThanMakingItWait() {
        // The mockup's `animation-delay`s are used to put things out of step: an offset star is
        // already twinkling at once, not still at rest for a second or two.
        // An offset loop is simply that far ahead of an unoffset one. Checked at several moments,
        // not only the first: a swing mirrors itself about its start, so a sign slip (running the
        // loop behind instead of ahead) only shows at moments away from that.
        for t in [0, 0.5, 1.3, 2.2, 3.7] {
            XCTAssertEqual(
                Swing.value(at: t, period: 4, phaseOffset: 1), Swing.value(at: t + 1, period: 4),
                accuracy: 1e-9, "at \(t)s"
            )
        }
        XCTAssertGreaterThan(Swing.value(at: 0, period: 4, phaseOffset: 2), 0.99, "offset half a period: already at its peak")
    }

    func testASwingStaysBetweenZeroAndOne() {
        for step in 0..<400 {
            let value = Swing.value(at: Double(step) * 0.037, period: 2.6, phaseOffset: 0.7)
            XCTAssertTrue((0...1).contains(value), "\(value) at step \(step)")
        }
    }

    // MARK: A star (the mockup's `pfm-twinkle`)

    private let star = Twinkle(x: 0.3, y: 0.4, size: 10, duration: 4, phaseOffset: 0)

    func testAStarIsSmallAndDimAtTheStartOfItsLoopAndFullSizeAndBrightHalfwayThrough() {
        let start = TwinkleMotion.pose(of: star, at: 0)
        XCTAssertEqual(start.scale, 0.6, accuracy: 1e-9)
        XCTAssertEqual(start.opacity, 0.35, accuracy: 1e-9)
        let peak = TwinkleMotion.pose(of: star, at: 2)
        XCTAssertEqual(peak.scale, 1, accuracy: 1e-9)
        XCTAssertEqual(peak.opacity, 1, accuracy: 1e-9)
        XCTAssertEqual(TwinkleMotion.pose(of: star, at: 4).scale, 0.6, accuracy: 1e-9, "and round again")
    }

    func testAStarNeverShrinksBelowTheMockupsSmallestOrDimsBelowItsDimmest() {
        for step in 0..<400 {
            let pose = TwinkleMotion.pose(of: star, at: Double(step) * 0.05)
            XCTAssertGreaterThanOrEqual(pose.scale, 0.6 - 1e-9)
            XCTAssertLessThanOrEqual(pose.scale, 1 + 1e-9)
            XCTAssertGreaterThanOrEqual(pose.opacity, 0.35 - 1e-9)
            XCTAssertLessThanOrEqual(pose.opacity, 1 + 1e-9)
        }
    }

    func testTheConstellationIsTheMockupsSixStarsInTheMockupsPlaces() {
        let stars = TwinkleMotion.constellation
        XCTAssertEqual(stars.count, 6)
        XCTAssertEqual(stars.map(\.x), [0.11, 0.83, 0.22, 0.74, 0.47, 0.08])
        XCTAssertEqual(stars.map(\.y), [0.18, 0.22, 0.66, 0.60, 0.13, 0.44])
        XCTAssertEqual(stars.map(\.size), [9, 7, 8, 10, 7, 7])
        XCTAssertEqual(stars.map(\.duration), [2.1, 2.6, 2.4, 3.0, 2.8, 2.2])
        XCTAssertEqual(stars.map(\.phaseOffset), [0, 0.7, 1.2, 0.3, 1.6, 2.0])
    }

    func testNoStarEverHangsOffTheEdgeOfTheScreen() {
        for star in TwinkleMotion.constellation {
            // The 393 × 852 the mockups are drawn at.
            XCTAssertLessThanOrEqual(star.x * 393 + star.size, 393)
            XCTAssertLessThanOrEqual(star.y * 852 + star.size, 852)
            XCTAssertGreaterThanOrEqual(star.x * 393, 0)
            XCTAssertGreaterThanOrEqual(star.y * 852, 0)
        }
    }

    func testStarsAreOutOfStepWithOneAnotherAtTheStart() {
        // Otherwise they would all swell and fade together.
        let opacities = Set(TwinkleMotion.constellation.map { TwinkleMotion.pose(of: $0, at: 0).opacity })
        XCTAssertGreaterThan(opacities.count, 3, "the six stars should not all start in the same phase")
    }

    // MARK: The mist (the mockup's `pfm-mist`)

    func testAMistBandDriftsFromLeftToRightAndBack() {
        let band = MistMotion.bands[0]  // 5s, no offset
        let start = MistMotion.pose(of: band, at: 0)
        XCTAssertEqual(start.offsetX, -14, accuracy: 1e-9)
        XCTAssertEqual(start.scaleY, 1, accuracy: 1e-9)
        XCTAssertEqual(start.opacity, 0.5, accuracy: 1e-9)
        let mid = MistMotion.pose(of: band, at: 2.5)
        XCTAssertEqual(mid.offsetX, 14, accuracy: 1e-9)
        XCTAssertEqual(mid.scaleY, 1.15, accuracy: 1e-9)
        XCTAssertEqual(mid.opacity, 0.9, accuracy: 1e-9)
        XCTAssertEqual(MistMotion.pose(of: band, at: 5).offsetX, -14, accuracy: 1e-9, "and back")
    }

    func testTheMistIsTheMockupsTwoBandsLowInTheBall() {
        XCTAssertEqual(MistMotion.bands.count, 2)
        XCTAssertEqual(MistMotion.bands.map(\.height), [34, 26])
        XCTAssertEqual(MistMotion.bands.map(\.period), [5, 6.4])
        for band in MistMotion.bands {
            XCTAssertGreaterThan(band.top, 0.5, "the mist sits in the lower half, under the name")
            XCTAssertLessThan((band.top * 240) + band.height, 240, "and inside the 240pt ball")
        }
    }

    func testABlurredBandFadesOutSmoothlyAtBothEdgesAndPeaksAtItsMiddle() throws {
        for band in MistMotion.bands {
            let alphas = MistMotion.profile(of: band).map { alpha(of: $0.color) }
            XCTAssertEqual(alphas.first ?? 1, 0, accuracy: 0.002, "nothing left of the blur at the top")
            XCTAssertEqual(alphas.last ?? 1, 0, accuracy: 0.002, "nor at the bottom")
            for (up, down) in zip(alphas, alphas.reversed()) {
                XCTAssertEqual(up, down, accuracy: 1e-6, "a blurred box is the same either way up")
            }
            // A 34pt band blurred by 7pt stays within ~2 % of full strength at its middle (a
            // 26pt one is about 6 % short of it).
            let peak = try XCTUnwrap(alphas.max())
            XCTAssertEqual(peak, band.alpha, accuracy: band.alpha * 0.08, "the band's own alpha, near enough, at its densest")
            XCTAssertLessThanOrEqual(peak, band.alpha + 1e-9, "blurring never makes it denser than it was")
            XCTAssertEqual(MistMotion.paintedHeight(of: band), band.height + 42)
        }
    }

    // MARK: What is actually drawn

    /// The bounding box of everything drawn (anything with a whisker of alpha), in points, or
    /// `nil` if nothing was. Renders at scale 1, so pixels are points.
    private func drawnBounds<V: View>(of view: V) throws -> CGRect? {
        let renderer = ImageRenderer(content: view)
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
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    private let screen = CGSize(width: 400, height: 800)

    /// A star at full size and brightness (its loop's midpoint), and one at its smallest and dimmest.
    func testAStarIsDrawnCentredWhereItsPositionSaysAndSwellsAboutItsCentre() throws {
        let cases: [(elapsed: Double, scale: Double)] = [(2, 1), (0, 0.6)]  // `star` is 4s round
        for (elapsed, scale) in cases {
            let field = TwinkleField(stars: [star], colors: [.red], size: screen, elapsed: elapsed)
            let bounds = try XCTUnwrap(try drawnBounds(of: field), "nothing drawn at \(elapsed)s")
            let expectedCentre = CGPoint(x: 0.3 * screen.width + 5, y: 0.4 * screen.height + 5)
            XCTAssertEqual(bounds.midX, expectedCentre.x, accuracy: 1.5, "off its column at \(elapsed)s")
            XCTAssertEqual(bounds.midY, expectedCentre.y, accuracy: 1.5, "off its row at \(elapsed)s")
            // A little over, since the soft edge of a disc counts as drawn.
            XCTAssertEqual(bounds.width, 10 * scale, accuracy: 2.5, "wrong size at \(elapsed)s")
            XCTAssertEqual(bounds.height, 10 * scale, accuracy: 2.5, "wrong size at \(elapsed)s")
        }
    }

    func testEveryStarOfTheConstellationIsDrawnInItsOwnPlace() throws {
        for (index, star) in TwinkleMotion.constellation.enumerated() {
            // Alone, at its brightest, so the bounding box is that star's.
            let elapsed = star.duration / 2 - star.phaseOffset
            let field = TwinkleField(stars: [star], colors: [.red], size: screen, elapsed: elapsed)
            let bounds = try XCTUnwrap(try drawnBounds(of: field), "star \(index + 1) not drawn")
            XCTAssertEqual(bounds.midX, star.x * screen.width + star.size / 2, accuracy: 1.5, "star \(index + 1)")
            XCTAssertEqual(bounds.midY, star.y * screen.height + star.size / 2, accuracy: 1.5, "star \(index + 1)")
        }
    }

    func testEachStarTakesItsOwnColourInOrderAndAnEmptyListDrawsNothingRatherThanTrapping() throws {
        // Two stars, two colours: the second is the one drawn at the right.
        let left = Twinkle(x: 0.1, y: 0.5, size: 20, duration: 4, phaseOffset: 2)
        let right = Twinkle(x: 0.8, y: 0.5, size: 20, duration: 4, phaseOffset: 2)
        let field = TwinkleField(stars: [left, right], colors: [.red, .blue], size: screen, elapsed: 0)
        let renderer = ImageRenderer(content: field)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        func pixel(_ x: Int, _ y: Int) -> UIColor {
            let cropped = image.cropping(to: CGRect(x: x, y: y, width: 1, height: 1))!
            var data = [UInt8](repeating: 0, count: 4)
            let context = CGContext(
                data: &data, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return UIColor(
                red: CGFloat(data[0]) / 255, green: CGFloat(data[1]) / 255, blue: CGFloat(data[2]) / 255, alpha: CGFloat(data[3]) / 255)
        }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        pixel(Int(0.1 * 400) + 10, 410).getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertGreaterThan(r, b, "the first star should be red")
        pixel(Int(0.8 * 400) + 10, 410).getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertGreaterThan(b, r, "the second star should be blue")

        // No colours: nothing to draw, and no trap on `colors[i % colors.count]`. A marker view
        // beside it gives the render something to draw (`ImageRenderer` can return the last
        // render's pixels for an empty view).
        let bare = ZStack {
            TwinkleField(stars: [left], colors: [], size: screen, elapsed: 0)
            Rectangle().fill(.green).frame(width: 4, height: 4).position(x: 2, y: 2)
        }.frame(width: screen.width, height: screen.height)
        let bounds = try XCTUnwrap(try drawnBounds(of: bare))
        XCTAssertLessThanOrEqual(bounds.width, 6, "only the marker should have been drawn")
    }

    /// Falling confetti hides under Reduce Motion, where a frozen shower doesn't read as one;
    /// a frozen starfield does, so Crystal Ball's stays — and that is what the snapshots show.
    func testTheStarsAreStillDrawnUnderReduceMotion() throws {
        let stars = Twinkles(style: Skin.crystalBall.reveal.confetti)
            .environment(\.indDisableIdleAnimationsForTesting, true)
            .frame(width: screen.width, height: screen.height)
        let bounds = try XCTUnwrap(try drawnBounds(of: stars), "Reduce Motion should leave the stars up")
        // From the leftmost star (8 %) to the rightmost (83 % plus its own width), and from the
        // topmost (13 %) to the lowest (66 %).
        XCTAssertEqual(bounds.minX, 0.08 * screen.width, accuracy: 6)
        XCTAssertGreaterThan(bounds.maxX, 0.80 * screen.width)
        XCTAssertEqual(bounds.minY, 0.13 * screen.height, accuracy: 6)
        XCTAssertGreaterThan(bounds.maxY, 0.64 * screen.height)
    }
}
