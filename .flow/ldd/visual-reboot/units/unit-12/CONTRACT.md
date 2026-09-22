# Unit 12 — Crawl Interface Visual Grammar

Status: **approved, implemented, accepted, device-verified, merged.** The
user approved this WHAT on 2026-09-17; the plan was approved separately; the
implementation landed as `259322b`; Unit 12.5 closed its device gate on
2026-09-18; PR #22 merged into `main` as `907a4a8` at 2026-09-18T08:49:20Z.
Corrected by Unit 13's intake reconciliation — this line previously still
read "drafted, awaiting explicit user approval".
Base: `main` at `60909e60ec3150cf9b590e6641a8ae51efca775c`
Intake: validated external LDD bundle, `authorization: not-carried`
Visual reference: `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`, frames 2–5
Source recon: `units/unit-12/recon.md`

## Outcome

The phone crawl reads as one designed screen instead of a dungeon viewport
surrounded by stock Material. Place, resources, time, causality and verbs each
occupy a deliberate region in the approved mock's order, drawn with one
crawl-owned visual authority, and every gameplay meaning behind them is
unchanged.

The dungeon viewport itself is Unit 11's, accepted and closed. Unit 12 changes
what surrounds it and how the crawl frames it, never what it renders.

## Inherited locks that bind this unit

- **Four-region responsibility** (epic contract): map = space and targets,
  timeline = time, log = causality, action row = verbs. No concern is
  duplicated across regions. Combat today violates this by showing Drink and
  Wait on both the shelf and the control row.
- **No important state by hue alone** (AGENTS.md, art bible, Unit 9). The
  author is deuteranomalous. Every screen reads in greyscale.
- **Armed reads by border and word** (`game_screen.dart:577`), never a hue.
- **A control appears exactly when it applies**; Pack is the one always-on
  exception (`game_screen.dart:199-210`).
- **The activation queue carries no `NOW —` / `IN n` prose per entry** and
  truncates silently at the first unseen actor.
- **The map is `Expanded`**: every row of chrome is subtracted from map height.
- **`ActionIconImage` stays `Image.asset`, untinted** — the Unit 10 masters are
  multitone and `IconTheme` would flatten them.
- Dependency rule `app → content → core`. Flame stays the dungeon scene's only
  home and is never authoritative state.

## Scope

### A. Crawl visual authority

Introduce one crawl-owned presentation seam — a sibling to
`town_style.dart` in shape, not a `ThemeExtension` and not a change to the
global `MaterialApp` theme — that owns the crawl's surfaces, type ladder,
spacing rhythm, chip metrics and control-state values.

Every crawl-local duplicate folds into it, including `log_drawer.dart:13-15`'s
re-declared `_logNewest` / `_logOlder` and the inline `TextStyle(fontFamily:
'monospace', …)` literals scattered through `game_screen.dart`,
`battle_view.dart` and `log_drawer.dart`.

A `Theme` scoped under `GameScreen` is permitted where Material widgets — the
bottom sheet above all — otherwise render stock. It must not leak: town,
world, character, spells and pack screens keep their present appearance.

### B. Mock layout order

The crawl column adopts the mock's order:

1. status block — place name, depth pair, battle glyph and word, resource
   meters;
2. activation timeline, in combat;
3. the map;
4. the log peek;
5. exactly one action row.

Status moves from below the map to above it. The map's framing — its inset,
edge treatment and how it meets the chrome above and below — is Unit 12's,
with the renderer's own output untouched.

### C. Information hierarchy

The timeline gains the mock's panel treatment: `NOW` and `NEXT` as column
captions, ringed tokens, the actor's word beneath each token, chevrons between.
Captions are region labels, not per-entry prose, so the existing prohibition
stands. Order, repetition, badge identity, silent truncation and the tap that
opens the read-only enemy sheet are unchanged.

The log peek gains a surface and an explicit expand affordance. The expanded
drawer gains the mock's handle, title, hairline rule and line rhythm. Category
marks stay the existing Unicode glyphs in their gutter, presented in the mock's
inset well.

### D. Action grammar

Exploration controls and the combat shelf become one chip vocabulary: icon
above word, even widths, rounded surface, hairline border — the mock's shelf.

Combat shows **one** action row. The shelf absorbs the verbs that currently sit
on the duplicate control row beneath it. Today only Drink is actually rendered
twice — the control row's Wait is already gated `!state.isBattleOpen`
(`game_screen.dart:302-304`) — but the merge puts every verb behind one guard,
so the duplication cannot return.

Available, disabled and armed remain distinguishable in greyscale by border,
fill value, type weight and word. Armed keeps its border and its ` — armed`
word. Every verb that applies stays visible; the mock's `More` chip is the
battle overflow already in the code, not a new place to hide contextual verbs.

### E. Crawl overlays

The spells overflow sheet and any sibling crawl-local sheet or dialog — the
completion confirm, the enemy info sheet, the death overlay — take the crawl's
surfaces and type so no stock-Material break remains reachable from the crawl.

## Deliberate deviations from the mock

Recorded so a later reader does not read them as misses.

1. **Monochrome meters.** The mock's red HP and blue Mana fills stay rejected;
   Unit 9 rejected them as the epic's first hue-only resource state. Value,
   label and numbers carry the reading.
2. **Monospace type.** The mock's serif body would require the repository's
   first font asset and would split the crawl from every other screen. The
   crawl takes the mock's *hierarchy* — letterspaced caps for region labels, a
   deliberate size ladder, ink against dim — in the existing family.
3. **Unicode log marks.** The mock's pictorial per-line log icons would be a
   new asset family; the unit ships no new assets. The existing category
   glyphs keep their meaning and gain the mock's treatment.
4. **`MESSAGE LOG` keeps its name.** The mock titles it `COMBAT LOG` while
   showing arrival, descent and departure lines beneath it. The log is not
   combat-only.

## Non-goals

- Unit 11's dungeon renderer: `dungeon_scene.dart`,
  `dungeon_scene_material.dart`, `dungeon_render_style.dart`,
  `glyph_marks.dart`, `dungeon_material*.dart`, `glyph_plan.dart`.
- New assets of any kind, including fonts and log-category icons.
- `packages/core`, `packages/content`, save schema, content, balance,
  generation, RNG.
- Any change to the global `MaterialApp` theme, and any restyle of town, world,
  character, standalone spells, roster or pack screens.
- An application-wide design system. The seam is the crawl's.
- New verbs, a melee button, direct casting, or any change to what an action
  dispatches.
- Screenshot golden tests.

## Acceptance criteria

1. One crawl-owned style seam holds the crawl's surfaces, type, spacing and
   control-state values; no crawl widget carries a private colour or a
   hand-rolled `TextStyle` the seam should own.
2. The crawl column renders in the mock's order, status above the map.
3. Combat shows one action row; no verb appears twice on screen.
4. Chips read as one family across exploration and combat: icon above word,
   even widths, shared metrics.
5. Available, disabled and armed are distinguishable without reading colour;
   armed still shows a border and the word. **Greyscale device confirmation
   defers to Unit 12.5;** the suite proves the value, weight and word
   separation.
6. The timeline shows `NOW`/`NEXT` captions, ringed tokens and actor words,
   and still truncates silently at the first unseen actor with no placeholder
   and no per-entry prose.
7. Activation order, literal repeated activations, duplicate badges, the
   current/selected distinction and the no-turn-cost inspect are unchanged.
8. Compact and expanded log contents, ordering, causality, the extent cycle,
   follow, unread and the `↓ N new` affordance are unchanged.
9. Every control's visibility rule, availability rule and dispatched action is
   unchanged; disabled controls remain inert.
10. Melee stays map-first with no melee control; targeted spells stay
    `arm → map target → tap`, and a stray tap still disarms.
11. No crawl-reachable surface renders as stock Material, including the spells
    overflow sheet, the completion confirm, the enemy info sheet and the death
    overlay.
12. Town, world, character, spells, roster and pack screens are visually
    unchanged. **Confirmation by eye defers to Unit 12.5;** the suite proves
    the theme does not leak and the pack route still renders in the town's
    ink.
13. The dungeon viewport's own output is unchanged; only its framing moves.
14. The chrome height is measured and asserted against the plan's caps at
    worst legal density, with no label ellipsised or word broken. **The
    device figures — whether the resulting map is playable on `Medium_Phone`
    — defer to Unit 12.5.**
15. Formatter, analyzer and the full `packages/app` suite pass; tests that
    pinned presentation implementation are rewritten to the behaviour they
    defend, never re-pinned to new literals.
16. **Deferred to Unit 12.5 in full.** `Medium_Phone` evidence covering
    exploration, combat, armed targeting, the expanded log, the spells sheet
    and a greyscale pass, with both save slots restored byte-identically, is
    no longer a Unit 12 criterion. Unit 12 closes on suite evidence and
    carries this debt forward explicitly.
17. **Deferred to Unit 12.5.** The judgement on whether the dungeon viewport
    is now the dominant remaining parity gap needs the crawl seen on a
    device, so it is recorded after 12.5's pass, not this unit's.

## Verification disposition

Behaviour is proved by focused widget and bloc tests at the layer that owns it.
**Unit 12 closes on that evidence alone.** Appearance is judged against the
mock on `Medium_Phone` — hierarchy, density, rhythm, framing, contrast and
action-state clarity, never pixel parity — and by the user's decision of
2026-09-17 that pass is **Unit 12.5's**, not this unit's. No golden images.

The three presentation-pinning test families named in `recon.md` — the log
row's literal colour, the control row's frozen widget type and fit maths, the
shelf's widget type — are rewritten to assert the contract rather than the
implementation. The frozen control *set and order* remains a real contract and
stays asserted.

Save handling follows the epic procedure — back both device slots up before
any install and verify byte-identical restoration afterwards — and belongs to
Unit 12.5, because Unit 12 installs nothing.
