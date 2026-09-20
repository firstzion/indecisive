# Codebase review — Rand-o-matic (`Indecisive`)

Reviewed at `d576a23` (main, clean tree). Scope: all 4,907 lines of Swift across the
app, unit and UI test targets, plus `project.yml`, the README and the generated
`Info.plist`.

Everything in §0 was verified by running it on this machine, not inferred. File
references are `path:line` against `d576a23`.

**Two headline findings:**

1. **The snapshot suite was red at every commit in the repo's history**
   (§P0-1). Six of 55 unit tests failed on a clean checkout: six reference images
   had gone stale after deliberate UI edits. This is the *only* automated defence
   against one skin's changes breaking another skin's rendering, and while it was red
   it couldn't tell an expected mismatch from a real regression. *(Fixed — Phase 0.)*
2. **Adding a fourth skin costs 25 compiler errors across 12 files — plus 18 more
   decision sites the compiler stays silent about** (§2). That silent tail is the
   thing that will bite when Crystal Ball goes in. *(Fixed — Phase 1, P0-3.)*

**Status:** Phases 0, 1 and 2 (§4) are done. A bare fourth `SkinID` case now costs **8 compiler
errors across 8 files**, and a complete fourth skin — measured by writing one — **10 files**, with
every value decision in a single token file (§2). Phase 3 (per-skin art) and the owner's calls —
P1-10, P1-11, P2-7, P2-8, P2-10, P2-11 — are open. One bug found afterwards — the confetti
never fell, it spiralled off the screen (P1-12) — is fixed as well.

---

## 0. Verified baseline

| Check | Result |
|---|---|
| `xcodegen generate` | ✅ succeeds |
| `xcodebuild … build` | ✅ **BUILD SUCCEEDED**, 1 warning (`ItemRow.swift:54`, reported twice) |
| Unit tests (`IndecisiveTests`) | ❌ **55 executed, 6 failures** — all in `SnapshotTests` |
| UI tests (`IndecisiveUITests`) | ✅ 3 executed, 0 failures |
| README's documented test destination | ❌ does not resolve on this machine |

The README's `-destination 'platform=iOS Simulator,name=iPhone 17 Pro'` fails: that
device only exists at OS 26.5 here, and `xcodebuild` defaults to `OS:latest` (27.0).
Everything below was run with `…,name=iPhone 17 Pro,OS=26.5`.

*After Phase 0 (§4): 55/55 unit and 3/3 UI tests pass on that destination. The table above
is the state at `d576a23`.*

*Warnings: the `build` row is the app target only. A clean `build-for-testing` — everything
compiled — had **112**: 1 in the app (`ItemRow`), 1 in `ContrastTests` and 110 in the UI tests,
all Swift 6 main-actor-isolation diagnostics. An incremental build prints none for the files
it skips, so a clean one is the only reliable count. After P1-1: 0.*

---

## 1. Prioritized issues

### P0 — fix before adding another skin

---

#### P0-1. The snapshot suite fails on a clean checkout, and always has

**Where:** `IndecisiveTests/__Snapshots__/SnapshotTests/` (reference images)

**Status: fixed in Phase 0 (§4).** The rest of this entry is the diagnosis.

Six assertions fail:

```
testDetailSnapshots  : eightBall-default, eightBall-xxl
testRevealSnapshots  : eightBall-default, eightBall-xxl, prizeWheel-default, prizeWheel-xxl
testHomeSnapshots    : (all 6 pass)
```

These are not antialiasing noise. Re-recording and diffing pixel-for-pixel:

| Snapshot | Pixels changed | Max channel delta |
|---|---|---|
| `testRevealSnapshots.prizeWheel-default` | 320,036 / 3,013,524 (**10.6 %**) | 240 |
| `testRevealSnapshots.eightBall-default` | 181,871 / 3,013,524 (**6.0 %**) | 247 |
| `testDetailSnapshots.eightBall-default` | 3,338 / 3,013,524 (0.11 %) | 61 |
| every Gashapon snapshot | 0 | 0 |
| every Home snapshot | 0 | 0 |

**Why they fail — verified, not inferred.** All six references are *stale*: recorded
before four deliberate UI edits, and never re-recorded afterwards. I reverted those
edits one at a time in a scratch copy and re-ran the *old* references:

| Stale reference | Explained by | After reverting just that edit |
|---|---|---|
| 8-Ball Detail ×2 | row-index colour `#5C4E9E` → `#958BC6`, the contrast fix documented in `EightBall.swift` (the stale PNG's digits are exactly `#5C4E9E`) | matches bit-for-bit |
| 8-Ball Reveal ×2 | `SkinIconButton`'s 44 × 44 pt hit-target frame: it grows the 32 pt "✕" button's layout box, so the header is 12 pt taller and the reveal content re-centres 6 pt lower | matches bit-for-bit |
| Wheel Reveal ×2 | that same frame, **plus** the kicker growing 16 → 19 pt, 8 pt of clearance under it, and the pointer flipping from ▲ (which overlapped the kicker text) to ▼ resting on the rim | remaining diff is a 26 × 38 pt box on the screen midline — the pointer, nothing else |

Everything outside those edits is pixel-identical, so nothing else had regressed.

**This is not a regression from the Gashapon work.** I checked out and ran the suite
at every commit in the repo:

| Commit | Snapshot failures |
|---|---|
| `7fb307d` initial commit | 8 (the same 6, plus 2 gumball) |
| `fa0a911` remove Gumball | 6 |
| `d576a23` add Gashapon | 6 |

It has been red at every commit because the initial commit already contained code that
post-dates these images. It is **not** an environment problem: 12 of the 18 references
(every Home, every Gashapon, and the Wheel's Detail) match today's renderer with zero
differing pixels, so Xcode, the simulator and the OS rendered identically when they
were recorded.

**Why it matters more than the pixels:** snapshot tests are the only thing that would
tell you a change made for skin N altered skin N−1. The Gashapon skin was added on top
of a red suite — nobody could have distinguished "6 expected failures" from "6 expected
failures plus a real regression". Every future skin inherits that blind spot.

**Fix:**
1. Re-record all references on one pinned simulator + OS, and pin that destination in
   the README and in any CI job.
2. Add a tolerance so ordinary rendering drift doesn't turn the suite red again:
   `.image(precision: 1, perceptualPrecision: 0.98, layout: frame, traits: …)`. Keep
   `precision` at 1 — a `0.99` allowance lets 1 % of the frame differ, which would have
   passed the 0.11 % row-index colour change above.
3. Make green-before-merge the rule for any commit touching `Skins/`.

---

#### P0-2. Every skin-coverage test hardcodes the three current skins

**Where:** `IndecisiveTests/SnapshotTests.swift:22`, `ContrastTests.swift:27`,
`SkinTypographyTests.swift:38`, `SkinCopyTests.swift:72`, `SkinCopyTests.swift:84`
(and the explicit trio in `SkinCopyTests.swift:7-10`)

**Status: done.** `Skin.all` is in `Skin.swift`; all five literals and the explicit trio now
use it, and `testAllListsEverySkinIDExactlyOnceInOrder` pins its contract so it can't quietly
turn back into a hand-written list. Verified with a negative control: a deliberately broken
skin added to `Skin.all` in a scratch copy failed 13 test methods — contrast ×6, fonts ×1,
copy ×3 (including the contract test), snapshots ×3 — each message naming the skin. The
diagnosis below is the state before the fix.

Five separate literal arrays:

```swift
private let allSkins = [Skin.eightBall, Skin.prizeWheel, Skin.gashapon]
```

`SkinID.allCases` exists (`SkinID.swift:5`) and no test uses it. Add Crystal Ball and
it silently gets:

- no WCAG contrast check on any of its colours,
- no cross-check that its PostScript names exist in `FontRegistry`,
- no snapshots at any Dynamic Type size,
- no empty-state or pluralisation coverage.

Those are precisely the three things most likely to be wrong in a brand-new skin, and
nothing fails to tell you.

**Fix:** one derived list, used everywhere.

```swift
extension Skin {
    /// Every shipped skin. Derived from `SkinID.allCases` so a new skin is
    /// covered by every test that iterates this, automatically.
    static let all: [Skin] = SkinID.allCases.map(Skin.skin(for:))
}
```

---

#### P0-3. 18 per-skin decision sites fall through silently for an unknown skin

**Where:** see the full inventory in Appendix A.

**Status: done.** Every one of the 18 sites is now an exhaustive `switch` over the skin
with no `default:` — 15 switches in all, because some sites shared a decision (the shake
check two screens made separately is now one decision, and three ad-hoc confetti checks are
one — both tokens since Phase 2: `skin.traits.shakeToPick`, `skin.reveal.confetti`). Verified
four ways: (1) all 18 snapshot images
re-render **byte-identical**, with no tolerance; (2) the five sites the snapshots can't
see (confetti ×3, shake ×2) are pinned by new tests in `SkinBehaviourTests`, written from
the old code's values; (3) a grep audit finds no `skin.id ==`/`!=`, no ternary on the skin
and no `default:` left; (4) the bare-fourth-case experiment now gives **40 errors across
13 files** (was 25 across 12), the +15 landing exactly on the new switches, with no silent
site left. The diagnosis below is the state before the fix.

I added a fourth `SkinID` case in a scratch copy and built (whole-module mode, which
type-checks everything — an ordinary batched debug build stops at the first failing batch
and reports fewer). The compiler produced **25 "switch must be exhaustive" errors across
12 files** — a useful, complete to-do list. But it said nothing about 18 further sites that decide behaviour from
`skin.id` using a form the compiler can't check: `if skin.id == …`, a ternary, or a
`switch` with a `default:`.

Those 18 sites don't fail to compile. They quietly pick whatever the `else`/`default`
branch happens to be. Concretely, a new skin would silently inherit:

- a name card on the Reveal screen whether or not its design has one
  (`RevealCentrepiece.swift:46`)
- the Wheel's 18 pt button corner radius rule, i.e. fully-round buttons
  (`RevealActions.swift:92`)
- default action-button font sizes and heights (`RevealActions.swift:77, 86`)
- no border and no shadow on its action buttons (`RevealActions.swift:123, 139`)
- a circular icon button, never a rounded square (`IconButton.swift:60, 87`)
- confetti in the wrong shape and no outline (`Confetti.swift:87, 105`)
- **no shake-to-pick, with no indication that's a decision**
  (`RevealView.swift:62`, `ListDetailView.swift:64`)

**Fix:** delete every non-exhaustive form. Either promote the value to a token
(preferred — see §3) or write it as an exhaustive `switch` with no `default:`. The goal
is that adding a `SkinID` case makes the compiler enumerate *every* decision the new
skin has to make.

---

### P1 — should fix

---

#### P1-1. Swift 6 concurrency warnings — 112 on a full compile

**Where:** `Indecisive/Features/Detail/ItemRow.swift:54`, `ContrastTests.swift:93`, and both UI-test classes

**Status: done.** All one family, main-actor isolation. `ItemRow` now binds through `@Bindable`
(`$item.name`) instead of a non-`Sendable` rename closure, and `onRename` is gone;
`ContrastTests` and both UI-test classes are `@MainActor` (which cleared the 110 UI-test
warnings), with `HappyPathTests` moving to the async `setUp`, the main-actor-isolated variant.
A clean `build-for-testing` of the final tree: 0 warnings. The diagnosis below is the state before.

```
warning: converting non-Sendable function value to
'@isolated(any) @Sendable (String) -> Void' may introduce data races
```

`Binding(get:set:)` now wants a `@Sendable` setter; `onRename` is a plain stored
closure. The project is on `SWIFT_VERSION: 6.0`, so this is a real strict-concurrency
diagnostic, not noise.

The cleanest fix also removes an indirection: the only call site
(`ListDetailView.swift:156`) passes `{ item.name = $0 }`, a pure pass-through. Replace
the closure with a direct binding:

```swift
@Bindable var item: PickItem   // instead of `let item` + `onRename`
…
TextField("Item name", text: $item.name)
```

The test targets had the rest: `ContrastTests.swift:93` reads the main-actor-isolated
`RevealKicker.kickerColor` from a nonisolated test method, and the two UI-test classes make
110 calls into XCUITest's main-actor-isolated API from nonisolated ones. `@MainActor` on the
class clears each, as `SnapshotTests` already had.

---

#### P1-2. Reveal animation timings and the VoiceOver announcement are two unlinked sources of truth — and already disagree

**Where:** `RevealCentrepiece.swift:216, 243, 267` vs `RevealView.swift:83-87`

**Status: done (Phase 2).** `SkinMotion.revealIntro` owns the numbers. `RevealCentrepiece` animates
from them, and `RevealView.announcementDelay(for:reduceMotion:)` reads `revealIntro.winnerLegibleAfter`,
which is *computed from those same numbers* — so the two can't drift. The 8-Ball's announcement moves
from 1.00 s to **1.43 s** (the wobble's 1.08 s plus the answer's 0.35 s fade-in): a deliberate behaviour
change, the one this entry describes. The Wheel's 2.9 s and Gashapon's 0.85 s are unchanged.
`SkinMotionTests` pins all three, and checks that no skin can announce before its winner begins to
appear (an exhaustive switch, so a new intro has to say when its winner appears). The haptic patterns
moved into the same token (`revealHaptics`), and the idle animations (`heroBadge`, `ctaGlyph`,
`rerollGlyph`, `revealBackdrop`) into `IdleMotion`, applied by one `indIdle` modifier in place of six
hand-written copies of the same `@State` + `onAppear` block.

Snapshots can't see any of this — they run under Reduce Motion — so it was checked live. The original
build and the new one were recorded playing each skin's reveal on the same simulator and compared frame
by frame: the 8-Ball and Gashapon intros are pixel-identical from 0.4 s on (mean difference 0.2–0.4
out of 255, against 6 at the fast presentation frames where a one-frame alignment error dominates); the
Wheel's spin fits 4 turns over 2.8 s in both builds (3 or 5 turns, or 2.4 s or 3.2 s, fit worse in each) and
its name card appears at the same moment (+2.97 s vs +3.00 s); the hero badge's bob (5.9 pt and 9.8 pt, waveform
correlation ≥ 0.999), the CTA glyphs' spin rates, the re-roll wiggle and the glow / sunburst all match. **Not
checked:** how the haptics *feel* — the simulator has no Taptic Engine, so only their schedule is tested; try
a pick on each skin on a device. The diagnosis below is the state before.

`RevealCentrepiece` owns the intro animation durations. `RevealView` separately hard-codes
when to post the VoiceOver announcement, with a comment saying it is "timed to roughly
match each skin's own intro animation". Nothing enforces that.

For the 8-Ball it is already wrong:

| | value |
|---|---|
| wobble finishes (`RevealCentrepiece.swift:216`) | `0.09 × 2 × 6` = **1.08 s** |
| answer then fades in over (`:243`) | 0.35 s → fully visible at **1.43 s** |
| VoiceOver announces (`RevealView.swift:84`) | **1.00 s** |

So the winner is announced 80 ms before it begins to appear and 430 ms before it is
fully legible. Minor in isolation — but the Wheel's pair (2.8 s spin vs 2.9 s announce)
sits on the same unguarded coupling, and a new skin has to get two numbers right in two
files with nothing connecting them.

**Fix:** a `SkinMotion` token owning both. Note `PLAN.md §4.1` already specified
`SkinMotion` as part of `Skin`; it was never built.

---

#### P1-3. `GashaponPaint` is a skin-specific global reachable from 6 shared files

**Where:** `Gashapon.swift:96-104`, referenced from `RevealActions.swift` (×4),
`RevealCentrepiece.swift` (×2), `Confetti.swift` (×2), `IconButton.swift`,
`RevealView.swift`, `PrimaryCTA.swift`, plus `CapsuleBall.swift` and `OpenCapsule.swift`.

**Status: done (Phase 2), by a different route from the fix below.** Palette slots turned out to be the
wrong home. Once the reveal's colours became tokens (`SkinRevealStyle`), none of the six shared files needed
the paints any more, and `surfaceAlt` / `inkOnReveal` / `prizeAccent` would have been values only one skin uses,
forced onto the other two as dummies. Instead: the reveal's ink and cream are locals in `Gashapon.swift`; the
cream and the yellow prize ball — the two paints only the capsule *artwork* draws — are `CapsulePaint`, owned
by `CapsuleBall.swift` and named only by the capsule art, the CTA knob (a structural branch) and Gashapon's own
token file; `GashaponPaint` is gone; and `CapsuleBall` takes its ink as a parameter instead of reaching into
`Skin.gashapon`. No shared component names a skin's paints any more. Phase 3 will move that art, and
`CapsulePaint`, into a folder of its own. The diagnosis below is the state before.

`CapsuleBall.swift:47` goes further and reaches straight back into the skin registry
from a leaf view:

```swift
let seam = Skin.gashapon.palette.primaryText.opacity(seamOpacity)
```

The pattern doesn't scale: Crystal Ball will want its own off-palette paints, so skin #4
adds `CrystalBallPaint` and six more shared files gain a branch that reads it.

**Fix:** give `SkinPalette` the two or three genuinely-missing semantic slots
(`surfaceAlt` for Gashapon's cream, `inkOnReveal` for text on a loud reveal background,
`prizeAccent`), so every skin fills them and no component names a skin.

---

#### P1-4. Edit-mode controls have no accessibility labels, and no test coverage

**Where:** `ItemRow.swift:37-41` (delete), `ItemRow.swift:69-77` (reorder)

**Status: done.** Delete and both reorder controls now carry labels that name the item
("Delete Pho Palace", "Move Pho Palace up" / "down", with an "untitled item" fallback for the
moment a field is empty mid-edit), plus identifiers (`deleteItemButton-N`, `moveItemUpButton-N`,
`moveItemDownButton-N`, `itemNameField-N`, `editModeButton`).
`HappyPathTests.testEditModeReordersDeletesAndRenamesItems` drives edit mode end to end —
reorder, delete, rename, Done, back and reopen — and checks the labels; `AccessibilityTests`
checks them in-process too, and both fail when a label is broken. The diagnosis below is the
state before.

The delete button and both reorder chevrons are bare `Image(systemName:)` inside
`Button`s with no `accessibilityLabel`, so VoiceOver falls back to the symbols' generic
descriptions instead of saying what the button does or which item it acts on. They also
have no `accessibilityIdentifier`, which is why there is no UI test for edit mode at all —
rename, delete-item and reorder are entirely unexercised end-to-end.

**Fix:** `.accessibilityLabel("Delete \(item.name)")`, `"Move \(item.name) up"`,
`"Move \(item.name) down"`, plus identifiers, then a `HappyPathTests` case for edit mode.

---

#### P1-5. Swipe-to-delete is unreachable without the gesture

**Where:** `Indecisive/Skins/Components/SwipeToDeleteRow.swift`

**Status: done.** The row now has `.accessibilityAction(named: "Delete")`, which still asks for
confirmation rather than deleting outright. Verified by reading SwiftUI's accessibility tree
in-process, because XCUITest can neither list nor invoke custom actions: the row
`'Lunch Places, 2 wedges'` carries `["Delete"]` and no other node does.
`AccessibilityTests.testHomeRowOffersADeleteActionToAssistiveTechnology` keeps it that way —
removing the action fails it. It relies on a private libAccessibility symbol
(`_AXSSetAutomationEnabled`, what UI automation sets); if a future OS drops it, the test skips
with a message rather than failing.

Deleting a list from Home is a custom `DragGesture` with no
`.accessibilityAction(named:)`. VoiceOver and Switch Control users can't reach it.
There is a fallback (Detail → Edit → "Delete this list"), so it isn't a dead end, but the
primary affordance is invisible to assistive tech.

**Fix:** add `.accessibilityAction(named: "Delete") { onDeleteRequested() }` to the row.

---

#### P1-6. Home materialises every `Pick` row to display a count

**Where:** `HomeView.swift:16` and `HomeView.swift:161`

```swift
@Query private var picks: [Pick]
…
private var totalPickCount: Int { picks.count }
```

Every `Pick` object is fetched and kept live purely to read `.count`. `Pick` history
grows unbounded — `RevealModel.reroll()` writes one row per re-roll
(`RevealModel.swift:44`) and nothing ever prunes it — so a heavy user pays a growing
cost on every Home appearance.

The comment at `:11-15` explains why this replaced `PickService.totalPickCount`
(the `fetchCount` wasn't observed, so the footer didn't update). That reasoning is
right; the remedy just overshoots.

**Fix:** stop holding every row to read a count. A running counter — e.g. an `@AppStorage`
int bumped in `PickService.record`, which is observed (so the footer still updates) for free —
does it, though it then counts lifetime picks rather than the rows that survive a list
deletion, which is arguably the better meaning for "the ball has spoken N times".
Separately, decide on a retention policy for `Pick` (only the last N per list are ever read).

---

#### P1-7. Destructive UI ignores the skin

**Where:** `SwipeToDeleteRow.swift:38` (`.fill(Color.red)`), `ItemRow.swift:39`
(`.foregroundStyle(.red)`)

**Status: done (Phase 2).** `SkinPalette.destructive` / `onDestructive`, read by `SwipeToDeleteRow` and
`ItemRow`, and covered by two new `ContrastTests` (the trash glyph on the red, and edit mode's "minus" on the
card — both 3:1, as UI components). The values are today's system reds made explicit: what `Color.red` resolves to
on iOS 26 (`#FF383C` light, `#FF4245` dark — measured, and not the values iOS 17 uses), so nothing looks different.
Giving each skin its own red is a design call this leaves open. One nuance: a fixed hex no longer shifts with
the system's Increase Contrast setting the way `Color.red` did — as no other skin colour does either. Negative control: a pale Wheel red failed both new
tests at 1.74:1, naming the skin. The diagnosis below is the state before.

These are the only two raw colours in the whole app outside a skin definition — every
other colour goes through a token, which `Skin.swift:4-6` states as a rule. System red
on the 8-Ball's `#241B52` card is also not contrast-checked by anything.

**Fix:** a `palette.destructive` / `palette.onDestructive` pair, covered by
`ContrastTests`.

---

#### P1-8. The 🎨 Skins button can't be skinned

**Where:** `HomeView.swift:122`

```swift
SkinIconButton(skin: skin, glyph: "🎨", accessibilityLabel: "Skins", variant: .secondary, size: 36)
```

`SkinIconButton` applies `skin.type.body(…)` and `foregroundStyle(skin.palette.secondaryText)`
to the glyph. Neither the font face nor the foreground colour has any effect on an emoji
(only the point size carries over) — Apple Color Emoji is a colour font, so it renders in
its own fixed colours. The `.secondary` variant's foreground colour is dead code for this one
button, and the glyph is the one thing on Home that looks the same in every skin (the
button's shape and background do follow the skin).

**Fix:** an SF Symbol (`paintpalette`) or a per-skin glyph token.

---

#### P1-9. README's build/test destination doesn't resolve

**Where:** `README.md`, "Build & test from the CLI"

Verified above. Both documented commands fail with *"Unable to find a device matching
the provided destination specifier"*.

**Fix:** `-destination 'generic/platform=iOS Simulator'` for `build`, and a
version-pinned device for `test` (which the snapshot references must then be recorded
against — see P0-1). **Status: done (Phase 0).**

---

#### P1-10. Bundle identifier disagrees with the README

**Where:** `project.yml:65` vs `README.md:11`, and `project.yml:3`

```yaml
bundleIdPrefix: com.indecisive          # line 3 — now dead, overridden below
PRODUCT_BUNDLE_IDENTIFIER: com.Randomatic.app   # line 65
```

The README states the bundle ID is `com.indecisive.app`; the build actually produces
`com.Randomatic.app`. The `bundleIdPrefix` option no longer does anything because the
target sets the identifier explicitly.

Worth settling now rather than later: a bundle ID is effectively permanent once the app
is first submitted, and `com.Randomatic.app` is neither reverse-DNS-conventional
(capital R) nor consistent with the stated prefix.

#### P1-11. Edit-mode controls are far below the minimum tap target

**Where:** `ItemRow.swift` (delete button, reorder chevrons)

Measured from the accessibility frames, not estimated: the delete button is **18 × 18 pt** and
each reorder chevron is **11 × 6 pt**, against Apple's 44 × 44 pt minimum. The two chevrons are
stacked with 2 pt between them, so landing on the right one — or either — with a real fingertip
is luck, and the same tiny targets make Switch Control and Voice Control fiddly. Nothing has
flagged it because XCUITest taps element centres.

`SkinIconButton` already shows how to enlarge the target without enlarging the artwork
(`.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())`), but two stacked 44 pt
controls would double the row's height. So this needs a layout decision — up and down side by
side, or native drag-to-reorder (`onMove`), which `ItemRow`'s own header comment says was
deferred — which is why it wasn't a quick win.

---

#### P1-12. The confetti spiralled off the screen instead of falling

**Where:** `Confetti.swift` (`ConfettiPieceView`)

Found after Phase 2, from the owner's report that it "doesn't really fall across the screen in the
background". **Status: done.**

**Cause.** The piece applied `.offset(y:)` and *then* `.rotationEffect(_:)`. Modifiers apply in
sequence, so the rotation turned the already-offset piece about the point it had started from, and every
piece swung round the top of the screen on a widening spiral: on screen for about its first 0.4 s, in the
top ~40 pt, then off the left, top or right edge (a second brief pass through the lower half followed, at
under half opacity). The mockup's `translateY(…) rotate(…)` is the other way round — spin about its own
centre, then move. Measured on recordings of each skin's reveal, 2.5–10.5 s after the tap: **1.5–2.3
pieces moving on screen at a time**, all but a handful in the top fifth of the screen (Gashapon:
103 of 116 detections), and 0–3 straight-down steps. Swapping those two modifiers alone restored the fall.

**Why nothing noticed.** The confetti is hidden under Reduce Motion, which is how the snapshot tests run,
and an implicit `repeatForever` animation can't be inspected by a unit test. So for its whole life it had no
coverage of any kind — this is the gap P0-3 noted for confetti, gestures and shake, in the one place where the
missing test hid a real bug.

**Fix.** A piece's position is now a pure function of the clock — `ConfettiMotion.pose(of:at:containerHeight:)`,
the mockup's `pfm-fall` keyframes (fade in over the first 15 %, out over the rest, 520° of spin) — drawn by
`ConfettiField` inside a `TimelineView`, which is what PLAN.md §4.4 specified. That also fixes a second
deviation: `.delay(_:).repeatForever()` re-applied each piece's start delay on every cycle, leaving it out of
sight between falls, where the mockup's CSS applies the delay to the first pass only. `ConfettiTests` (9)
pin the path against the keyframes, that the shower covers every fifth of the screen at every moment, and —
by rendering the real view — that a piece is drawn straight below its own column at the height the function
says. With the original bug put back, the render test fails ("round piece nowhere on screen 20 % of the way
through its fall"). Verified live on all three skins: **7.7–11.8 pieces moving at a time**, in every fifth of
the screen, 510–850 straight-down steps, a median fall of 25 pt per 0.1 s (a ~3.75 s fall over the screen's
954 pt predicts 25.4), steady from second to second. Snapshots are byte-identical (confetti is hidden in them),
and the UI tests take the same 74 s as before, so the per-frame timeline doesn't upset XCUITest.

**Left as it was, for a design call.** Against the mockup: the 8-Ball's has three colours (lime, pink, cyan)
and dots and squares, where the app adds the card surface colour — `#241B52`, 1.28:1 on the reveal
background, so roughly one piece in four barely shows — and draws 1 : 1.6 rounded rectangles. The Wheel's
mockup pieces are red, teal and cream squares and circles; the app also includes yellow, which *is* the reveal
background (only its outline shows), and white. The mockup's fall stops at `translateY(620px)` on an ~852 pt
screen; the app's crosses the whole height, fading out at the bottom. The mockup has six pieces, the app ten.

---

### P2 — worth doing, not urgent

---

#### P2-1. No localization

~28 user-facing strings outside `SkinCopy` are hard-coded English literals — `"New List"`,
`"Cancel"`, `"Create"`, `"Flavour"`, `"Delete list?"`, `"Lists"`, `"Choose your toy"`,
`"Skins"`, `"Couldn't load your saved lists"`, plus `"Untitled"` at
`ListDetailView.swift:332`. `SkinCopy.swift:5-8` documents the String Catalog migration
as deliberately deferred, and `PLAN.md §6` anticipated `Localizable.xcstrings`. Fine as a
decision; just note the debt is larger than `SkinCopy` alone.

#### P2-2. Unguarded array indexing in `Confetti`

**Status: done (Phase 2).** No shared component indexes `flavors` any more: the confetti colours are
`skin.reveal.confetti.colors`, and `Confetti` guards against an empty list. Gashapon's own file still picks two of its
flavours by index — from the array literal a few lines above it, in the skin's own file.

`Confetti.swift:52` reads `skin.palette.flavors[0]` and `flavors[2]` directly. Safe today
(Gashapon ships 5 flavours) but it will crash if that palette is ever trimmed, and it's a
pattern a new skin will copy. `RowMarker.swift:11-15` shows the right shape
(`guard !flavors.isEmpty`, then `%`).

#### P2-3. `flavorIndex` isn't portable between skins

Palettes are different lengths — 3 (8-Ball), 4 (Wheel), 5 (Gashapon). `NewListSheet.swift:44`
offers the *current* skin's swatches, stores the raw index (`PickList.flavorIndex`), and
every renderer wraps with `% flavors.count`. So a list created as Gashapon's orange
(index 4) becomes the 8-Ball's cyan (index 1) after a skin switch, permanently. Probably
acceptable for a toy app, but it's an undocumented consequence and it gets worse with each
skin that has a different palette length.

#### P2-4. `RevealActions`' bespoke colour pairs aren't contrast-tested

**Status: done.** Three new `ContrastTests`: the accept / re-roll labels against their own fills
(translucency-aware — Gashapon's are blended over the reveal background first), the header
title against `revealBackground` (held to 4.5:1, since 15 pt bold is too near the "large text"
line to lean on it), and the "✕" glyph against its disc. So the tests can read the real values,
`RevealActionStyle.foreground` / `background`, `SkinIconButton.foreground` / `background` and
`RevealView.headerTextColor(for:)` are now internal (since Phase 2 the header and kicker colours are
tokens, `skin.reveal.headerText` and `skin.reveal.kicker.color`, which the tests read directly). Checked two ways: all 12 ratios match an
independent calculation to two decimals, and with three colours deliberately broken the new
tests failed on exactly those (Wheel accept 1.97:1, 8-Ball header and dismiss 1.0:1) while all
seven older contrast tests still passed — the gap this entry described. The diagnosis below is
the state before.

`ContrastTests` covers palette tokens but not the one-off literals at
`RevealActions.swift:111` and `:115`. The Wheel's accept button — `#FBF3E4` on `#1F9E8E` —
measures **3.00:1**. It clears WCAG AA's 3:1 large-text bar by 0.003, and would fail if
either shade moved at all. Same gap for `RevealView.headerTextColor` (`:125-131`), which
sits on `revealBackground`.

#### P2-5. No CI and no linter

No `.github/`, no SwiftLint or swift-format config. Given that the snapshot suite is the
main regression net for skins, it only protects anything if something runs it
automatically.

#### P2-6. No version numbers in `project.yml`

Neither `MARKETING_VERSION` nor `CURRENT_PROJECT_VERSION` is set, so the generated
`Info.plist` falls back to `1.0` / `1`. Since the plist is generated and gitignored,
there's currently nowhere in source to bump a release. `project.yml` already pins
`DEVELOPMENT_TEAM` and `TARGETED_DEVICE_FAMILY` for exactly this reason.

#### P2-7. Reveal kicker sizes have drifted from the mockup

The mockup sets the Wheel's reveal kicker at `16px Titan One`, `letter-spacing: .06em`; the
code uses 19 pt with the shared `.tracking(2)` (`RevealKicker.swift:25`), and has since the
first commit. The 8-Ball's is 14 pt extrabold with tracking 2 against the mockup's 13 px
regular at `.24em`; Gashapon's matches. It may be deliberate — 14 pt bold and 19 pt regular
both clear WCAG's "large text" threshold — but `ContrastTests.swift:90` still says "16pt
display", so the code and its own documentation disagree. Left as-is in Phase 0 (it's a
design call); changing the Wheel's means re-recording its two Reveal images.

#### P2-8. The snapshot images only hold on iOS 26.5, and Detail's don't cover its toolbar

On iOS 27.0, 17 of the 18 snapshots fail — on both devices tried (iPhone 18 Pro and
iPhone 17), while an iPhone 17 on 26.5 passes all 18, so it is the OS, not the device.
Reveal is near-identical (0.02–0.9 % of pixels); Home and Detail differ by 16–40 % because
`NavigationStack` lays out differently: content sits ~50 pt lower and Detail draws its
toolbar ("‹ Lists", title, "Edit"). That last part is the real finding: **the 26.5 renders
never draw that toolbar**, so nothing snapshot-tests the skinned back button, title or Edit
button today. On this machine a destination that doesn't pin the OS resolves to 27.0, so it
will be red. Options: fail (or skip) with a clear message when the OS isn't 26.5, and/or
record a second baseline once 27.x is the OS you target.

#### P2-9. Unit tests are app-hosted, and one run trapped inside SwiftData

`IndecisiveTests` is hosted by the real app, so its live `@Query` views coexist with the
in-memory containers the tests create and save. On the first launch of the app on an
iPhone 17 @ 26.5 simulator that had never had it installed (its log shows the app's store
didn't exist yet), `testRevealSnapshots` died with `EXC_BREAKPOINT` on the main thread inside
`SnapshotTests.makeRevealModel()`, in a SwiftData → `_SwiftData_SwiftUI` notification
observer. Not reproduced: the same device passed on the next run, and the pinned device took
15 iterations (45 tests) with no failures. Recorded in case it recurs.

#### P2-10. `project.yml` doesn't pin `swift-snapshot-testing`

`from: "1.17.0"` with no committed lockfile (the workspace's `Package.resolved` sits under
the gitignored `*.xcodeproj/`), so a fresh clone resolves whatever is newest that day —
1.19.5 today. For a library whose whole job is pixel comparison, that's a way for the suite
to go red with no code change. `exactVersion: "1.19.5"` in `project.yml` pins it (checked:
XcodeGen emits `kind = exactVersion`).

#### P2-11. Tapping Done with a text field focused logs "Modifying state during view update"

Renaming an item (or the list title) and then tapping **Done** makes SwiftUI log `Modifying state
during view update, this will cause undefined behavior.` It is pre-existing: the same line appears
with the old closure-style binding, **0 times when nothing is focused** and once when a field is,
and it was never seen because no earlier test tapped Done. The likely mechanism is that removing a
focused `TextField` as `isEditing` flips makes SwiftUI commit its text into the model mid-update.
It's a log line today — the value written is the one already there — but the message says
"undefined behavior". The fix is probably to resign first responder before `commitEdits()` and the
toggle in `editButton`. That's a focus-handling change, so it wasn't folded into the quick wins;
the edit-mode UI test exercises exactly this path and says so in a comment.

---

## 2. What adding a skin actually costs today

The Gashapon commit (`d576a23`) is a clean natural experiment. It touched **24 files**:

| Category | Files |
|---|---|
| The new skin itself | 1 (`Gashapon.swift`) |
| New Gashapon-only components | 2 (`CapsuleBall`, `OpenCapsule`) |
| **Shared components edited** | **10** |
| Shared screens edited | 1 (`RevealView`) |
| Registry / enum / token plumbing | 4 |
| Tests edited | 4 |
| Fonts, licences, README, project.yml | (the rest) |

I measured the compiler's contribution directly by adding a bare fourth case to
`SkinID` and building:

```
25 × "switch must be exhaustive" errors, across 12 files   (whole-module build)
```

That's the *good* part — it's a precise, complete to-do list for the exhaustive
switches. The problem is the other half:

| | count | compiler tells you? |
|---|---|---|
| Exhaustive `switch skin.id` | 25 sites / 12 files | ✅ yes |
| `if skin.id ==` / ternary / `switch … default:` | **18 sites** | ❌ **no** |
| Hard-coded test skin arrays | **5** | ❌ **no** |

So roughly **40 % of the skin-dependent decisions in the codebase give no signal when a
skin is added**, and the entire test suite silently continues to cover only the old
skins. *(After P0-2 and P0-3: no hard-coded test arrays and no silent sites; the same
experiment gives 40 errors across 13 files.)*

*(After Phase 2 — measured: a bare fourth case gives **8 errors across 8 files** — the registry and the seven
structural views. And a complete stand-in fourth skin, written in a scratch copy, builds having touched
**10 files**: `SkinID`, the registry, one new file holding all its tokens, and one arm in each of the seven
structural views. No test file was edited; the suite then reacted to the new skin by itself: the six snapshot
tests recorded their missing images, a contrast test flagged the stand-in's accept label at 2.92:1, and the copy
tests flagged strings it had copied from another skin. Before Phase 2 the same job meant 15 files, twelve of
them shared components each taking a value decision.)*

### The underlying cause

`PLAN.md §4.1` set a good rule:

> if two skins differ only in token values, put the difference in tokens. Use a
> component switch only when the layout or shape really differs.

The token bags never grew to hold everything that's a value, so the component switches
absorbed the overflow. Today they carry three quite different kinds of decision:

| Kind | Example | Belongs in |
|---|---|---|
| **Values** — colours, fonts, sizes, timings | `RevealKicker.swift:23-27` (which font), `RevealActions.swift:77-92` (sizes/radii), `RevealCentrepiece.swift:212-310` (durations/haptics) | tokens |
| **Capabilities** — does this skin do X? | `ListDetailView.swift:64` / `RevealView.swift:62` (shake to pick), `RevealCentrepiece.swift:46` (is there a name card?) | tokens |
| **Structure** — genuinely different view trees | `ListBadge`, `HeroBadge`, `RowMarker`, `PrimaryCTAGlyph`, `RevealGlow`, `RevealCentrepiece.shape` | per-skin code |

Only the third kind actually needs a switch. The first two are ~70 % of the sites. *(Phase 2 moved the first two
kinds into tokens; the third is what remains.)*

`SkinMotion` — listed in `PLAN.md §4.1`'s own `Skin` struct — was never built, which is
why all the animation timing ended up inline in `RevealCentrepiece`. *(Built in Phase 2.)*

---

## 3. Proposed architecture

Keep the existing shape. Grow the token layer to cover values and capabilities, and
(optionally, later) move structure into per-skin art packs.

> **Built in Phase 2, with these changes from the sketch below.** `SkinTraits` holds only `shakeToPick`: the
> compact-title font role went to `SkinTypography` (`compactTitleRole`, where a font choice belongs) and the
> confetti to `SkinRevealStyle` (it is the reveal's). `SkinMotion`'s two idle fields became `IdleMotion` values
> (`heroBadge`, `ctaGlyph`, `rerollGlyph`, `revealBackdrop`) beside a `RevealIntro` enum whose numbers the
> announcement is derived from, and the haptics are `[HapticBeat]`. `SkinRevealStyle` holds resolved `Color` and
> `Font` values, built in each skin's own file, rather than font-role specs. `SkinPalette` gained only
> `destructive` / `onDestructive` — not `surfaceAlt`, `inkOnReveal` or `prizeAccent` (see P1-3). `SkinShape`
> gained `ctaInsetShadow` and `iconButton`. `SkinArt` is still Phase 3. Every token initialiser takes every
> field, with no defaults, so a skin file that omits a decision doesn't compile.

```swift
struct Skin: Identifiable, Sendable {
    let id: SkinID
    let name: String
    let tagline: String

    let palette: SkinPalette        // + surfaceAlt, inkOnReveal, prizeAccent,
                                    //   destructive / onDestructive
    let type:    SkinTypography
    let shape:   SkinShape
    let copy:    SkinCopy

    let motion:  SkinMotion         // NEW
    let reveal:  SkinRevealStyle    // NEW
    let traits:  SkinTraits         // NEW
    let art:     SkinArt            // NEW (phase 3, optional)
}
```

### `SkinMotion` — one home for every timing and haptic

Absorbs `RevealCentrepiece.swift:209-327`, `RevealView.swift:79-88`,
`HeroBadge.swift:51/64/75`, `PrimaryCTA.swift:83/101`, `RevealActions.swift:175`.

```swift
struct SkinMotion: Sendable {
    /// How long the reveal intro runs before the winner is legible. The one
    /// number both the animation and the VoiceOver announcement read, so they
    /// cannot drift apart (they currently can — see REVIEW.md P1-2).
    let revealIntroDuration: Double
    let heroBadgeIdle: IdleAnimation      // .float(period:) / .spin(period:) / .none
    let ctaGlyphIdle:  IdleAnimation
    let revealHaptics: [HapticBeat]       // (offset, style)
}
```

Crucially, `RevealView.scheduleWinnerAnnouncement()` then reads
`skin.motion.revealIntroDuration` instead of its own table, and P1-2 stops being
possible.

### `SkinRevealStyle` — the reveal screen's own tokens

Absorbs `RevealKicker` entirely, `RevealView.swift:121-138`, and
`RevealCentrepiece.swift:46, 145-199`, `RevealActions.swift:76-143`.

```swift
struct SkinRevealStyle: Sendable {
    let colorScheme: ColorScheme
    let headerText:  Color
    let kickerFont:  FontRole          // .body(14, .extrabold) / .display(19)
    let kickerColor: Color
    let kickerBottomPadding: CGFloat

    let nameCard: NameCardStyle?       // nil == 8-Ball: no separate card at all
    let actions:  ActionButtonStyle    // axis, heights, radii, per-role fg/bg/border/shadow
}
```

Making `nameCard` an `Optional` is the important bit: it turns
`RevealCentrepiece.swift:46`'s silent `if skin.id != .eightBall` into a decision a new
skin is *required* to make.

### `SkinTraits` — capabilities, named

```swift
struct SkinTraits: Sendable {
    /// The 8-Ball's "ASK. SHAKE. OBEY." — shake the phone instead of tapping.
    let shakeToPick: Bool
    /// Wheel's Titan One reads too heavy at list-row density, so it drops to
    /// the body face. (Currently `Skin+CompactTitle.swift`.)
    let compactTitleUsesDisplayFont: Bool
    let confetti: ConfettiStyle        // shapes, outline, colour source
}
```

`ListDetailView.swift:64` and `RevealView.swift:62` become
`guard skin.traits.shakeToPick`, and a new skin has to answer the question rather than
silently defaulting to "no".

### `SkinArt` — only if you're going past ~5 skins

The six or seven genuinely-structural pieces become per-skin closures, so each skin owns
its own artwork in its own folder:

```swift
struct SkinArt: Sendable {
    let listBadge:   @MainActor @Sendable (BadgeContext)  -> AnyView
    let heroBadge:   @MainActor @Sendable (BadgeContext)  -> AnyView
    let rowMarker:   @MainActor @Sendable (MarkerContext) -> AnyView
    let ctaGlyph:    @MainActor @Sendable (CGFloat)       -> AnyView
    let rerollGlyph: @MainActor @Sendable ()              -> AnyView
    let backdrop:    @MainActor @Sendable ()              -> AnyView
    let centrepiece: @MainActor @Sendable (RevealContext) -> AnyView
}
```

**Honest trade-off:** this means `AnyView`, which erases the type and costs SwiftUI some
diffing precision. For leaf views drawn a handful of times per screen that's immaterial
here — but it is a real cost, and it's why I'd hold this phase back until the skin count
justifies it. Going 3 → 4 skins, phases 1 and 2 get you most of the benefit.

---

## 4. Implementation plan

Four phases, each independently shippable, each with a measurable exit criterion.

### Phase 0 — get to green (prerequisite) — ✅ done

Nothing else is trustworthy until the suite passes.

1. ✅ **README destination (P1-9).** `build` uses `generic/platform=iOS Simulator`; `test`
   pins `name=iPhone 17 Pro,OS=26.5`. Added a "Snapshot tests" section: what the images
   were recorded on, how to re-record, and the keep-it-green rule.
2. ✅ **Re-recorded the six stale references** with `RECORD=failed`, so only the
   mismatching images changed — the other 12 are untouched. Reviewed before/after first:
   every difference is one of the four deliberate edits listed in P0-1.
3. ✅ **Tolerance** — one shared `screen(_:)` strategy in `SnapshotTests` with
   `precision: 1, perceptualPrecision: 0.98`. *This deviates from the `precision: 0.99`
   originally proposed here:* a 1 % allowance would have passed the 8-Ball row-index
   regression (0.11 % of the frame) — the very drift that left these images stale.
   Checked the other way too: with the tolerance on, the six stale images still fail.

**Exit — met:** 55/55 unit tests and 3/3 UI tests pass on iPhone 17 Pro / iOS 26.5, in the
working tree and from a clean copy of the tracked files (regenerated project, the README's
literal destination string). 15 consecutive iterations of `SnapshotTests` gave 45 passes
and 0 failures, and an iPhone 17 at iOS 26.5 matches all 18 images. **The suite is not
green on iOS 27.0** (17 of 18 images fail) — see P2-8.

### Phase 1 — make the safety net skin-complete (~half a day, highest value) — ✅ done

1. ✅ Add `Skin.all` derived from `SkinID.allCases`; replace all five hard-coded arrays
   (P0-2).
2. ✅ Delete every non-exhaustive skin branch (P0-3, Appendix A) — promote to a token where
   one exists, otherwise rewrite as an exhaustive `switch` with no `default:`.
3. ✅ Extend `ContrastTests` to the reveal action pairs and header text (P2-4).
4. ✅ Fix the `ItemRow` Swift 6 warning (P1-1) and the accessibility gaps (P1-4, P1-5).

**Exit:** adding a bare `SkinID` case produces a compiler error for *every* skin-dependent
decision, and every existing test automatically covers the new skin. *Met after P0-2 +
P0-3 (measured: a bare fourth case now gives 40 errors across 13 files and no silent site).
Items 3 and 4 are done too, so Phase 1 is complete.*

This is the phase worth doing even if you do nothing else — it converts the 18 silent
decisions into compiler errors, which is the difference between "Crystal Ball renders
subtly wrong and we find out in review" and "Crystal Ball doesn't build until it's
complete".

### Phase 2 — move values and capabilities into tokens (~1–2 days) — ✅ done

1. ✅ Added `SkinMotion` (fixes P1-2 structurally), `SkinRevealStyle`, `SkinTraits`.
2. ✅ Added `destructive` / `onDestructive` to `SkinPalette` and retired `GashaponPaint` (P1-3) and the raw
   reds (P1-7). The other palette slots proposed here proved unnecessary — see P1-3 and §3.
3. ✅ Reduced `RevealKicker`, `RevealActions`, `IconButton`, `Confetti`, `Skin+CompactTitle` (deleted; now
   `SkinTypography.compactTitle`) and `RevealView` to zero `skin.id` references — and with them `PrimaryCTA`'s
   bottom lip (`SkinShape.ctaInsetShadow`), the name card and when it appears, the action buttons' layout and the
   dismiss disc's colours.

**Exit — met, with the wording sharpened.** No shared file makes a *value* decision from `skin.id`: the reads went
from 41 (in 14 files) to 9 — the seven structural views, the registry, and the skin picker tile's
`accessibilityIdentifier`, which is an identity rather than a decision — and `Features/` went from 4 to that one.
Verified: all 18 snapshots byte-identical to before (`TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all`, then `git status`
on the PNGs); a clean build with 0 warnings; 84 unit and 4 UI tests; negative controls on the new tests; and, for the
motion that snapshots can't see, a live frame-by-frame comparison against the original build (P1-2).

### Phase 3 — per-skin art packs (~1–2 days, optional)

Only if the roster is heading past five skins. Introduce `SkinArt`, move each skin's
structural views into `Skins/<SkinName>/`, and reduce `ListBadge`, `HeroBadge`,
`RowMarker`, `PrimaryCTAGlyph`, `RevealGlow` and `RevealCentrepiece` to thin dispatchers.

**Exit:** adding a skin touches 3 files (+1 new folder).

### Expected trajectory

| | files touched to add a skin | silent-failure sites |
|---|---|---|
| at `d576a23` | 24 | 18 + 5 test arrays |
| after Phase 1 | ~24, now compiler-guided | **0** |
| after Phase 2 — *measured* | **10**: three fixed (`SkinID`, the registry, the skin's own file) + 7 structural views | 0 |
| after Phase 3 (estimate) | ~3 | 0 |

Phase 1 doesn't reduce the file count much — it changes *how* you find them, from
eyeballing to following compiler errors. That's the change that actually protects the
existing skins. Phase 2 is what moves the count, and it changes *what* the edits are: every value
decision now sits in one file, and the seven that remain are "draw this skin's artwork" arms. (The ~6
estimated here originally left out those seven structural views; only Phase 3 removes them.)

---

## 5. The end state: adding a skin

After Phases 0–2, adding Crystal Ball is — as measured with a stand-in skin (§2):

1. Add `case crystalBall` to `SkinID`, and a line to `Skin.skin(for:)`.
2. Build. The compiler lists the seven structural views that need an arm for the new artwork
   (`ListBadge`, `HeroBadge`, `RowMarker`, `PrimaryCTAGlyph`, `RevealGlow`, `RevealActionGlyph`,
   `RevealCentrepiece.shape`).
3. Write `Skins/CrystalBall.swift` — tokens only, one file: `palette`, `type`, `shape`, `copy`, `motion`,
   `reveal`, `traits`, none with a default, so a decision left out doesn't compile.
4. Write the structural arms — the badge, marker, glyphs, backdrop and centrepiece.
5. Add its fonts to `FontRegistry` + `project.yml`, run `xcodegen generate`.
6. Run the tests. Contrast, font-resolution, copy and behaviour tests cover it automatically; record its
   six new snapshot images.

Steps 2 and 6 are the ones that didn't exist before Phase 1. After Phase 3, step 4 moves into the skin's own
folder and stops touching shared files.

---

## Appendix A — silent (non-exhaustive) skin branches

The 18 sites that needed rewriting or promoting in Phase 1. **Status: all 18 converted
(P0-3)** — the table is the state before. None of these produced a compiler error when a
`SkinID` case was added; each now does. **Phase 2 then moved every one of them into a token**,
so what a new skin owes for these is now a field in its own file rather than an arm in a shared one.

| File | Line | Form | Silent default for a new skin |
|---|---|---|---|
| `PrimaryCTA.swift` | 28 | `if skin.id == .gashapon` | no inset bottom lip |
| `RevealCentrepiece.swift` | 46 | `if skin.id != .eightBall` | gets a name card |
| `RevealCentrepiece.swift` | 171 | `if skin.id == .prizeWheel` | no name-card border |
| `RevealCentrepiece.swift` | 179 | ternary | no horizontal inset |
| `RevealCentrepiece.swift` | 185 | ternary | name card filled with `surface` |
| `RevealActions.swift` | 77 | `switch` + `default` | 19 pt labels |
| `RevealActions.swift` | 86 | `switch` + `default` | 62/56 pt heights |
| `RevealActions.swift` | 92 | ternary | fully-round buttons |
| `RevealActions.swift` | 123 | `switch` + `default` | no border |
| `RevealActions.swift` | 139 | `switch` + `default` | no shadow |
| `IconButton.swift` | 60 | ternary | circular icon buttons |
| `IconButton.swift` | 87 | `guard ==` | no border |
| `Confetti.swift` | 51 | ternary | `flavors + [surface]` |
| `Confetti.swift` | 87 | `if skin.id == .prizeWheel` | no confetti outline |
| `Confetti.swift` | 105 | ternary | 3 pt corner radius |
| `RevealKicker.swift` | 19 | ternary | no bottom padding |
| `RevealView.swift` | 62 | `guard ==` | **no shake-to-pick** |
| `ListDetailView.swift` | 64 | `guard ==` | **no shake-to-pick** |

(`RevealView.swift:62` and `ListDetailView.swift:64` are the same capability expressed
twice, so these 18 sites represent 17 distinct decisions.)

For reference, the 12 files that errored before P0-3 — these were already working as
intended: `Skin.swift` (the `Skin.skin(for:)` registry), `Skin+CompactTitle.swift`,
`RowMarker.swift`, `ListBadge.swift`, `HeroBadge.swift`, `PrimaryCTA.swift`,
`RevealGlow.swift`, `RevealKicker.swift`, `RevealActions.swift`, `RevealCentrepiece.swift`,
`IconButton.swift`, `RevealView.swift`.

---

## Appendix B — commands used

```bash
export PATH="$HOME/.local/xcodegen/bin:$PATH"
xcodegen generate

# build (the README's iPhone 17 Pro destination does not resolve)
xcodebuild -project Indecisive.xcodeproj -scheme Indecisive \
  -destination 'generic/platform=iOS Simulator' build

# test — pin the OS, or the device isn't found
xcodebuild -project Indecisive.xcodeproj -scheme Indecisive \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' test
```

To reproduce the "cost of a fourth skin" measurement: add a bare `case crystalBall` to
`SkinID` and build with `SWIFT_COMPILATION_MODE=wholemodule` added to the `xcodebuild`
command — the compiler then lists all 25 errors (an ordinary batched debug build stops at the
first failing batch and shows fewer), and Appendix A is what it missed. After P0-3 the same
experiment gives 40.
