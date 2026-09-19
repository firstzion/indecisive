import UIKit

/// Central list of every custom font PostScript name the app expects to be able to load,
/// plus a startup check (DEBUG only) that each one actually resolves.
///
/// Space Grotesk and Work Sans below are Google Fonts *variable* fonts bundled as a single
/// `.ttf` per family (registered via `UIAppFonts` in Info.plist). iOS exposes each named
/// instance defined in the font's `fvar` table as its own usable font name, but the
/// exact naming isn't always predictable from the source file alone — Space Grotesk's
/// non-Regular-default instances come out as "SpaceGrotesk-Light_Medium" (base
/// subfamily + underscore + instance) rather than a clean "SpaceGrotesk-Medium", and
/// Work Sans's Regular instance is "WorkSans-Regular" while every other weight is
/// "WorkSansRoman-*". These names were confirmed by actually running
/// `verifyAllResolve()` on-device and reading the real `UIFont.fontNames` it printed —
/// don't hand-guess this list from a font file's tables alone.
///
/// Mochiy Pop One and M PLUS Rounded 1c are Latin-only subsets (the `-Latin.ttf` files):
/// the Google Fonts originals include Japanese and are 3–5 MB each, and the OFL reserves no
/// font name for either, so trimming is allowed. M PLUS Rounded 1c's PostScript names are the
/// legacy "RoundedMplus1c-*", not the "MPLUSRounded1c-*" its filenames suggest.
enum FontRegistry {

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

    static let dmMono: [String] = [
        "DMMono-Regular", "DMMono-Medium",
    ]

    static let singleWeight: [String] = [
        "LilitaOne", "TitanOne", "MochiyPopOne-Regular",
    ]

    static var all: [String] {
        spaceGrotesk + workSans + mPlusRounded1c + dmMono + singleWeight
    }

    /// Confirms every PostScript name above actually resolves to a loaded font.
    /// Runs only in debug builds; fails an assertion (and prints the real family
    /// listing) if any name is missing, so a naming mistake is caught immediately
    /// on first launch rather than showing up as silent system-font fallback.
    static func verifyAllResolve() {
        #if DEBUG
        var missing: [String] = []
        for name in all where UIFont(name: name, size: 12) == nil {
            missing.append(name)
        }
        if missing.isEmpty {
            print("✅ FontRegistry: all \(all.count) custom fonts resolved.")
        } else {
            for family in ["Space Grotesk", "Work Sans", "Rounded Mplus 1c", "DM Mono", "Lilita One", "Titan One", "Mochiy Pop One"] {
                let available = UIFont.fontNames(forFamilyName: family)
                if !available.isEmpty {
                    print("ℹ️ Family '\(family)' actually exposes: \(available)")
                }
            }
            assertionFailure("FontRegistry: missing fonts \(missing) — see console for the real names available.")
        }
        #endif
    }
}
