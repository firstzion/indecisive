import XCTest

@testable import IndecisiveKit

/// The keys App Store Connect requires on every bundle in an upload.
///
/// This exists because it caught us out. `IndecisiveKit` was added with
/// `GENERATE_INFOPLIST_FILE: YES` and no version settings of its own, so its
/// generated `Info.plist` had `CFBundleVersion` (a default) but no
/// `CFBundleShortVersionString`. Everything built, the tests were green, the
/// archive succeeded and was signed — and the upload was refused: *"The bundle
/// 'Payload/Indecisive.app/Frameworks/IndecisiveKit.framework' is missing plist
/// key ... CFBundleShortVersionString."*
///
/// Validation only runs at the very end of the longest loop this project has,
/// so a missing key costs an archive and an upload round trip to discover. It
/// is a plain dictionary lookup, and belongs somewhere that fails in seconds.
final class BundleMetadataTests: XCTestCase {

    /// The framework itself — the bundle that was missing a key. `Bundle(for:)`
    /// resolves to whichever copy this test run linked.
    private var frameworkBundle: Bundle {
        Bundle(for: PickCounter.self)
    }

    func testTheFrameworkCarriesEveryKeyAnUploadRequires() throws {
        // `CFBundleShortVersionString` is the one that was actually missing;
        // the rest are required of an embedded framework too, and are cheap to
        // hold onto now that anything is looking.
        for key in [
            "CFBundleShortVersionString",
            "CFBundleVersion",
            "CFBundleIdentifier",
            "CFBundleExecutable",
        ] {
            let value = frameworkBundle.object(forInfoDictionaryKey: key) as? String
            XCTAssertNotNil(
                value,
                "IndecisiveKit's Info.plist has no \(key). App Store Connect rejects the upload for this, "
                    + "long after everything else has gone green — set it in project.yml.")
            XCTAssertFalse(
                value?.isEmpty ?? true,
                "IndecisiveKit's \(key) is present but empty, which fails validation just the same.")
        }
    }

    func testTheFrameworkIsVersionedTheSameWayTheAppIs() throws {
        // Both read `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`, which are
        // set once for the whole project. If someone re-adds a per-target
        // override the two can drift, and a framework at a different version
        // from the app it ships inside is at best confusing in a crash report.
        let short = try XCTUnwrap(
            frameworkBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        let build = try XCTUnwrap(
            frameworkBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)

        // A release version is dotted digits; a build number is digits.
        XCTAssertNotNil(
            short.range(of: #"^\d+(\.\d+)*$"#, options: .regularExpression),
            "expected a release version like 1.0, got '\(short)'")
        XCTAssertNotNil(
            build.range(of: #"^\d+$"#, options: .regularExpression),
            "expected a numeric build number, got '\(build)'")
    }
}
