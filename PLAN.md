# PickForMe — Implementation Plan

Source design: `design/PickForMe Directions.dc.html` (imported from claude.ai/design).
`design/support.js` is only the design-canvas runtime (it renders the mockup), not app code.

The design shows three directions — **1a Gumball**, **1b Midnight 8-Ball**, **1c Prize Wheel** — each
with the same three screens: **Home**, **List detail**, **The reveal**. It says "iOS bones stay standard;
the toy lives in the motif, palette and type", so we build **one app with one set of screens**, and a
**skin** supplies the palette, type, motif and copy. The user can pick any of the three skins.

---

## 1. Tech stack

| Concern | Choice | Why |
|---|---|---|
| Platform | Native iOS, SwiftUI | Mockups are 393×852 iPhone frames with standard iOS nav |
| Min OS | iOS 17 | `@Observable`, SwiftData, `sensoryFeedback`, `phaseAnimator` |
| Persistence | SwiftData | Small relational model (lists → items → picks) |
| Skin preference | `@AppStorage("skin")` | One value, needs no sync logic |
| Fonts | Bundled OFL Google Fonts | Custom type is central to every skin |
| Tests | XCTest + swift-snapshot-testing | Logic tests, plus a snapshot per skin × screen |

---

## 2. Product scope (from the mockups)

**Home**
- Big title, a subtitle line, a round "+" button (new list)
- One card per list: skin badge, name, count line, chevron
- Dashed "New list" row at the bottom of the stack
- Footer tagline (the 8-Ball skin shows a running total: "THE BALL HAS SPOKEN 412 TIMES")

**List detail**
- Nav bar: `‹ Lists` · list name · `Edit`
- Hero: animated badge + count headline + "last pick" line ("Last pick: Pho Palace, Tuesday")
- Grouped card of items, each with a skin row marker (dot / `01` index / square swatch)
- Dashed "add" row (inline text entry)
- Pinned bottom CTA: small caption + big **Pick For Me** button

**Reveal** (full-screen cover)
- List name + ✕ close
- Kicker ("And the winner is…" / "THE BALL HAS SPOKEN" / "WE HAVE A WINNER")
- Skin centrepiece that pops in, then the winner's name
- Supporting line ("Chosen out of 14. No takebacks.")
- Accept button and re-roll button
- Confetti (in the skin's shapes and colours)

**Not in the design, still needed** (design these to match each skin):
- Edit mode: rename, delete and reorder items, plus a delete-list option
- New-list sheet: name, plus a flavour colour for Gumball
- Empty states: a list with 0 or 1 items, and no lists at all
- **Skin picker** (see §5)

---

## 3. Data model & logic

```swift
@Model final class PickList {
    var name: String
    var flavorIndex: Int          // index into the skin's accent palette (Gumball capsule colour etc.)
    var sortOrder: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var items: [PickItem]
    @Relationship(deleteRule: .cascade) var picks: [Pick]
}

@Model final class PickItem {
    var name: String
    var sortOrder: Int
    var createdAt: Date
}

@Model final class Pick {             // history → "last pick", global counter
    var itemName: String              // snapshot, survives item deletion
    var date: Date
    var accepted: Bool
}
```

**`PickService`** (plain Swift, unit tested):
- `pick(from list, excluding: Set<ID>) -> PickItem?` picks uniformly at random, using an injectable RNG for tests
- A re-roll leaves out the winner just rejected, and resets once every item has been rejected
- `record(_:accepted:)` writes a `Pick` row; the "last pick" line uses the most recent accepted pick
- Guard rails: 0 items shows an empty state and disables the CTA; 1 item still works, with a joke line
- `totalPickCount` feeds the 8-Ball home footer

**First launch:** seed the five sample lists from the design (Lunch Places, Movie Night, Next Book to Read,
Makeup of the Day, Weekend Adventure) so the app never opens empty. The Lunch list gets the six mockup items.

---

## 4. Skin system (the core of this plan)

### 4.1 Shape

```swift
enum SkinID: String, CaseIterable, Identifiable { case gumball, eightBall, prizeWheel }

struct Skin {
    let id: SkinID
    let palette: SkinPalette       // semantic colour tokens
    let type: SkinTypography       // display / body / mono Fonts
    let shape: SkinShape           // radii, border widths, shadow style
    let copy: SkinCopy             // all the tone-of-voice strings
    let motion: SkinMotion         // which idle animation the hero badge uses, etc.
}
```

- Inject with `.environment(\.skin, Skin.for(storedSkinID))` at the root.
- Screens read **only semantic tokens** (`skin.palette.background`, `skin.type.display(36)`), never hex values.
- The visual pieces that differ in *structure*, not just colour, live in one `SkinComponents` file.
  Each one is a `@ViewBuilder` that switches on `skin.id`:
  - `ListBadge(list)` — glossy capsule / black ball with a neon diamond / conic pie with N wedges
  - `HeroBadge(list)` — the same badge, larger, with a float or spin animation
  - `RowMarker(index, flavor)` — coloured dot / `01` mono index / outlined square swatch
  - `CardStyle` ViewModifier — soft drop shadow / 1px neon border / 3px ink border with a hard offset shadow
  - `DashedAddRow(label)`
  - `PrimaryCTA` ButtonStyle, plus the small CTA glyph (gumball / "8" ball / mini spinning wheel)
  - `RevealCentrepiece(winner)` — open capsule / 8-ball with the answer in the diamond window / wheel with pointer
  - `RevealActions` — stacked pills (Gumball and 8-Ball) or side-by-side blocks (Wheel)
  - `ConfettiPiece` — rounded rects and circles / diamonds and dots / outlined squares and circles
- The rule: if two skins differ only in token values, put the difference in tokens. Use a component
  switch only when the layout or shape really differs. This keeps screens as shared code and each
  skin's "toy" in one place.

### 4.2 Token values from the design

| Token | Gumball (1a) | Midnight 8-Ball (1b) | Prize Wheel (1c) |
|---|---|---|---|
| background | `#FFF8EC` | `#140F2E` | `#FBF3E4` |
| surface (cards) | `#FFFFFF` | `#241B52` (border `#362A72`) | `#FFFFFF` (border `#17130F` 3pt) |
| ink / primary text | `#2B1B12` | `#F2EEFF` | `#17130F` |
| secondary text | `#7E6553` | `#9186C4` | `#6E655B` |
| tertiary text | `#8E7460` | `#7C6FC0` | `#7C7167` |
| chevron | `#D6C4B4` | `#5C4E9E` | `#17130F` |
| row divider | `#F4EBE0` | `#322766` | `#17130F` 2pt |
| dashed border | `#E3D2C0` 2.5pt | `#3E3183` 2pt | `#C9B89C` 3pt |
| accent / CTA | `#FF3B5C` | `#C8FF4D` (text `#140F2E`) | `#F0503C` (text `#FBF3E4`) |
| flavour palette | `#FF3B5C #7B5CFF #35D6A6 #FF7AB8 #FFB020` | `#FF4FD8 #4DE1FF #C8FF4D` | `#F0503C #FFC93C #1F9E8E #FBF3E4` |
| reveal background | accent `#FF3B5C` | `#0B0818` + pulsing lime glow | `#FFC93C` |
| display font | Baloo 2 ExtraBold | Lilita One (UPPERCASE) | Titan One |
| body font | Nunito SemiBold/Bold | Space Grotesk (+ DM Mono for indices) | Work Sans SemiBold/Bold |
| card radius | 22 | 20 | 18 |
| CTA shape | pill, 66h, soft coloured shadow + inner bottom shade | pill, 68h, lime glow | rounded rect (r20), 68h, 3pt border + 5/5 hard shadow |
| status bar | dark (light on reveal) | light | dark |

### 4.3 Copy per skin (`SkinCopy`)

| Slot | Gumball | 8-Ball | Wheel |
|---|---|---|---|
| home subtitle | "{n} lists · infinite indecision" | "ASK. SHAKE. OBEY." | "Step right up, pick a wheel" |
| count line | "{n} things" ¹ | "{n} items" | "{n} wedges" |
| new list row | "New list" | "Start a new list" | "Build a new wheel" |
| home footer | "Can't decide? That's the whole point." | "THE BALL HAS SPOKEN {total} TIMES" | "Everybody wins. Eventually." |
| detail headline | "{n} things to eat" ¹ | "{n} CANDIDATES" | "{n} wedges loaded" |
| last pick | "Last pick: {x}, {day}" | "Ball last said: {x}" | "Last spin landed on {x}" |
| add row | "Add something tasty" ¹ | "Throw one in the ring" | "Add a wedge" |
| CTA caption / label | "Let fate decide" / "Pick For Me" | "THE 8-BALL KNOWS" / "PICK FOR ME" | "Give it a whirl" / "PICK FOR ME" |
| reveal kicker | "And the winner is…" | "THE BALL HAS SPOKEN" | "WE HAVE A WINNER" |
| reveal support | "Chosen out of {n}. No takebacks." | "Beat {n-1} other contenders. Arguing with a ball is undignified." | "The wheel does not negotiate." |
| accept / reroll | "Sold, let's go" / "Nope, roll again" | "LOCK IT IN" / "SHAKE AGAIN" | "LOCK IT IN" ² / "SPIN AGAIN" |

¹ The Gumball mockup uses list-specific nouns ("14 things to eat", "23 maybes", "9 on the pile").
  Plan: ship the generic string, and add an optional per-list `countPhrase` later if wanted.
² The mockup says "EATING IT", which only fits the Lunch list. Use a generic label. See open questions.

Put every string in a String Catalog (`Localizable.xcstrings`), with keys namespaced by skin, and use
real plural rules.

### 4.4 Motion (CSS keyframes → SwiftUI)

| Design keyframe | Used for | SwiftUI |
|---|---|---|
| `pfm-pop` .7s `cubic-bezier(.34,1.56,.64,1)` | reveal centrepiece + winner card (+.12s delay) | scale .72→1, rotate −6°→0, `.spring(response: 0.55, dampingFraction: 0.58)` |
| `pfm-float` 3.4s | Gumball / 8-Ball hero badge | `phaseAnimator` offsetting y by 0 → −10 |
| `pfm-spin` 9s / 2.4s | Wheel hero badge, CTA glyph | `rotationEffect` with a linear repeating animation |
| `pfm-wiggle` 1.2s | re-roll button glyph | ±4° rotation, repeating |
| `pfm-fall` 3–4.5s | confetti | `TimelineView(.animation)` + `Canvas`, about 9 particles, staggered delays |
| `pfm-glow` 2.6s | 8-Ball reveal halo | opacity .45↔1 on a radial gradient |

**The toy moment, by skin.** A pick should feel like the skin's toy:
- **Gumball:** capsule drops and pops open, then the winner card pops in. Haptic `.impact(.soft)` then `.success`.
- **8-Ball:** tapping the CTA *or shaking the phone* (motion shake) triggers a ~0.6s ball wobble, then the answer
  fades in the diamond window. Haptic: rigid ticks.
- **Wheel:** the wheel really spins and decelerates onto the winner's wedge before the name card
  appears. The wedge angle comes from the chosen index. Haptic `.selection` per wedge passed, slowing down.

**Reduce Motion:** turn off confetti, float, spin and the wheel spin-up. Keep a simple crossfade and scale.

---

## 5. Skin picker (not in the design, needs a design pass)

**Recommended UX:**
1. A **"Skins" sheet**, opened from a small palette/gear button in the Home header next to "+".
   (Alternative: long-press the title. It's playful but hard to find, so offer it as an extra entry point.)
2. The sheet shows **three live preview tiles**. Each tile renders a real `ListCard` and `PrimaryCTA` in that
   skin by overriding `.environment(\.skin, …)`, so previews can't drift from the real skin.
   Each tile has its name and tagline from the design:
   - Gumball: "Cream ground, candy capsules, every list gets its own flavour."
   - Midnight 8-Ball: "Dark arcade cabinet, neon answers, the ball does the talking."
   - Prize Wheel: "Fairground stickers, hard black outlines, wedges everywhere."
3. Tapping a tile writes `@AppStorage("skin")`. The root crossfades (`.animation(.easeInOut, value: skinID)`)
   and plays a light haptic. Selection updates everywhere at once.
4. **Onboarding:** on first launch, show the same picker as a "Choose your toy" step before Home.
5. **Optional extra:** alternate app icons per skin (`UIApplication.setAlternateIconName`), with a toggle
   in the sheet ("Match app icon").

---

## 6. Project structure

```
PickForMe/
├─ PickForMe.xcodeproj            (or project.yml via XcodeGen)
├─ PickForMe/
│  ├─ App/            PickForMeApp.swift, RootView.swift, SeedData.swift
│  ├─ Model/          PickList.swift, PickItem.swift, Pick.swift
│  ├─ Logic/          PickService.swift, RandomSource.swift
│  ├─ Skins/
│  │  ├─ Skin.swift, SkinID.swift, SkinEnvironment.swift
│  │  ├─ Tokens/      SkinPalette.swift, SkinTypography.swift, SkinShape.swift, SkinCopy.swift
│  │  ├─ Gumball.swift, EightBall.swift, PrizeWheel.swift     (token instances)
│  │  └─ Components/  ListBadge, HeroBadge, RowMarker, CardStyle, DashedAddRow,
│  │                  PrimaryCTA, RevealCentrepiece, RevealActions, Confetti, WheelShape
│  ├─ Features/
│  │  ├─ Home/        HomeView.swift, ListCard.swift, NewListSheet.swift
│  │  ├─ Detail/      ListDetailView.swift, ItemRow.swift
│  │  ├─ Reveal/      RevealView.swift, RevealModel.swift
│  │  └─ SkinPicker/  SkinPickerSheet.swift, SkinPreviewTile.swift
│  └─ Resources/      Fonts/*.ttf, Assets.xcassets (incl. alt icons), Localizable.xcstrings
├─ PickForMeTests/    PickServiceTests, SkinCopyTests, SnapshotTests
├─ PickForMeUITests/  HappyPathTests
└─ design/            imported mockup (reference only)
```

---

## 7. Build phases

### Phase 0 — Setup (½ day)
- Create the Xcode project (iOS 17, SwiftUI, SwiftData). XcodeGen is recommended so the project file stays diff-able.
- Download and bundle the fonts: Baloo 2, Nunito, Lilita One, Space Grotesk, Titan One, Work Sans, DM Mono
  (all SIL OFL). Register them in `UIAppFonts` and add a debug check that every PostScript name resolves.
- Add swift-snapshot-testing via SPM.

### Phase 1 — Model & logic (1 day)
- SwiftData models, model container, first-launch seed.
- `PickService` with an injectable RNG. Unit tests cover uniformity (roughly), re-roll exclusion, reset after
  all items are rejected, the empty list, and the one-item list.

### Phase 2 — Skin foundation (1½ days)
- `Skin`, `SkinID`, token structs, and the three token instances from §4.2 and §4.3.
- Environment key and root injection from `@AppStorage`.
- `Font` helpers use `Font.custom(_:size:relativeTo:)` so Dynamic Type scales.
- Build each component in `Skins/Components` with an Xcode Preview grid showing all three skins side by side.
  That grid is the main way to check the work against the mockup.

### Phase 3 — Screens with the Gumball skin first (2 days)
- `HomeView`: `NavigationStack`, custom large header (the design hides the system large title), a
  `ScrollView` of `ListCard`s, dashed new-list row, footer, and the "+" button opening `NewListSheet`.
- `ListDetailView`: custom toolbar tint and title font, hero, items card, inline add row
  (`TextField` shown in place of the dashed row), `safeAreaInset(edge: .bottom)` for the CTA with the
  background-fade gradient.
- Edit mode: swipe-to-delete, `onMove` reorder, rename by tapping in edit mode, delete list.
- `RevealView` as a `fullScreenCover`: `RevealModel` holds the current winner and the rejected set.
  Accept records the pick and dismisses. Re-roll records a rejection and re-runs the reveal animation.

### Phase 4 — 8-Ball and Wheel skins (2 days)
- Fill in the component switch cases for both skins. Screens should need no changes. If one does,
  move that difference into a component.
- `WheelShape`: a `Canvas`-drawn pie with N wedges cycling the flavour palette, an ink border, and a pointer
  triangle. The Home badge uses the *list's own item count* for its wedges (capped at about 8 so it stays readable).
- Wheel spin: compute the target angle so the pointer lands on the winner's wedge, then animate
  with `timingCurve(0.15, 0.85, 0.25, 1, duration: 2.8)`.
- 8-Ball: diamond window with the uppercase winner, `minimumScaleFactor` for long names, the glow halo,
  and shake detection (`UIWindow` `motionEnded` bridged into a SwiftUI modifier).

### Phase 5 — Skin picker & onboarding (1 day)
- `SkinPickerSheet` with live preview tiles, header entry point, first-launch onboarding step,
  crossfade on change, and optional alternate icons.

### Phase 6 — Polish & accessibility (1½ days)
- Haptics per skin (`.sensoryFeedback`).
- Reduce Motion paths. VoiceOver labels ("Pick for me, chooses randomly from 14 items"); the reveal
  announces the winner.
- Dynamic Type at the largest sizes: cards wrap, the CTA grows, the reveal card scrolls if needed.
- Contrast check. Known risk spots: Gumball tertiary `#8E7460` on `#FFF8EC`, 8-Ball `#7C6FC0` on `#140F2E`.
  Darken these tokens slightly if they fail AA for body text.
- Empty states per skin. Long names: truncate on cards, balance-wrap on the reveal.

### Phase 7 — Testing & ship (1 day)
- Snapshot tests: {Home, Detail, Reveal} × {3 skins} × {light Dynamic Type default, XXL} on an iPhone 15/16
  simulator (393×852, the mockup size). Record baselines, then compare by eye against the design.
- UI test: create a list, add 3 items, pick, re-roll, accept, check the "last pick" line, switch skin, and
  check that the state persists.
- App icon(s) and launch screen tinted to the default skin.

**Rough total: about 10–11 working days for one developer.**

---

## 8. Open questions

1. **Platform:** is native SwiftUI iOS right, or should this also run on Android and web (React Native / Flutter)?
   The plan assumes iOS only, based on the mockups.
2. **Default skin** on first launch, or always make the user choose at onboarding?
3. **Per-list phrasing:** keep Gumball's custom count nouns ("23 maybes") and the Wheel's contextual accept
   verb ("EATING IT") as optional per-list fields, or go generic?
4. **Skin scope:** global only (plan), or also a per-list override?
5. **iCloud sync** (SwiftData + CloudKit): in or out for v1?
6. Should the skin picker, edit mode, new-list sheet and empty states go back to Claude Design for mockups
   before Phase 3?
