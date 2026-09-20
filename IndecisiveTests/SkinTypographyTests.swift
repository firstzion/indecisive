import XCTest
@testable import Indecisive

final class SkinTypographyTests: XCTestCase {

    func testResolveReturnsExactWeightWhenPresent() {
        let type = SkinTypography(
            display: [.regular: "A-Regular", .bold: "A-Bold"],
            body: [:],
            mono: [:],
            compactTitle: .display
        )
        XCTAssertEqual(type.name(for: .display, weight: .bold), "A-Bold")
    }

    func testResolveFallsBackToRegularWhenWeightMissing() {
        // Space Grotesk has no semibold instance — this is exactly that case.
        let type = SkinTypography(
            display: [:],
            body: [.regular: "A-Regular", .bold: "A-Bold"],
            mono: [:],
            compactTitle: .body
        )
        XCTAssertEqual(type.name(for: .body, weight: .semibold), "A-Regular")
    }

    func testResolveFallsBackToAnyAvailableNameIfNoRegularEither() {
        let type = SkinTypography(display: [.black: "OnlyBlack"], body: [:], mono: [:], compactTitle: .display)
        XCTAssertEqual(type.name(for: .display, weight: .bold), "OnlyBlack")
    }

    func testEveryShippedSkinOnlyReferencesFontsFontRegistryKnowsAbout() {
        // Cross-check against FontRegistry (the on-device-verified source of
        // truth) so a typo in a skin file fails a fast unit test instead of
        // showing up as silent system-font fallback in the simulator.
        let allRegistered = Set(FontRegistry.all)
        let weights: [SkinFontWeight] = [.regular, .medium, .semibold, .bold, .extrabold, .black]
        let roles: [SkinTypography.Role] = [.display, .body, .mono]

        for skin in Skin.all {
            for role in roles {
                for weight in weights {
                    let name = skin.type.name(for: role, weight: weight)
                    XCTAssertTrue(
                        allRegistered.contains(name),
                        "\(skin.name) \(role)/\(weight) resolves to '\(name)', which FontRegistry doesn't know about"
                    )
                }
            }
        }
    }
}
