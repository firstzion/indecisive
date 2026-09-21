# Open work — Rand-o-matic (`Indecisive`)

Reviewed at `67b82c0` + the working tree, 2026-09-20. Scope: all 7,439 lines of Swift across
the app and both test targets, plus `project.yml`, the README and the generated `Info.plist`.

**This file lists only what is still open.** Everything that has been fixed — the red snapshot
suite, the 18 silent skin branches, the 112 Swift 6 concurrency warnings, the unlinked animation
timings, the missing edit-mode accessibility labels, the spiralling confetti, the untested reveal
button contrast, the Phase 0–2 architecture work, and (2026-09-20) all three P0 entries and all
six P1s, and twelve of the thirteen P2s — has been removed rather than marked done. The full
diagnosis of each is in this file's git history. The one P2 left is a deliberate deferral, and
the decisions that closed the rest are recorded with the trigger that would reopen them.

File references are `path:line` against the working tree.

---

## 0. Verified baseline

Measured on this machine, not inferred. Destination: `iPhone 17 Pro, OS=26.5`.
Re-verified 2026-09-20 after the P0, P1 and P2 fixes.

| Check | Result |
|---|---|
| `xcodegen generate` | ✅ succeeds |
| Clean `xcodebuild … build-for-testing` | ✅ **0 Swift warnings** (everything compiled) |
| Unit tests (`IndecisiveTests`) | ✅ **162 executed, 0 failures** |
| UI tests (`IndecisiveUITests`) | ✅ **4 executed, 0 failures** |

`swift-format lint --strict` is clean too, and CI (`.github/workflows/ci.yml`) runs all three on
every push. An incremental build prints no warnings for files it skips, so only a clean
`build-for-testing` gives an honest count. (Three `appintentsmetadataprocessor` notices are tool
output, not Swift diagnostics, and are expected.)

Pin `OS=26.5`. An unpinned destination resolves to 27.0 here, where the snapshot tests skip
themselves rather than fail — verified on that runtime: 162 executed, 3 skipped, 0 failures. Green,
but with no cross-skin rendering coverage, which is why CI pins it too.

---

## P0 — blocks shipping

**Empty as of 2026-09-21.** Nothing currently blocks a submission: `xcodebuild archive` succeeds,
signed, and every bundle in the payload carries the keys App Store Connect validates.

Both halves of that sentence had to be learned. A successful archive is **not** the same as an
accepted upload — the app archived and signed perfectly while `IndecisiveKit`'s generated
`Info.plist` had no `CFBundleShortVersionString`, and the upload was refused for it. Validation runs
at the end of the longest loop this project has, so anything it checks is worth checking sooner:
`BundleMetadataTests` now does, in milliseconds. The three entries that were here — edit-mode tap
targets, the bundle identifier, and version/build numbers — are fixed; see the git history of this
file for what they said, and `ItemRow.swift` / `project.yml` for what changed.

One correction worth keeping: the bundle-identifier entry was closed by changing it to
`com.indecisive.app`, and that had to be reverted. An App ID must be unique across **every** Apple
developer account, not just within a team, and that generic name was already registered to someone
else — archiving failed with "cannot be registered to your development team because it is not
available". It is `com.Randomatic.app`, and the README now documents that rather than contradicting
it, which is what the entry was actually about.

---

## P1 — bugs and real risks

**Empty as of 2026-09-20.** The last entry — app-hosted unit tests — is fixed: the app's code
moved into an `IndecisiveKit` framework, so `IndecisiveTests` links it directly and no longer runs
inside the app. See the git history of this file for the investigation, and `project.yml` for the
target layout.

Two things that change fell out of it and are worth knowing:

- **Fonts are registered in code now** (`FontRegistry.ensureRegistered()`), because `UIAppFonts`
  only reads the *main* bundle and a test bundle no longer has one. Without it every snapshot
  would render in the system font.
- **A `NavigationStack` doesn't build its content** in a plain `UIWindow` with no host app — its
  `UINavigationTransitionView` stays empty. Rendering is unaffected (the snapshot tests go through
  the library's own hosting), but a test that walks a whole screen's *view hierarchy* can't host
  one. `AccessibilityTests` now hosts the row it is actually asserting about.

---

## P2 — maintainability and coverage

**One entry left open, and it's a deliberate deferral.** Of the thirteen that were here, nine are
fixed (pinned snapshot library, CI, a formatter, testable CRUD, the unreachable screens, name-card
and toolbar contrast, the "Modifying state" log line, invisible confetti, the Detail toolbar) and
three are closed as decisions with a revisit trigger, below.

### P2-1. No localization — **deliberately deferred**

~27 hardcoded English strings outside `SkinCopy`, plus English pluralization inlined into every
`SkinCopy` closure across four skins, so a String Catalog migration has to unpick plural rules from
four different voices rather than just extract literals.
[`RevealCentrepiece`](Indecisive/Skins/Components/RevealCentrepiece.swift) also calls
`.uppercased()` with no locale. `SWIFT_EMIT_LOC_STRINGS` is already on; there is no catalog to emit
into.

**Do it in one pass once the copy stops moving**, not in pieces. The debt is larger than `SkinCopy`
alone and grows with each skin. This is the only thing in P2 that is still work rather than a
decision.

---

## Decisions (2026-09-20) — closed, with the trigger that would reopen them

**Per-skin art packs: declined.** `ListBadge`, `HeroBadge`, `RowMarker`, `PrimaryCTAGlyph`,
`RevealGlow`, `RevealActionGlyph` and `RevealCentrepiece.shape` each carry an exhaustive
`switch skin.id`, so a fifth skin means editing seven shared files of artwork. The fix — `SkinArt`,
per-skin folders, those seven reduced to thin dispatchers — is 1–2 days and only pays off past
roughly five skins. The roster is four and no more are planned, and the switches being exhaustive
is what makes the compiler list every site when a `SkinID` case is added.
**Reopen if:** a fifth skin is planned.

Two shared components still read a skin's own art constants —
`CapsulePaint.shell` from [`PrimaryCTA`](Indecisive/Skins/Components/PrimaryCTA.swift) and
`CrystalPaint.markers` from [`RowMarker`](Indecisive/Skins/Components/RowMarker.swift) — both
*inside that skin's own switch arm*, so they are only reachable where the skin is already known.
Giving them tokens would mean every skin declaring a value three of them ignore; their real home is
the art pack above. **Reopens with it.** (Two other reaches were removed via
`reveal.backdropTint` and `reveal.rerollGlyphTint`, which also took two hardcoded values out of
shared components.)

**A second snapshot baseline for iOS 27: not now.** 26.5 is what the app is developed and recorded
on. A parallel baseline would double the references from 24 to 48 and double re-recording forever.
`SnapshotTests` skips itself with an explanation on any other OS, and that was verified on a real
iOS 27 simulator: **162 tests, 3 skipped, 0 failures** — the three being the snapshot tests, with
the other 159 passing unchanged. Before the guard, the same run was 17 image diffs and a red suite.
**Reopen if:** 27.x becomes the OS you develop against.

**Gashapon's confetti: accepted as drawn.** Its four unoutlined pastels sit at 1.21:1 (mint),
1.40:1 (yellow), 1.44:1 (pink) and 1.90:1 (cream) against its bright cyan reveal background. That
is the mockup's own palette, and it is listed as an explicit named exception in
`testUnoutlinedConfettiCanActuallyBeSeen` rather than hidden by a lowered bar, so a future skin
can't inherit the leniency by accident. The mockup's piece count (six vs the app's ten) and fall
distance are likewise accepted. **Reopen if:** the reveal gets a design pass.

**The kicker's size drift from the mockup: accepted.** The Wheel's reveal kicker is 19pt against
the mockup's 16px, the 8-Ball's 14pt extrabold against 13px regular. All four clear the 4.5:1 the
smallest of them needs.

**`flavorIndex` staying skin-relative: accepted.** Palettes are different lengths (3, 4, 4, 5) and
every renderer wraps with `% flavors.count`, so a list's badge colour changes with the skin and two
lists can collide under one skin but not another. Fine for a toy app; documented on the property.

---

## P3 — small

The two that were worth doing are done: the release-path `print` (there was no logging at all, so a
store failure in the field was invisible) and the silent data loss after the store-open fallback.
Six left, none urgent.

1. **`orderedItems` uses an unstable sort** —
   [`PickList.swift:44`](Indecisive/Model/PickList.swift:44). Tied `sortOrder`s would render in an
   unspecified order that can change between `body` evaluations. No app path creates ties today; test
   fixtures do.
2. **A `.pill` radius is derived from `minHeight`** —
   [`RevealActions.swift:83`](Indecisive/Skins/Components/RevealActions.swift:83). A button that
   grows at large Dynamic Type stops being a pill.
3. **`nextFlavorIndex` is `max + 1`** — [`PickList.swift:38`](Indecisive/Model/PickList.swift:38).
   Deleting every list restarts colours at 0, and lists can collide after deletions. Cosmetic.
4. **`DEVELOPMENT_TEAM: 29DR9P3A6R` is committed to a public repo** —
   [`project.yml:103`](project.yml:103). There's no root `LICENSE` either. (The font OFL licences *are*
   present and correct in `Indecisive/Resources/Fonts/LICENSES/`.)
5. **Focusing in `onAppear` on a sheet is a race** —
   [`NewListSheet.swift:58`](Indecisive/Features/Home/NewListSheet.swift:58).
6. **The long-press skin-picker shortcut is unreachable to assistive tech** —
   [`HomeView.swift:116`](Indecisive/Features/Home/HomeView.swift:116) puts it on a `Text`, which
   isn't a control. The 🎨 button covers the need, so this is a nicety.

---

## Suggested order

P0, P1 and P2 are done bar one deferral, and the two P3s worth doing are done.

1. **P2-1, localization** — the only remaining item that is real work. When the copy settles, in one
   pass.
2. **The six remaining P3s** — all small, none urgent. `orderedItems`' unstable sort is the one with
   any teeth, and no app path creates the tie it needs today.
3. Everything else only if its trigger fires (see Decisions).

---

## Appendix — reproducing the baseline

```bash
xcodegen generate
```

```bash
xcodebuild -project Indecisive.xcodeproj -scheme Indecisive \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' clean build-for-testing
```

```bash
xcodebuild -project Indecisive.xcodeproj -scheme Indecisive \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' test-without-building
```

Pin `OS=26.5` — off it, the snapshot tests skip themselves (see §0). Use a clean
`build-for-testing` for an honest warning count — an incremental build prints none for the files
it skips. Re-recording snapshots after a deliberate UI change:
`TEST_RUNNER_SNAPSHOT_TESTING_RECORD=failed`, per the README.
