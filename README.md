# Rand-o-matic

A "can't decide?" list-and-random-picker iOS app. See [PLAN.md](PLAN.md) for the
original implementation plan. The app ships its visual skins as a user-selectable
choice — currently Midnight 8-Ball, Prize Wheel, Gashapon and Crystal Ball.
(PLAN.md also describes a third skin, Gumball, which has since been removed
from the app.)

(The app displays as "Rand-o-matic" on the home screen and in onboarding.
Everything else — bundle ID, Xcode project/target/scheme, Swift module name,
and source folders — uses the unrelated technical name "Indecisive"
(`com.indecisive.app`), which only needs to stay internally consistent, not
match the on-screen brand. Two earlier names — the internal codename
"PickForMe", then briefly "Wizard of Odds" — didn't clear trademark/App Store
availability checks and still show up in PLAN.md's history.)

## Setup

The Xcode project is **generated, not committed** — [project.yml](project.yml) is
the source of truth (via [XcodeGen](https://github.com/yonaskolb/XcodeGen)).

```bash
xcodegen generate   # regenerate Indecisive.xcodeproj + Info.plist after editing project.yml
open Indecisive.xcodeproj
```

If `xcodegen` isn't installed:

```bash
brew install xcodegen
```

## Build & test from the CLI

```bash
# Build — any simulator will do, so don't name one.
xcodebuild -project Indecisive.xcodeproj -scheme Indecisive \
  -destination 'generic/platform=iOS Simulator' build

# Test — pin the device *and* the OS.
xcodebuild -project Indecisive.xcodeproj -scheme Indecisive \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' test
```

Naming only the device (`name=iPhone 17 Pro`) means "on the newest OS installed",
so on a Mac that also has a newer runtime — iOS 27 has no iPhone 17 Pro — it fails
with *Unable to find a device matching the provided destination specifier* before
anything compiles. `xcodebuild -showdestinations -project Indecisive.xcodeproj
-scheme Indecisive` lists what your machine has.

### Snapshot tests

`SnapshotTests` renders Home, Detail and Reveal for every skin, at default and XXL
Dynamic Type, and compares each against a PNG in `IndecisiveTests/__Snapshots__/`.
Those were recorded on an **iPhone 17 Pro running iOS 26.5** (a 3× device: each image
is 1179 × 2556), which is why the test destination above is pinned to it. Other 3×
iPhones on iOS 26.5 match (an iPhone 17 was checked); **iOS 27.0 does not** — it lays
out the navigation screens differently (Home and Detail render about 50 pt lower, and
Detail draws its toolbar), so 17 of the 18 images fail there.

A mismatch means a screen no longer looks like its reference. If the change is
deliberate, re-record the image **in the same commit as the change**; if it isn't,
you've found a regression. Keep the suite green before merging anything under
`Skins/` or `Features/` — a suite that is already red can't tell an expected
mismatch from a real one.

To re-record, run the tests with recording turned on. Each image it writes is
reported as a failure and the run exits non-zero; that is expected. Run again
without the variable to confirm it is green.

```bash
TEST_RUNNER_SNAPSHOT_TESTING_RECORD=failed xcodebuild -project Indecisive.xcodeproj \
  -scheme Indecisive -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:IndecisiveTests/SnapshotTests test
```

`failed` re-records only the snapshots that currently mismatch (`all` redoes every
one; the default, `missing`, only records images that don't exist yet). Look at the
new images before you commit them — recording accepts whatever the app draws today.
Add `TEST_RUNNER_SNAPSHOT_ARTIFACTS=<dir>` to a normal run to get the newly rendered
images written to `<dir>/SnapshotTests/`, ready to compare side by side.

## Project layout

```
Indecisive/
├─ App/            Entry point, root view, font registry
├─ Model/          SwiftData models (Phase 1)
├─ Logic/          PickService — the random-pick logic (Phase 1)
├─ Skins/          Skin tokens (palette, type, shape, copy, motion, reveal, traits) + the components that draw them
├─ Features/       Home, Detail, Reveal, SkinPicker screens (Phase 3+)
└─ Resources/
   ├─ Fonts/       Bundled OFL Google Fonts (Lilita One, Space Grotesk,
   │                Titan One, Work Sans, DM Mono, Mochiy Pop One,
   │                M PLUS Rounded 1c, Bagel Fat One, Nunito) + LICENSES/
   └─ Assets.xcassets
design/            Reference-only export of the Claude Design mockups (every skin
                    direction, including Gashapon and Crystal Ball) — not app code.
```

## Adding a skin

Everything a skin decides lives in one token file; the compiler and the tests do the checklist.

1. Add a `case` to `SkinID` and a line to `Skin.skin(for:)`.
2. Build. The seven views that draw a skin's artwork — `ListBadge`, `HeroBadge`, `RowMarker`,
   `PrimaryCTAGlyph`, `RevealGlow`, `RevealActionGlyph` and `RevealCentrepiece` — each need an arm.
3. Write `Skins/<Name>.swift`. A `Skin` takes a `palette`, `type`, `shape`, `copy`, `motion`, `reveal` and
   `traits`, and none of their initialisers has a default: a decision you leave out doesn't compile.
4. Add its fonts to `FontRegistry` and `project.yml`, then run `xcodegen generate`.
5. Run the tests. Contrast, fonts, copy and behaviour cover the new skin automatically (they iterate
   `Skin.all`); record its snapshot images (see [Snapshot tests](#snapshot-tests)).

[REVIEW.md](REVIEW.md) §2 and §5 have the reasoning and a measured trial.

## Fonts

All nine families are SIL Open Font License (OFL) fonts pulled from
[google/fonts](https://github.com/google/fonts); license texts are bundled in
`Indecisive/Resources/Fonts/LICENSES/`. Three (Space Grotesk, Work Sans and
Nunito) are variable fonts shipped as a single `.ttf`. Mochiy Pop One, M PLUS
Rounded 1c and Bagel Fat One are trimmed to Latin characters (the `-Latin.ttf`
files): the originals include Japanese or Korean and run 1.5–5 MB each, and the
OFL reserves no font name for any of them, so trimming is allowed.
`FontRegistry.swift` lists every
PostScript name the app uses and asserts on launch (DEBUG only) that each one
actually resolves — variable font named-instance naming isn't always
predictable from the font file alone, so this check is the source of truth,
not the table in PLAN.md.
