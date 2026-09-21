# Open work — Rand-o-matic (`Indecisive`)

Reviewed at `67b82c0` + the working tree, 2026-09-20. Scope: all 7,439 lines of Swift across
the app and both test targets, plus `project.yml`, the README and the generated `Info.plist`.

**This file lists only what is still open.** Everything that has been fixed — the red snapshot
suite, the 18 silent skin branches, the 112 Swift 6 concurrency warnings, the unlinked animation
timings, the missing edit-mode accessibility labels, the spiralling confetti, the untested reveal
button contrast, the Phase 0–2 architecture work, and (2026-09-20) all three P0 entries and all
six P1s, and nine of the thirteen P2s — has been removed rather than marked done. The full
diagnosis of each is in this file's git history.

File references are `path:line` against the working tree.

---

## 0. Verified baseline

Measured on this machine, not inferred. Destination: `iPhone 17 Pro, OS=26.5`.
Re-verified 2026-09-20 after the P0, P1 and P2 fixes.

| Check | Result |
|---|---|
| `xcodegen generate` | ✅ succeeds |
| Clean `xcodebuild … build-for-testing` | ✅ **0 Swift warnings** (everything compiled) |
| Unit tests (`IndecisiveTests`) | ✅ **161 executed, 0 failures** |
| UI tests (`IndecisiveUITests`) | ✅ **4 executed, 0 failures** |

`swift-format lint --strict` is clean too, and CI (`.github/workflows/ci.yml`) runs all three on
every push. An incremental build prints no warnings for files it skips, so only a clean
`build-for-testing` gives an honest count. (Three `appintentsmetadataprocessor` notices are tool output, not Swift
diagnostics, and are expected.) Pin `OS=26.5`: an unpinned destination resolves to 27.0 here, where
17 of the 24 snapshots fail (see P2-9).

---

## P0 — blocks shipping

**Empty as of 2026-09-20.** Nothing currently blocks a submission. The three entries that were here
— edit-mode tap targets, the bundle identifier, and version/build numbers — are fixed; see the git
history of this file for what they said, and `ItemRow.swift` / `project.yml` for what changed.

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

Nine of the thirteen entries that were here are gone: the snapshot library is pinned, CI and a
formatter exist, the app's CRUD is testable (`ListEditor`), the two unreachable screens are dealt
with, the reveal's name-card text is contrast-tested, the "Modifying state during view update" log
line is fixed, and the per-skin art packs, localization and kicker drift were all decided rather
than left hanging. What follows is what is genuinely still open.

### P2-1. Two shared components still reach into a skin's own colours

**Reduced, 2026-09-20.** Two of the four reaches are gone, via tokens that also took two hardcoded
values out of shared components: `reveal.backdropTint` (the 8-Ball's glow read `palette.accent`,
Gashapon's sunburst a literal `.white`, Crystal Ball's haze reached into `CrystalPaint`) and
`reveal.rerollGlyphTint` (the 8-Ball's was a bare `Color(hex: 0xFF4FD8)` living in the component).
Both are optional, and `nil` now expresses "the Wheel has neither", replacing a named special case
in each of `RevealGlow` and `RevealActionGlyph`.

Two remain, and they are art internals rather than values a token can sensibly name:

| Namespace | Still read from |
|---|---|
| `CapsulePaint.shell` ([`CapsuleBall.swift`](Indecisive/Skins/Components/CapsuleBall.swift)) | [`PrimaryCTA.swift`](Indecisive/Skins/Components/PrimaryCTA.swift) — Gashapon's knob disc |
| `CrystalPaint.markers` ([`CrystalOrb.swift`](Indecisive/Skins/Components/CrystalOrb.swift)) | [`RowMarker.swift`](Indecisive/Skins/Components/RowMarker.swift) — Crystal Ball's per-row dot cycle |

Both sit **inside that skin's own `switch skin.id` arm**, so they are only reachable where the skin
is already known. Giving them tokens would mean every skin declaring a value three of them ignore.
The real home for them is a per-skin art pack — which was considered and declined (see P2-2), so
this is where it rests. Worth revisiting only if that decision changes.

### P2-2. Per-skin art still lives in seven shared files — **declined, not deferred**

`ListBadge`, `HeroBadge`, `RowMarker`, `PrimaryCTAGlyph`, `RevealGlow`, `RevealActionGlyph` and
`RevealCentrepiece.shape` each carry an exhaustive `switch skin.id`, so a fifth skin means editing
seven shared files of artwork. The fix — `SkinArt`, per-skin folders, those seven reduced to thin
dispatchers — is 1–2 days and only pays for itself past roughly five skins.

**Decision (2026-09-20): not doing it.** The roster is four and no more are planned. The switches
are exhaustive, so the compiler lists every one when a `SkinID` case is added, which is the
property that actually protects the existing skins; that is worth keeping regardless. Recorded here
so the question isn't reopened from scratch — revisit only if the roster grows.

### P2-3. No localization — **deliberately deferred**

~27 hardcoded English strings outside `SkinCopy`, plus English pluralization inlined into every
`SkinCopy` closure across four skins, so a String Catalog migration has to unpick plural rules from
four different voices rather than just extract literals.
[`RevealCentrepiece`](Indecisive/Skins/Components/RevealCentrepiece.swift) also calls
`.uppercased()` with no locale. `SWIFT_EMIT_LOC_STRINGS` is already on; there is no catalog to emit
into.

**Decision (2026-09-20): still deferred**, and worth doing in one pass once the copy stops moving —
not in pieces. The debt is larger than `SkinCopy` alone and grows with each skin.

### P2-4. The snapshots still only hold on iOS 26.5

`SnapshotTests` now **skips itself with an explanation** on any other OS instead of producing 17
mystifying image diffs, and CI pins the destination so the coverage actually runs somewhere. The
underlying dependence is unchanged: on iOS 27.0, Home and Detail differ by 16–40 % because
`NavigationStack` lays out differently — content ~50 pt lower, and Detail draws its toolbar.

Two things still open:
- **Detail's toolbar has never been snapshot-tested.** The 26.5 renders don't draw it, so the
  skinned back button, title and Edit button have no image coverage at all.
- A second baseline will be needed whenever 27.x becomes the target.

### P2-5. Gashapon's confetti is still hard to see

The two clear defects are fixed: the 8-Ball's fourth colour (1.27:1 on its own reveal background,
unoutlined — roughly one piece in four fell unseen) and the Wheel's yellow (1.00:1 — *literally* the
background, so those pieces showed as nothing but their outline).

Gashapon's remains: its four unoutlined pastels sit at 1.21:1 (mint), 1.40:1 (yellow), 1.44:1
(pink) and 1.90:1 (cream) against its bright cyan reveal background. That is the mockup's own
palette, so changing it is a design call rather than a defect to quietly fix, and it's listed as an
explicit exception in `testUnoutlinedConfettiCanActuallyBeSeen` rather than hidden by a lowered bar.
The mockup's piece count (six vs the app's ten) and fall distance are likewise accepted deviations.

---

## P3 — small

1. **`print` on a release path** — [`IndecisiveApp.swift:72`](Indecisive/App/IndecisiveApp.swift:72).
   There is no `os.Logger` anywhere in the app, so a store-open failure in the field is invisible.
2. **The store-open fallback loses everything, silently, after the first alert.** The alert fires
   once ([`HomeView.swift:80`](Indecisive/Features/Home/HomeView.swift:80)); the entire session then
   runs against a throwaway in-memory store, so everything the user creates afterwards vanishes on
   relaunch with nothing on screen saying so.
3. **`orderedItems` uses an unstable sort** —
   [`PickList.swift:44`](Indecisive/Model/PickList.swift:44). Tied `sortOrder`s would render in an
   unspecified order that can change between `body` evaluations. No app path creates ties today; test
   fixtures do.
4. **A `.pill` radius is derived from `minHeight`** —
   [`RevealActions.swift:83`](Indecisive/Skins/Components/RevealActions.swift:83). A button that
   grows at large Dynamic Type stops being a pill.
5. **`nextFlavorIndex` is `max + 1`** — [`PickList.swift:38`](Indecisive/Model/PickList.swift:38).
   Deleting every list restarts colours at 0, and lists can collide after deletions. Cosmetic.
6. **`DEVELOPMENT_TEAM: 29DR9P3A6R` is committed to a public repo** —
   [`project.yml:103`](project.yml:103). There's no root `LICENSE` either. (The font OFL licences *are*
   present and correct in `Indecisive/Resources/Fonts/LICENSES/`.)
7. **Focusing in `onAppear` on a sheet is a race** —
   [`NewListSheet.swift:58`](Indecisive/Features/Home/NewListSheet.swift:58).
8. **The long-press skin-picker shortcut is unreachable to assistive tech** —
   [`HomeView.swift:116`](Indecisive/Features/Home/HomeView.swift:116) puts it on a `Text`, which
   isn't a control. The 🎨 button covers the need, so this is a nicety.

---

## Suggested order

Nothing here is urgent — P0 and P1 are empty and the four P2s are each either a design call or a
known, bounded gap.

1. **P2-4's missing toolbar coverage** — the skinned back button, title and Edit button have no
   image coverage on any OS. That's the one real hole left in the rendering net.
2. **P2-5** — decide Gashapon's confetti. Five minutes if the answer is "leave it"; it just wants
   an owner's call rather than sitting as an exception in a test.
3. **P2-3** — worth starting the String Catalog whenever the copy settles, in one pass.
4. **P2-1 and P2-2** stay closed unless a fifth skin appears, at which point they reopen together.

Also worth watching: CI has never actually run (see the note at the top of
`.github/workflows/ci.yml`). The runner label and Xcode path are the likely first-run snags.

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

Pin `OS=26.5` (P2-9). Use a clean `build-for-testing` for an honest warning count — an incremental
build prints none for the files it skips. Re-recording snapshots after a deliberate UI change:
`TEST_RUNNER_SNAPSHOT_TESTING_RECORD=failed`, per the README.
