import CoreText
import UIKit

/// Central list of every custom font PostScript name the app expects to be able to load,
/// the code that registers the files themselves, and a startup check (DEBUG only) that
/// each name actually resolves.
///
/// Space Grotesk and Work Sans below are Google Fonts *variable* fonts bundled as a single
/// `.ttf` per family (registered by `ensureRegistered()`). iOS exposes each named
/// instance defined in the font's `fvar` table as its own usable font name, but the
/// exact naming isn't always predictable from the source file alone — Space Grotesk's
/// non-Regular-default instances come out as "SpaceGrotesk-Light_Medium" (base
/// subfamily + underscore + instance) rather than a clean "SpaceGrotesk-Medium", and
/// Work Sans's Regular instance is "WorkSans-Regular" while every other weight is
/// "WorkSansRoman-*". These names were confirmed by actually running
/// `verifyAllResolve()` on-device and reading the real `UIFont.fontNames` it printed —
/// don't hand-guess this list from a font file's tables alone.
///
/// Mochiy Pop One, M PLUS Rounded 1c and Bagel Fat One are Latin-only subsets (the `-Latin.ttf`
/// files): the Google Fonts originals include Japanese or Korean and are 1.5–5 MB each, and the
/// OFL reserves no font name for any of them, so trimming is allowed. M PLUS Rounded 1c's
/// PostScript names are the legacy "RoundedMplus1c-*", not the "MPLUSRounded1c-*" its filenames
/// suggest.
///
/// Nunito is a variable font like the two above, but its named instances declare their own
/// PostScript names ("Nunito-SemiBold", …) — unlike Space Grotesk's — so they come out clean.
public enum FontRegistry {

    /// Registers every bundled `.ttf` with Core Text, once per process.
    ///
    /// The fonts used to be listed in the app's `UIAppFonts`, which iOS reads
    /// at launch — but only from the **main** bundle. Once the app's code moved
    /// into `IndecisiveKit` so the unit tests could link it without a host app,
    /// the fonts came with it, and a test bundle that never launches the app has
    /// no main bundle to read them from. Every snapshot would have rendered in
    /// the system font, which the suite would have caught, loudly and
    /// confusingly, as 24 unrelated-looking image diffs.
    ///
    /// Registering from this framework's own bundle works for both: the app
    /// calls it at launch, and anything else that asks for a skin font gets it
    /// on the way through (`SkinTypography.name(for:weight:)`).
    public static func ensureRegistered() {
        _ = registered
    }

    /// The work itself, done once — a lazy `static let` is initialised exactly
    /// once per process, and thread-safely.
    private static let registered: Void = {
        let bundle = Bundle(for: BundleToken.self)
        for url in bundle.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            var error: Unmanaged<CFError>?
            // `false` here is usually "this file is already registered",
            // which is not a problem worth reporting. A genuinely broken
            // font shows up in `verifyAllResolve()` instead, by name.
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }()

    /// Only here so `Bundle(for:)` has a class to find this framework by.
    private final class BundleToken {}

    static let spaceGrotesk: [String] = [
        "SpaceGrotesk-Light", "SpaceGrotesk-Light_Regular", "SpaceGrotesk-Light_Medium", "SpaceGrotesk-Light_Bold",
    ]

    static let workSans: [String] = [
        "WorkSans-Regular", "WorkSansRoman-Medium", "WorkSansRoman-SemiBold",
        "WorkSansRoman-Bold", "WorkSansRoman-ExtraBold",
    ]

    static let mPlusRounded1c: [String] = [
        "RoundedMplus1c-Medium", "RoundedMplus1c-Bold",
    ]

    static let nunito: [String] = [
        "Nunito-Regular", "Nunito-Medium", "Nunito-SemiBold",
        "Nunito-Bold", "Nunito-ExtraBold", "Nunito-Black",
    ]

    static let dmMono: [String] = [
        "DMMono-Regular", "DMMono-Medium",
    ]

    static let singleWeight: [String] = [
        "LilitaOne", "TitanOne", "MochiyPopOne-Regular", "BagelFatOne-Regular",
    ]

    static var all: [String] {
        spaceGrotesk + workSans + mPlusRounded1c + nunito + dmMono + singleWeight
    }

    /// Confirms every PostScript name above actually resolves to a loaded font.
    /// Runs only in debug builds; fails an assertion (and prints the real family
    /// listing) if any name is missing, so a naming mistake is caught immediately
    /// on first launch rather than showing up as silent system-font fallback.
    public static func verifyAllResolve() {
        #if DEBUG
        ensureRegistered()
        var missing: [String] = []
        for name in all where UIFont(name: name, size: 12) == nil {
            missing.append(name)
        }
        if missing.isEmpty {
            AppLog.fonts.debug("All \(all.count, privacy: .public) custom fonts resolved.")
        } else {
            for family in [
                "Space Grotesk", "Work Sans", "Rounded Mplus 1c", "Nunito", "DM Mono", "Lilita One", "Titan One", "Mochiy Pop One",
                "Bagel Fat One",
            ] {
                let available = UIFont.fontNames(forFamilyName: family)
                if !available.isEmpty {
                    AppLog.fonts.error(
                        "Family '\(family, privacy: .public)' actually exposes: \(available, privacy: .public)"
                    )
                }
            }
            assertionFailure("FontRegistry: missing fonts \(missing) — see console for the real names available.")
        }
        #endif
    }
}
