# Open work — Rand-o-matic (`Indecisive`)

Reviewed at `67b82c0` + the working tree, 2026-09-20. Scope: all 7,439 lines of Swift across
the app and both test targets, plus `project.yml`, the README and the generated `Info.plist`.

**This file lists only what is still open.** Everything that has been fixed — the red snapshot
suite, the 18 silent skin branches, the 112 Swift 6 concurrency warnings, the unlinked animation
timings, the missing edit-mode accessibility labels, the spiralling confetti, the untested reveal
button contrast, the Phase 0–2 architecture work, and (2026-09-20) all three P0 entries plus five
of the six P1s — has been removed rather than marked done. The full diagnosis of each is in this
file's git history.

File references are `path:line` against the working tree.

---

## 0. Verified baseline

Measured on this machine, not inferred. Destination: `iPhone 17 Pro, OS=26.5`.
Re-verified 2026-09-20 after the P0 and P1 fixes.

| Check | Result |
|---|---|
| `xcodegen generate` | ✅ succeeds |
| Clean `xcodebuild … build-for-testing` | ✅ **0 Swift warnings** (everything compiled) |
| Unit tests (`IndecisiveTests`) | ✅ **139 executed, 0 failures** |
| UI tests (`IndecisiveUITests`) | ✅ **4 executed, 0 failures** |

An incremental build prints no warnings for files it skips, so only a clean `build-for-testing`
gives an honest count. (Three `appintentsmetadataprocessor` notices are tool output, not Swift
diagnostics, and are expected.) Pin `OS=26.5`: an unpinned destination resolves to 27.0 here, where
17 of the 24 snapshots fail (see P2-9).

---

## P0 — blocks shipping

**Empty as of 2026-09-20.** Nothing currently blocks a submission. The three entries that were here
— edit-mode tap targets, the bundle identifier, and version/build numbers — are fixed; see the git
history of this file for what they said, and `ItemRow.swift` / `project.yml` for what changed.

---

## P1 — bugs and real risks

### P1-1. Unit tests are app-hosted, and a full run occasionally traps inside SwiftData

**Mitigated 2026-09-20, not fixed.** The one lead this entry listed as untried has now been
tried: while hosting unit tests the app no longer builds its UI or opens the real on-disk store
at all (`IndecisiveApp.isHostingUnitTests` — XCTest sets `XCTestConfigurationFilePath` in the
host process, and a UI test's target app doesn't get it, so `IndecisiveUITests` is unaffected).
That removes the second, unasked-for set of live `@Query` save observers from the test process,
which was the leading suspect. **40 consecutive unit-suite runs since were clean** — suggestive
against a baseline of 3 in 69, but not proof, and nowhere near enough runs to call it closed.

**The real fix is still the one this entry started with: don't host the unit tests in the app.**
There is no smaller version of it. On iOS you cannot `@testable import` an app module without
the test bundle being hosted by that app, so unhosting means moving the app's code into a
framework target that both the app and the tests link: a new `IndecisiveKit` target, every
`@testable import Indecisive` updated, and an access-level pass over anything the thin app shell
still reaches for. That is a structural change, not a patch, which is why it hasn't been done
along with the rest of P1.

The diagnosis, and what has already been ruled out:

`IndecisiveTests` is hosted by the real app, so its live `@Query` views coexist with the in-memory
containers the tests create and save. **This recurs**: three crashes in 69 full runs on 2026-09-20,
none in ~20 the day before, and first seen 2026-09-19. My run for this review was clean.

Every occurrence is `EXC_BREAKPOINT` on the main thread in `SnapshotTests.makeRevealModel()` or
`makeHomeContainer()`, at the `context.save()`: the save posts a notification, a `_SwiftData_SwiftUI`
observer calls into SwiftData, and SwiftData traps. XCTest then restarts the host and prints
"Restarting after unexpected exit, crash, or test timeout" with **zero assertion failures** and exit
code 65 — so the failed run names no test. `~/Library/Logs/DiagnosticReports/Indecisive-*.ips` is
the only place that does. Re-run before investigating anything else; `-test-iterations` stops at the
crash and reports partial totals.

Already ruled out: the cold start (four forced fresh installs, no crash; the snapshot suite alone,
none in 40 runs), and a hosted view merely outliving its container (a 25-round probe). **Retaining
every test container does not fix it and is not safe to ship** — 100 runs were clean, but 300 crashed
at run 180 inside Core Data's `notify_register_plain`, presumably resource exhaustion from thousands
of retained containers. The remaining lead — that the app keeps its own Home (a `@Query` on the
*on-disk* store) alive inside the test process, and its observers are the likeliest callee — is what
the mitigation above acts on.

A suite that can fail without naming a test is one people learn to re-run instead of trust.

---

## P2 — maintainability and coverage

### P2-1. `swift-snapshot-testing` isn't pinned

[`project.yml:20`](project.yml:20) — `from: "1.17.0"`, with no committed lockfile (the workspace's
`Package.resolved` sits under the gitignored `*.xcodeproj/`). A fresh clone resolves whatever is
newest that day. For a library whose entire job is pixel comparison, that is a way for 24 snapshots
to go red with no code change. `exactVersion: "1.19.5"` pins it (checked: XcodeGen emits
`kind = exactVersion`).

### P2-2. No CI, no linter, no formatter

No `.github/`, no SwiftLint or swift-format config. The main regression net for skins is 24
pixel-exact images that only hold on one simulator OS — it protects nothing unless something runs
it automatically, on a pinned destination, on every push.

### P2-3. The app's actual CRUD is unreachable from a test

`commitNewItem`, `deleteItem`, `moveItem`, `renormalizeSortOrder` and `commitEdits`
([`ListDetailView.swift:278–334`](Indecisive/Features/Detail/ListDetailView.swift:278)) and
`createList` ([`HomeView.swift:164`](Indecisive/Features/Home/HomeView.swift:164)) are private
methods on `View` structs.

125 unit tests cover tokens, copy, motion, contrast, confetti maths and `PickService` — and not one
list or item edit. Creating, renaming, reordering and deleting *is* the app. Only the UI tests touch
it, at 74 s a run. `PickService.choose` is the pattern that works here: a pure function, injectable,
tested directly. These want the same treatment.

### P2-4. Two screens ship but are unreachable

- **`SkinOnboardingView`** (41 lines): `hasChosenSkin` defaults to `true`
  ([`AppRoot.swift:17`](Indecisive/App/AppRoot.swift:17)) and nothing in the app ever sets it
  `false`. The first-launch "Choose your toy" screen cannot be reached in a shipping build.
- **`SkinComponentGallery`** (96 lines): referenced only by its own `#Preview`;
  [`RootView.swift:6`](Indecisive/App/RootView.swift:6) explains why it's kept.

Both compile into the shipped binary, neither has a test, and nobody would notice if either broke.
Keep them if they earn it — but then give onboarding an entry point (or a test) and move the gallery
behind `#if DEBUG`.

### P2-5. The biggest text in the app is the one pair contrast doesn't check

`ContrastTests` covers 13 pairs and is otherwise thorough, but not the reveal's name card:

- the 34 pt winner name — `palette.primaryText` on `card.fill`
  ([`RevealCentrepiece.swift:175`](Indecisive/Skins/Components/RevealCentrepiece.swift:175))
- the "YOU GOT" label — `palette.accent` on `card.fill`
- the card's support line — `palette.secondaryText` on `card.fill`
- the 8-Ball's in-ball answer — `palette.accent` on `revealBackground`
  ([`:124`](Indecisive/Skins/Components/RevealCentrepiece.swift:124))

`primaryText` is only ever checked against `palette.background`
([`ContrastTests.swift:62`](IndecisiveTests/ContrastTests.swift:62)) — a different colour from
`card.fill` in every skin that has a card.

**Related, and wrong today:** the kicker test
([`ContrastTests.swift:108`](IndecisiveTests/ContrastTests.swift:108)) applies a 3:1 "large text"
bar to all four skins, but Crystal Ball's kicker is 13 pt semibold
([`CrystalBall.swift:129`](Indecisive/Skins/CrystalBall.swift:129)), which is not WCAG large text
and needs 4.5:1. All four currently measure 5.8–16.8:1, so nothing is broken — the bar just
wouldn't catch it if a colour moved.

### P2-6. Shared components still reach into skin-specific colour namespaces

`Skin.swift:4-8` sets the rule: screens read semantic tokens, never a raw value. These are the
exceptions, and they are the pattern a fifth skin will copy:

| Namespace | Read from |
|---|---|
| `CapsulePaint` ([`CapsuleBall.swift:36`](Indecisive/Skins/Components/CapsuleBall.swift:36)) | [`PrimaryCTA.swift:80`](Indecisive/Skins/Components/PrimaryCTA.swift:80) |
| `CrystalPaint` ([`CrystalOrb.swift:7`](Indecisive/Skins/Components/CrystalOrb.swift:7)) | [`RowMarker.swift:41`](Indecisive/Skins/Components/RowMarker.swift:41), [`RevealActionGlyph.swift:28`](Indecisive/Skins/Components/RevealActionGlyph.swift:28), [`RevealGlow.swift:48`](Indecisive/Skins/Components/RevealGlow.swift:48) |

### P2-7. Per-skin art still lives in seven shared files (the optional Phase 3)

`ListBadge`, `HeroBadge`, `RowMarker`, `PrimaryCTAGlyph`, `RevealGlow`, `RevealActionGlyph` and
`RevealCentrepiece.shape` each carry an exhaustive `switch skin.id`. Exhaustive is the *right*
property — the compiler lists every one when a `SkinID` case is added, which is what protects the
existing skins — so don't trade it away. But a fifth skin still means editing seven shared files of
artwork.

**Only worth doing if the roster is heading past five skins:** introduce `SkinArt`, move each skin's
structural views into `Skins/<SkinName>/`, and reduce those seven to thin dispatchers. Exit
condition: adding a skin touches 3 files plus one new folder, down from 10 today. Estimate 1–2 days.

### P2-8. No localization

~27 user-facing strings outside `SkinCopy` are hard-coded English literals — `"New List"`,
`"Cancel"`, `"Create"`, `"Delete list?"`, `"Lists"`, `"Choose your toy"`, `"Skins"`,
`"Couldn't load your saved lists"`, plus `"Untitled"` at
[`ListDetailView.swift:332`](Indecisive/Features/Detail/ListDetailView.swift:332).

`SkinCopy` itself is worse than "not localized": every closure inlines English pluralization
([`EightBall.swift:96`](Indecisive/Skins/EightBall.swift:96) and the equivalents in every skin), so
a String Catalog migration has to unpick plural rules from four skins' voices, not just extract
literals. [`RevealCentrepiece.swift:124`](Indecisive/Skins/Components/RevealCentrepiece.swift:124)
also calls `.uppercased()` with no locale. `SWIFT_EMIT_LOC_STRINGS` is already on
([`project.yml:90`](project.yml:90)); there is no catalog to emit into.

`SkinCopy.swift:5-8` documents the deferral as a decision — fine. Just note the debt is larger than
`SkinCopy` alone, and grows with each skin.

### P2-9. The snapshot images only hold on iOS 26.5, and Detail's don't cover its toolbar

On iOS 27.0, 17 of the 24 snapshots fail — on both devices tried (iPhone 18 Pro, iPhone 17) while an
iPhone 17 on 26.5 passes, so it is the OS, not the device. Reveal is near-identical (0.02–0.9 % of
pixels); Home and Detail differ by 16–40 % because `NavigationStack` lays out differently: content
sits ~50 pt lower, and Detail draws its toolbar.

That last part is the real finding: **the 26.5 renders never draw that toolbar**, so nothing
snapshot-tests the skinned back button, title or Edit button today. And on this machine an unpinned
destination resolves to 27.0, so a run that forgets `OS=26.5` is red.

Options: fail (or skip) with a clear message when the OS isn't 26.5, and/or record a second baseline
once 27.x is the OS you target.

### P2-10. Reveal kicker sizes have drifted from the mockup

The mockup sets the Wheel's reveal kicker at `16px Titan One`, `letter-spacing: .06em`; the code uses
**19 pt** ([`PrizeWheel.swift:111`](Indecisive/Skins/PrizeWheel.swift:111)) with the shared
`.tracking(2)`, and has since the first commit. The 8-Ball's is 14 pt extrabold
([`EightBall.swift:122`](Indecisive/Skins/EightBall.swift:122)) against the mockup's 13 px regular
at `.24em`; Gashapon's matches. It may be deliberate, but the code and its own documentation
disagree — see the stale "16pt display" comment noted in P2-5. Changing the Wheel's means
re-recording its two Reveal images.

### P2-11. Tapping Done with a text field focused logs "Modifying state during view update"

Renaming an item (or the list title) and then tapping **Done** makes SwiftUI log `Modifying state
during view update, this will cause undefined behavior.` It is pre-existing and appears **0 times
when nothing is focused**, once when a field is. The likely mechanism: removing a focused `TextField`
as `isEditing` flips makes SwiftUI commit its text into the model mid-update.

It's a log line today — the value written is the one already there — but the message says
"undefined behavior". The fix is probably to resign first responder before `commitEdits()` and the
toggle in `editButton`. That's a focus-handling change; the edit-mode UI test exercises exactly this
path and says so in a comment.

### P2-12. `flavorIndex` is skin-relative, permanently

Palettes are different lengths — 3 (8-Ball), 4 (Wheel and Crystal Ball), 5 (Gashapon) — and every
renderer wraps with `% flavors.count`. A list's badge colour therefore changes when the skin
changes, and two lists that looked different under one skin can collide under another. The
new-list "Flavour" picker is gone and lists now take the next colour along automatically, so nobody
*chooses* an index that later changes meaning; this consequence is all that's left. Probably
acceptable for a toy app — just undocumented.

### P2-13. Confetti still differs from the mockup, pending a design call

The motion is fixed and tested; the *contents* were left as they were:

- The 8-Ball's mockup has three colours (lime, pink, cyan); the app adds the card surface colour
  `#241B52`, which is 1.28:1 on the reveal background — roughly one piece in four barely shows.
- The Wheel's mockup pieces are red, teal and cream; the app also includes yellow, which **is** the
  reveal background (only its outline shows), and white.
- The mockup's fall stops at `translateY(620px)` on an ~852 pt screen; the app's crosses the whole
  height. The mockup has six pieces, the app ten.

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

1. **P2-1 and P2-2** — cheap, and they stop the suite rotting silently. With no CI, the 24
   pixel-exact snapshots protect nothing unless someone remembers to run them on a pinned OS.
2. **P2-3** — the app's own CRUD still isn't reachable from a test. That's the largest remaining
   hole in what a green run actually proves.
3. **P1-1** — the structural fix (a framework target, so the unit tests need no host). Worth doing
   *after* P2-3, since both touch how the tests are built, and worth watching the soak in the
   meantime to see whether the mitigation held.
4. **P2-5** — one contrast test away from covering the largest text in the app.
5. Everything else as it comes up.

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
