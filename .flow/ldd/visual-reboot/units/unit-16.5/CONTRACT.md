# Unit 16.5 Contract — ASCII Crawl Full Parity

Status: **approved by the user on 2026-09-23.** Local commits on the branch are authorized during execution (one Conventional Commit per accepted task); push, pull request and merge are not.

Observed head: `2c073b7` on `residuum-visual-reboot-16` (U16 implementation
`b301f27` plus its docs commit). Same branch; no new branch.

Visual authority (appearance and composition):

- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-atmosphere-art-bible.png`
- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-exploration-mock.png`
- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-combat-targeting-mock.png`
- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-expanded-log-mock.png`

The repository stays the authority for every displayed fact and every action.

## Why this unit exists

U16 kept every lock and the result does not look like the mocks. Its device
capture (`.flow/evidence/visual-reboot/unit-16-device/exploration/`) shows about
11×17 large serif glyphs on a flat grey field, no visible torchlight, the old
two-row status band, a clipped log peek and two small chips. Four locks made
parity impossible: the 36 dp camera cell, the monospace ban, the 600 dp
action-driven chrome ceiling, and the ban on any light or fog layer beyond an
ink tint. The user delegated those four decisions to the architect on
2026-09-23 and asked for full parity with the art bible and the three mocks.

## Settled decisions (delegated by the user, 2026-09-23)

1. **Dense map; aim by intent, not by cell.** The map cell becomes a
   monospace character cell at mock density: about **13 dp wide × 16 dp tall**
   (the mock measures about 12.4 × 15.4 dp), so a 393 dp phone shows about 30
   columns. This replaces the fixed 36 dp `cameraCellSize`. Touch precision
   comes from resolving what the player meant, not from large cells: every map
   interaction has an effective touch target of at least 44 dp (rules in
   scope item 3). There is no zoom.
2. **Monospace comes back, for the map and data only.** Bundle **IBM Plex
   Mono** (SIL OFL 1.1, licence file shipped next to the fonts) as a third
   type role in `lib/style/tokens.dart`. It is used for map glyphs, log
   sentences, numbers and data values. EB Garamond remains display (wordmark,
   section titles, names). Spectral remains body prose and control labels.
   `fontFamily` still appears only in `tokens.dart`. The Unit 14 "monospace
   retired" rule and its CI grep are superseded.
3. **Fixed chrome by mode; action count never moves the map.** The crawl
   screen has one fixed layout per mode (exploration, battle). The number of
   legal actions no longer changes chrome height. The old "worst legal chrome
   < 600 dp" ceiling and U15's measure-all-candidates chip-fit search are
   retired. New floor: the map region is at least **45%** of the phone's
   logical height in exploration and at least **35%** in battle, and armed and
   unarmed states keep the same map rectangle.
4. **Real light and real fog.** Torchlight is a warm light pool drawn under
   the glyphs and centred on the hero, plus value falloff on visible terrain.
   The backdrop is a near-black field with soft deterministic fog, a vignette
   and camera-relative parallax. Knowledge secrecy still holds: light never
   draws a glyph, shape or edge that the visibility state does not already
   show.

## Outcome

On the target phone, each of the four crawl states sits next to its mock and
reads as the same design: same regions in the same order, same proportions,
same type roles, same palette, same light and darkness. The only differences
are facts the game does not have (listed under "Mock content that stays out").

## In scope

### 1. Palette (art bible, section 7)

Adopt the bible palette as crawl tokens: torch light `#FFD27A`, player
`#FFF4D6`, enemy `#FF5B5B` / high-danger enemy `#FF3B3B`, cold/mana `#4FC3FF`,
UI gold `#D6C280`, text primary `#E6E1D6`, text secondary `#9CA3AF`,
background `#0A0F14`, fog/depth `#1A2430`. Terrain ink is warm stone: walls
warm tan and floor dots dim warm, as in the mocks, in every region, including
road encounters. A region may change the fog tint only. Existing item and
node marks keep distinct hues that fit this palette. No red-versus-green pair
anywhere. Every category is also carried by glyph, shape or word.

### 2. Map rendering

- Glyphs are drawn in the mono role on the new character cell: `#` walls,
  `·`/`.` floor, `<` `>` stairs, `@` hero, the existing monster letters and the
  existing item and node marks. Unknown cells draw nothing.
- Value hierarchy: the hero `@` is brightest, with a soft bloom. Visible
  terrain is bright near the hero and falls to a dim value at the edge of the
  field of view. Remembered terrain is clearly dimmer again, at about the
  mock's remembered value. Unknown terrain is void.
- The torchlight pool (radius about 6 cells, torch-light hue, soft falloff)
  sits between the backdrop and the glyphs. It follows the hero and draws no
  glyphs, edges or shapes.
- Target geometry: legal targets get corner-bracket reticles (the mock's
  `[ ]`). The current or selected target gets a heavier reticle plus its
  callout (scope item 5). Selected and marked stay distinguishable by shape
  and weight, not hue.
- Depth backdrop: near-black base, low-frequency deterministic fog in the fog
  hue, darker edges (vignette). It draws in screen space behind the map only.
  Parallax moves only the backdrop, at a small fraction of camera movement,
  and is off when the platform asks for reduced motion. Same state and camera
  give the same frame.

### 3. Map input on dense cells

Every existing behaviour stays: tap to move or auto-walk, map-first melee,
arm → target → tap, tap a far monster to inspect it, long-press to inspect,
drag to pan, recenter. Only how a touch point becomes a logical cell changes:

- With a spell armed, a tap resolves to the nearest legal target within 22 dp
  of the touch point.
- A tap within 22 dp of a visible monster resolves to that monster (melee if
  adjacent, inspect if far), as the current cell rules do.
- Otherwise, a tap within 22 dp of the hero steps one cell in the tap's
  8-way direction. A farther tap resolves to the cell under the finger for
  auto-walk.
- Long-press resolves to the nearest inspectable actor within 22 dp.
- Ties break deterministically. A touch that resolves to nothing does
  nothing.

`GridGeometry` stays the single projection and hit-test authority (now with
non-square cells). Rendering layers never install input handlers.

### 4. Screen composition (top to bottom)

Exploration (`ascii-exploration-mock.png`):

1. Wordmark `RESIDUUM` (display role, wide tracking, gold-ivory), with a thin
   rule under it. No menu or settings buttons (no real route exists).
2. Meta line in mono, secondary text: `Depth N/M | <place name>`, plus a third
   real fact if the crawl already has one available (for example the world
   day). No seed.
3. Status chips: outlined pills, each a leading shape mark plus a word, built
   only from real state: the battle/watch state (for example `Watched 1`,
   `Engaged 2`), the HP condition (`Steady` / `Wounded` / `Critical`) and the
   ward when present.
4. Map (the `Expanded` region).
5. Character panel, three columns as in the mock: left column is the hero
   name (display, spaced caps), HP bar and mana bar (mana only when spells are
   known), then attack range, armour and gold. Middle column is the weapon
   (main hand, or bare fists) and body armour (chest piece, or none). Right
   column is the quick item (potion name and count) and pack `count/cap`.
   Shipped potion and pack icons are used here. Weapon and armour marks use
   the Flutter-bundled Material icon font tinted in UI gold (no new asset).
6. Recent events panel: framed, titled `RECENT EVENTS` (display, spaced caps)
   with the truthful unread/new count and the expand affordance at the right.
   Four mono lines, newest at the bottom, category-tinted text (hostile red,
   spell/item cold blue, discovery/loot torch amber, neutral primary). Nothing
   clips.
7. Action bar: full width, five equal framed slots visible, icon above label,
   count as small metadata. When more than five actions are legal, the bar
   scrolls horizontally and a sixth slot visibly peeks as the scroll cue. The
   armed slot gets the mock's cold-blue border glow plus its existing word.
   Shipped icons are used where one exists. An action without a shipped icon
   gets a Material icon-font glyph in UI gold that fits the meaning (for
   example an hourglass for Wait).

Battle / targeting (`ascii-combat-targeting-mock.png`):

- Items 1–3 as above, then the activation timeline: a `NOW` label with the
  current token (heavier gold frame), a divider, then a `NEXT` label with
  upcoming tokens as outlined pills (glyph plus name, in the actor's hue). No
  invented numbers. Repeated/ordinal identity and secrecy are unchanged.
- The map.
- The character panel is replaced by the combat panel, three columns: TARGET
  (name in enemy hue, HP bar and `HP a/b`, plus real facts already shown by
  the enemy sheet), DAMAGE (the damage range of the armed spell, or the
  hero's attack range when none is armed, shown large in mono), and SELECTED
  SPELL (armed or first readied spell: name, `Mana Cost N`, damage type and
  school as `A | B` tags). No to-hit percentage (the core has no hit-chance
  rule).
- Recent events and the action bar as above.

Exploration callout: tapping a far monster (the existing inspect trigger)
shows an anchored callout card beside it on the map, with a thin leader line,
name, HP and existing enemy facts, instead of the bottom sheet. The callout
takes input only inside its own bounds and dismisses on the next map
interaction or action.

Expanded log (`ascii-expanded-log-mock.png`): a sheet over the lower map,
leaving the action bar visible. Header `RECENT EVENTS` (display, spaced
caps), a truthful `N entries` count and a real close control. Rows are a
category pictogram (Material icon font, one distinct silhouette per
`LogCategory`, category tint) followed by the mono sentence in category tint,
with a thin scrollbar. Follow/unread, ordering and causal text are unchanged.
Each category's accessible word stays.

### 5. Documentation that the new direction contradicts

Update in this unit: repo `AGENTS.md` (Type rule), `.github/workflows/ci.yml`
(the monospace grep; the "fontFamily only in tokens.dart" gate stays),
`docs/specs/2026-08-20-dungeon-game-design.md` (Visuals line: glyphs are the
permanent direction), `units/unit-13/VISUAL-SYSTEM.md` (monospace, the 36 dp
cell, the 600 dp ceiling, dungeon materials and dominance sections, each
marked superseded by U16.5), plus the ledger's locked-contract section and
RESUME. Historical ledger entries are not rewritten; supersession is
appended.

## Protected boundaries

- No change to `packages/core` or `packages/content` behaviour, save schema,
  RNG outcomes, map topology, field of view, encounter generation or balance.
  If a displayed fact is not reachable from app state without a core change,
  leave it out and record that. Do not change core.
- Action vocabulary, stable action ids, dispatch, `readiedSpellCount == 3`
  and legality are unchanged. Only presentation and the fit algorithm change.
- Timeline schedule and identity semantics, hidden-actor secrecy,
  `LogCategory` semantics, event ordering, follow/unread and causal text are
  unchanged.
- Determinism: no unseeded randomness. Fog and noise are hashed from screen
  coordinates and a fixed salt, never from gameplay `Rng`.
- Accessibility: nothing important is carried by hue alone. No red-versus-green
  pair.
- Town, world, roster and other non-crawl screens are unchanged except for
  the shared token additions.
- No generated or semantically edited images. Allowed: the bundled IBM Plex
  Mono font files and licence, the Flutter-bundled Material icon font, the
  existing shipped icons, and code-drawn shapes, gradients and fog. Historical
  dungeon-art masters stay in the repository.
- No widget golden tests (repo rule).

## Mock content that stays out

Stays out because the game has no such fact or action: `Torch`, `Hungry`,
`Clear`, `Seed 42`, `Auto-walk`, `Help`, `Inspect` as a button, hamburger and
settings buttons, `[12:14]` clock timestamps, turn numbers such as `(14)`,
`TO HIT 73%`, monster flavour text (unless content already carries it), doors
`+` and water `~` (no such terrain), and the dotted range path (settled
2026-09-18). Each is replaced by the nearest real fact as described above, or
left out.

## Acceptance

1. Map: the device shows about 30 columns of mono glyphs on a 393 dp phone,
   with warm terrain ink, a visible torchlight pool around `@`, falloff to dim
   at the edge of view, clearly dimmer remembered terrain, and a void for
   unknown cells.
2. No glyph, edge or shape appears for unknown cells, whether from light,
   fog, parallax or callouts. There is automated negative proof.
3. The backdrop shows visible fog and vignette. Parallax moves only the
   backdrop, is bounded, and is off under reduced motion. Projection and hit
   testing are unaffected (automated proof).
4. Input: each rule in scope item 3 is proven by bloc- or widget-level tests,
   including the 22 dp resolution radius, deterministic ties and
   resolves-to-nothing. The existing interaction tests still pass, rewritten
   only where they pinned the 36 dp cell.
5. Composition: exploration, battle/targeting and expanded-log device captures
   match their mock's region order and approximate proportions (each region's
   height within about ±20% of the mock's share of screen height), type roles
   and palette.
6. Map share is at least 45% of logical height in exploration and at least
   35% in battle. Armed and unarmed map rectangles are identical. Chrome
   height is independent of the number of legal actions.
7. Every legal action stays reachable. With more than five actions the bar
   scrolls with a visible peek cue. Ids and dispatch are unchanged.
8. The log peek shows four unclipped lines. The expanded log shows the
   pictogram, sentence and tint per category, with follow/unread and ordering
   unchanged.
9. No mock-only fact from "Mock content that stays out" appears. Every
   displayed value traces to app or game state.
10. Docs in scope item 5 are updated and no tracked doc still asserts the
    retired locks as current. The CI type gate passes with the mono role.
11. `dart format`, `flutter analyze` and full `flutter test` pass in
    `packages/app`. `packages/core` and `packages/content` are untouched.
12. **Early visual checkpoint:** after the map renderer, light and backdrop
    land, and before chrome work, a device capture of exploration is compared
    to the art bible and exploration mock. The architect must judge it on
    track, or the map work is corrected before continuing.
13. **Final visual gate:** device captures on the user's physical phone for
    exploration, battle with timeline, armed targeting, callout, log peek,
    expanded log, road encounter and the densest action state. Each is placed
    side by side with its mock, scored by an independent reviewer against
    criteria 1–9, then **shown to the user for visual sign-off**. The unit is
    accepted only after the user signs off.
14. Device state: the phone currently holds the U16 test install and its test
    saves. U16.5 may install over it. At the end, uninstall the package and
    verify it is absent, returning the phone to its original pre-U16 state.
    Checkpoint first, as before.

## Relation to Unit 16

U16's code on this branch is the starting point: glyph renderer, dungeon
decode cutover, visibility-aware light and depth seam. U16.5 supersedes U16's
plan decisions where they conflict (36 dp cell, ink-only light, gradient-only
backdrop, no parallax, unchanged chrome and action row). U16 and U16.5 are
accepted together at U16.5's final gate.

## Authorization boundary

Approving this contract authorizes planning only. Implementation needs
approval of the execution-grade plan. Local commits, push, pull request and
merge each need explicit user approval.
