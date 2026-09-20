# Open work — Rand-o-matic (`Indecisive`)

Reviewed at `67b82c0` + the working tree, 2026-09-20. Scope: all 7,439 lines of Swift across
the app and both test targets, plus `project.yml`, the README and the generated `Info.plist`.

**This file lists only what is still open.** Everything that has been fixed — the red snapshot
suite, the 18 silent skin branches, the 112 Swift 6 concurrency warnings, the unlinked animation
timings, the missing edit-mode accessibility labels, the spiralling confetti, the untested reveal
button contrast, the Phase 0–2 architecture work, and (2026-09-20) all three P0 entries — has been
removed rather than marked done. The full diagnosis of each is in this file's git history.

File references are `path:line` against the working tree.

---

## 0. Verified baseline

Measured on this machine, not inferred. Destination: `iPhone 17 Pro, OS=26.5`.
Re-verified 2026-09-20 after the P0 fixes.

| Check | Result |
|---|---|
| `xcodegen generate` | ✅ succeeds |
| Clean `xcodebuild … build-for-testing` | ✅ **0 Swift warnings** (everything compiled) |
| Unit tests (`IndecisiveTests`) | ✅ **125 executed, 0 failures** |
| UI tests (`IndecisiveUITests`) | ✅ **4 executed, 0 failures** |

An incremental build prints no warnings for files it skips, so only a clean `build-for-testing`
gives an honest count. (Three `appintentsmetadataprocessor` notices are tool output, not Swift
diagnostics, and are expected.) Pin `OS=26.5`: an unpinned destination resolves to 27.0 here, where
17 of the 24 snapshots fail (see P2-9).

One figure below was measured with a throwaway probe test that hosted the real views and read their
accessibility frames rather than estimating: the fact that the write-after-delete in P1-4 does *not*
currently crash.

---

## P0 — blocks shipping

**Empty as of 2026-09-20.** Nothing currently blocks a submission. The three entries that were here
— edit-mode tap targets, the bundle identifier, and version/build numbers — are fixed; see the git
history of this file for what they said, and `ItemRow.swift` / `project.yml` for what changed.

---

## P1 — bugs and real risks

### P1-1. A cancelled swipe leaves a Home row permanently un-tappable

**Where:** [`SwipeToDeleteRow.swift:57`](Indecisive/Skins/Components/SwipeToDeleteRow.swift:57),
[`:70`](Indecisive/Skins/Components/SwipeToDeleteRow.swift:70)

`isSwiping` is set in `onChanged` and cleared **only** in `onEnded`. SwiftUI does not guarantee
`onEnded` fires when a simultaneous gesture wins or the system interrupts the drag — and this
gesture is deliberately `.simultaneousGesture` alongside a `ScrollView`, which is precisely the
arrangement where a drag gets taken away. If that happens, `.disabled(true)` sticks for the life of
the row and `offset` freezes mid-swipe with the red backdrop showing; the row can no longer be
tapped or navigated into.

`@GestureState` resets automatically when a gesture is cancelled. `@State` doesn't. Both `offset`
and `isSwiping` want to be `@GestureState` (or to be reset from an `onChange`/`.onDisappear` safety
net) rather than hand-cleared in `onEnded`.

### P1-2. Accept and re-roll aren't debounced

**Where:** [`RevealActions.swift:15`](Indecisive/Skins/Components/RevealActions.swift:15),
[`RevealView.swift:121`](Indecisive/Features/Reveal/RevealView.swift:121),
[`RevealModel.swift:35`](Indecisive/Features/Reveal/RevealModel.swift:35)

`accept()` records a `Pick` and *then* calls `dismiss()`, which is not instantaneous. A double-tap
on "LOCK IT IN" records two accepted picks — inflating both the list's history and the 8-Ball's
"THE BALL HAS SPOKEN *n* TIMES" counter — from one user action.

Shake-to-reroll ([`RevealView.swift:59`](Indecisive/Features/Reveal/RevealView.swift:59)) has no
guard at all while the intro animation is still playing, unlike the CTA on the detail screen, which
checks `revealModel == nil`. A shaky hand stacks re-rolls behind the visible one, each recording a
rejection. `RevealModel` should make both operations idempotent for the life of one session, or the
buttons should disable themselves after the first hit.

### P1-3. Home materialises every `Pick` ever made to render one line

**Where:** [`HomeView.swift:16`](Indecisive/Features/Home/HomeView.swift:16),
[`:160`](Indecisive/Features/Home/HomeView.swift:160)

`@Query private var picks: [Pick]` loads the entire pick history into memory so that `picks.count`
can render the footer. It was changed from `PickService.totalPickCount` (an untracked `fetchCount`)
for a good reason — the footer has to update when a pick is recorded elsewhere — but the fix traded
a correctness bug for an unbounded one.

Nothing ever prunes `Pick` rows, either. There is no history UI, no retention policy and no cap, so
both the store and this fetch grow for the life of the install, and every re-roll adds a row. Wants
either a `fetchCount` behind something observable, or a `@Query` that doesn't materialise the rows.

### P1-4. A write is ordered after a delete

**Where:** [`ListDetailView.swift:336`](Indecisive/Features/Detail/ListDetailView.swift:336),
[`:74`](Indecisive/Features/Detail/ListDetailView.swift:74),
[`:326`](Indecisive/Features/Detail/ListDetailView.swift:326)

`deleteList()` calls `dismiss()` and defers `context.delete(list)` by one run-loop turn, to keep
`body` from re-evaluating against a deleted object. But `.onDisappear(perform: commitEdits)` fires
*after* that — and `commitEdits()` reads **and writes** `list.name` and every `item.name` on the
object that was just deleted.

**Probed, and it does not currently crash**: against an in-memory store, reading and writing a
deleted-then-saved `PickList` succeeded. So this is a latent hazard, not a reproduced failure — but
ordering a write after a delete is still wrong, and it survives only on SwiftData's tolerance.

Separately, and regardless of deletion: `commitEdits()` runs on **every** back-navigation, not just
after an edit. Leaving a list you only looked at rewrites its name and every item name to the same
values, dirtying the model and waking autosave and every `@Query` that observes it. Gate it on
"was actually editing".

### P1-5. Unit tests are app-hosted and intermittently trap inside SwiftData

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
of retained containers. Not yet tried: the app keeps its own Home (a `@Query` on the *on-disk* store)
alive inside the test process, and its observers are the likeliest callee, so suppressing the app's
UI while it hosts unit tests would test that.

The real fix is the one this entry has always ended with: **don't host the unit tests in the app.**
A suite that can fail without naming a test is one people learn to re-run instead of trust.

### P1-6. The happy-path UI test mutates the machine's real `UserDefaults`

**Where:** [`HappyPathTests.swift:54`](IndecisiveUITests/HappyPathTests.swift:54),
[`:135`](IndecisiveUITests/HappyPathTests.swift:135)

`testCreateListAddItemsPickRerollAcceptThenSwitchSkinAndStatePersists` deliberately omits `-skin`
so the skin switch it performs is real — which means it **persists to the simulator's defaults**.
It restores the Wheel at the end, but only on the pass path: a failure anywhere before the last
block leaves the machine on the 8-Ball, and the next run starts from different state. The test also
can't be run in parallel with itself or repeated safely.

`IndecisiveApp`'s own doc comment promises a run "never touches, or depends on, real persisted app
data". The store honours that; the skin doesn't. Either drive the switch through a launch argument
the app re-reads, or restore in a `tearDown` that runs on failure too.

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

1. **P1-1 and P1-2** — the two a real user actually hits: a row that stops responding, and one tap
   recorded as two.
2. **P1-5 and P2-3** — until the unit tests are unhosted and the CRUD is testable, a green run isn't
   fully trustworthy evidence.
3. **P2-1 and P2-2** — cheap, and they stop the suite rotting silently.
4. **P1-3 and P1-4** — both grow worse the longer the app is used, but neither bites on day one.
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
