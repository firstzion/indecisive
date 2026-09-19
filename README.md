# Rand-o-matic

A "can't decide?" list-and-random-picker iOS app. See [PLAN.md](PLAN.md) for the
original implementation plan. The app ships its visual skins as a user-selectable
choice — currently Midnight 8-Ball and Prize Wheel. (PLAN.md also describes a
third skin, Gumball, which has since been removed from the app.)

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
xcodebuild -project Indecisive.xcodeproj -scheme Indecisive \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild -project Indecisive.xcodeproj -scheme Indecisive \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Project layout

```
Indecisive/
├─ App/            Entry point, root view, font registry
├─ Model/          SwiftData models (Phase 1)
├─ Logic/          PickService — the random-pick logic (Phase 1)
├─ Skins/          Skin tokens (palette/type/shape/copy) + per-skin components (Phase 2+)
├─ Features/       Home, Detail, Reveal, SkinPicker screens (Phase 3+)
└─ Resources/
   ├─ Fonts/       Bundled OFL Google Fonts (Lilita One, Space Grotesk,
   │                Titan One, Work Sans, DM Mono) + LICENSES/
   └─ Assets.xcassets
design/            Reference-only export of the original Claude Design mockup —
                    not app code.
```

## Fonts

All five families are SIL Open Font License (OFL) fonts pulled from
[google/fonts](https://github.com/google/fonts); license texts are bundled in
`Indecisive/Resources/Fonts/LICENSES/`. Two (Space Grotesk and Work Sans) are
variable fonts shipped as a single `.ttf`; `FontRegistry.swift` lists every
PostScript name the app uses and asserts on launch (DEBUG only) that each one
actually resolves — variable font named-instance naming isn't always
predictable from the font file alone, so this check is the source of truth,
not the table in PLAN.md.
