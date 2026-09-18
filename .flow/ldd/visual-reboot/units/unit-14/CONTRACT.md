# Unit 14 — Type, palette and surface authority

Status: **approved 2026-09-18, with monospace retired outright.** Awaiting an
execution-grade plan and its own separate plan approval before any code.
Type: parity implementation. First of the recut roadmap's visual units.
Base: `residuum-visual-reboot-13` at `5ac1a49` (U13.1 closed at `03e8c0c`;
`5ac1a49` is the docs-only approval commit on top, no production seam moved)
Visual reference: all ten frames of
`.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`
Authority for appearance: `units/unit-13/VISUAL-SYSTEM.md` sections 1–4 and 9
Source grounding: `units/unit-13/recon.md`

## Outcome

The application speaks one visual language. Two authored typefaces carry
display and text, monospace is gone from the application entirely, one
token module is the single source of colour and type, and every screen root
opts into a theme so no stock Material control can render in Material 3's
default palette again. The HP and Mana meters become one component with a
hue fill, a number and a label, legible in greyscale.

Nothing about row anatomy, control geometry, icons, illustration placement or
the dungeon renderer changes here. This unit gives the later ones their
vocabulary.

## Why it is first

Every unit from U15 to U21 consumes these tokens. It is also the cheapest
large win in the epic: on frames 6, 8, 9 and 10 the most visible defect is
Material 3's default lavender, and that is not a styling choice — it is the
absence of a theme (`recon.md`, and `main.dart:81-85`, `:169-172`).

## What changes

### Typography

Bundle **Spectral** (text) and **EB Garamond** (display), both SIL Open Font
License 1.1, with their `OFL.txt` committed beside them. Weight budget: at
most two faces per family, and the unit states which and why. Declare them in
`packages/app/pubspec.yaml`, whose `fonts:` block is still the commented
Flutter template.

Three roles, from `VISUAL-SYSTEM.md` section 1:

- **Display** — place names, screen titles, taglines, section captions;
  letterspaced roman capitals.
- **Text** — row titles, purposes, prose, log sentences, chip labels.

There is **no third role**. Monospace is retired: the mock uses none, not even
for `14/20` or `Strength 8`, and the standing instruction is parity with the
mock rather than a compromise with the old identity.

**Numeric alignment comes from layout and OpenType, not from the font's
advance width.** The town already aligns its marking columns with a
fixed-width slot, `markColumn = 28` (`town_style.dart:31`), and its own
dartdoc says why: "the markings are not all one cell wide in the device's
monospace font". Monospace never aligned them. Where digits must not jitter —
the meters, the stat columns, the depth pair, prices — use the text face's
tabular figures (`FontFeature.tabularFigures()`), and a fixed-width slot
where a whole column must hold still. **Verify the shipped face actually
carries `tnum` before relying on it**; if it does not, the fallback is the
fixed-width slot and the unit says so.

Every one of the roughly fifty `fontFamily: 'monospace'` sites resolves
through the token module afterwards. There are inline literals in `main.dart`,
`game/pack_screen.dart`, `town/character_screen.dart`, `forge_screen.dart`,
`gear_screen.dart`, `roster_screen.dart`, `world/world_screen.dart`,
`world_route_diagram.dart` and `game/dungeon_scene.dart` as well as in the two
style files; a clean cutover leaves no screen declaring a family for itself.

### One token module

`crawl_style.dart:3-12` and `town_style.dart:9-12` declare the same four
colour values with no shared source. Collapse them into one module — new,
under `packages/app/lib/style/` — owning the value ladder, the type roles, the
spacing rhythm and the hairline. The two existing seams keep their
seam-specific tokens and consume the shared ones.

### Sibling themes, never a global restyle

The crawl already has a local `crawlTheme` singleton
(`crawl_style.dart:146-176`). Town and world get their own, in the same shape,
applied at each screen root. `MaterialApp.theme` must **not** be used to
restyle stock Material controls application-wide; that prohibition is the
surviving half of the superseded lock (`VISUAL-SYSTEM.md` section 8).

### The meter pair

`crawl_status.dart:115-152` has the only real meter in the app; the character
screen shows health as text inside a stat panel and the town screen as a
number. One component serves all of them: label, monochrome-safe track, fill,
and the number. This unit introduces the epic's **first permitted hue** —
warm for health, cold blue for mana — as reinforcement only. The number and
the label carry the meaning; removing the colour must lose nothing.

## Boundaries

May change: `packages/app/pubspec.yaml`, a new `packages/app/lib/style/`,
`packages/app/assets/fonts/`, `game/crawl_style.dart`,
`town/town_style.dart`, `main.dart`, `game/crawl_status.dart`,
`town/character_screen.dart`, `town/town_screen.dart`, and every file above
that declares a font family inline — for the font family and token
substitution only. Tests that break on the change.

**Widened 2026-09-18, twice, on planner findings:**

- `town/inn_screen.dart:45-46`, its two space-padded label columns. The file
  declares no font family so the list above did not reach it, but six padded
  columns across the town only ever aligned in monospace and leaving one
  screen drifting while five are fixed is worse than either extreme.
- `.github/workflows/ci.yml` and the repository `AGENTS.md`, for the guard
  that keeps `'monospace'` from returning in U15 through U21. A source-text
  assertion belongs in CI, not in the suite.

May not change: row anatomy, control or chip geometry, the chip fit rule's
algorithm (U15); any icon or art asset (U16); illustration placement or the
character identity block (U17); anything under `dungeon_*`, `glyph_*`,
`grid_geometry.dart` or `art/` beyond the map glyph's font family (U18–U20);
the timeline, log rhythm or sheet extents (U21). Nothing in `packages/core` or
`packages/content`. Not the save schema. Not `cameraCellSize`.

## Traps

- **Type metrics move chrome height, and the dp budget is the real
  constraint.** Worst legal combat measured 580.95 dp against a 600 dp
  ceiling. A serif at the same nominal size is not the same height as
  monospace, and the action row's fit rule measures labels in their heaviest
  style. Re-measure; do not assume the new face is cheaper.
- **`inherit: false` is load-bearing.** `crawl_style.dart:102-135` sets it on
  the chip and caption styles so measurement cannot drift. A style that
  carries `inherit: false` must also carry its family explicitly, or it will
  silently fall back.
- **Wrap count is not monotonic in width.** The fit rule measures and then
  picks the shortest legal layout from five columns down to one. A narrower
  face can produce *more* runs, not fewer.
- **Widget-test dp figures are not device dp figures.** U13.1 found
  `flutter_test`'s font fallback wrapping the same eleven chips into four runs
  where the device fits three — 208.43 dp against the device's 285.33 dp.
  Bundling the faces should close this, because a bundled face resolves
  identically in the test host and on device — which is one more reason
  monospace had to go. Confirm it closed; do not assume it.
- **Two dartdocs already record a device-metric dependency** —
  `town_style.dart:29` and `:203`, on the fixed-width marking columns, where a
  padded string aligned on the desktop and stepped sideways on the phone. A
  device pass caught it once; it can catch it again.
- **Tests that pin old literals get rewritten to the behaviour they defend,
  never re-pinned to new literals.** This is a standing epic lock and this
  unit will trip it more than any other.
- The map glyph's family (`dungeon_scene.dart:432`, `:441`) is the mechanical
  role and its size is derived from `cameraCellSize`. Changing the family is
  in scope; changing the derivation is not.

## Acceptance criteria

1. Both families are bundled with their `OFL.txt`, declared in `pubspec.yaml`,
   and the weight budget is stated with its reason.
2. Two type roles exist in one module. No screen declares `fontFamily` for
   itself, and **`'monospace'` appears nowhere in `packages/app/lib`** — a
   grep for it returns nothing.
3. One module owns the value ladder. Neither `crawl_style.dart` nor
   `town_style.dart` declares a duplicate colour literal.
4. **No stock Material control renders in the Material 3 default palette on
   any screen.** A test fails if one does. The four lavender controls in the
   audit — character navigation, the pack filter chips, the Forge's `Smelt`,
   the Tavern's `Ask` — are the named cases.
5. `MaterialApp.theme` restyles no stock control application-wide; each screen
   root opts into its own theme.
6. One meter component serves the crawl status, the character screen and the
   town screen. Its hue is reinforcement: the label and the number carry the
   meaning, proved by a greyscale render.
7. **The dp budget is re-measured** at exploration, typical combat and worst
   legal combat, and worst legal combat is under 600 dp. The figures are
   recorded in the ledger; if the eleven-chip ceiling now wraps differently,
   the unit says so.
8. Every screen reads in greyscale, including the new meter hues.
9. Broken tests are rewritten to behaviour, not re-pinned to new literals.
   The unit lists which tests it rewrote and what each now defends.
10. `dart format`, `flutter analyze` and the full `flutter test` suite pass
    from `packages/app`.
11. **Device evidence**, colour and greyscale, of every screen — with three
    duties inherited from earlier units:
    - the **ceiling-density crawl**, which carries U13.1's hardware
      confirmation; if the `BattleDock` is covered there, U13.1 reopens;
    - the **world map** and the **roster**, which have no visual baseline
      anywhere in this epic and get their first one here;
    - both device save slots backed up before any install and restored
      byte-identically after, from the backups and never from the device.

## Non-goals

No row or chip restructuring. No new icon, illustration, portrait or item art.
No illustration header. No dungeon material, lighting, prop or actor change.
No timeline or log redesign. No gameplay, content, balance or save change. No
navigation change. The Forge's door split, the town's status-block relocation
and the spells screen's locked section all belong to U15 and U17.

## Glyph coverage, the one thing to check early

The text face must carry every mark the app already draws, because they all
move onto it: the log categories `← → † ◎ ⇅ ✕ ■ ▲ ◆ §`
(`log_line.dart:4-14`), the item marks `‡ ▲ ▼ ·`
(`item_presentation.dart:7,40`), the superscript ordinals `⁰`–`⁹`
(`actor_presentation.dart:79`), the stepper's `−`, the world's `?`, the stair
glyphs `< >`, and the battle glyphs `✖ ◉`. Check this **before** the cutover,
not after. Any mark the face lacks needs a decision — a substitute mark now,
or an authored pictogram in U16 — and must never be discovered as a tofu box
on a device screenshot.

The map glyphs move too (`dungeon_scene.dart:432`, `:441`). Each is centred
in its own cell by `Anchor.center`, so nothing about the grid depended on a
uniform advance width, but the hero, every monster and every stair must stay
legible at `cameraCellSize * 0.73` and that is gameplay-critical. It is part
of AC8's greyscale evidence and AC11's device pass.
