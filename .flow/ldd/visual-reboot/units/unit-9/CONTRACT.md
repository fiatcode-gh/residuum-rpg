# Unit 9 — Crawl HUD Chrome Contract

Status: **draft for user approval; planning and implementation are separate authorization steps.**

Recon: `units/unit-9/recon.md`, source-verified at `main` `2b0e0a4`.

## Outcome

Replace the crawl's single scale-down status string with two deliberate rows —
a whereabouts header and a labelled resource row — without losing one fact the
string carries today and without reintroducing the overflow and ellipsis
defects three device passes have already found on this part of the screen.

After this unit:

- the hero's place and depth read as a header, not as the middle of a sentence:
  the dungeon's name on the left, `depth / deepest` on the right;
- HP and Mana each have a labelled bar with its own numbers, built from the
  meter grammar the Skills room already ships, so a resource reads at a glance
  instead of being parsed out of a line;
- the condition word, the battle glyph and word, the enemy count and the ward
  remain visible exactly where they are meaningful;
- the control row stays text-only, because the app has no icon language yet and
  the row's labels carry counts and a data-driven verb.

This unit changes presentation and composition only. It must not change rules,
events, state ownership, prose, save shape, or core/app boundaries.

## Locked product decisions

### Two rows, not one line and not the mock's shape

The approved mock's header-plus-two-bars reading is adopted. Its **red HP and
blue Mana fills are rejected**, and its **icon control chips are deferred** with
the rest of the icon language.

An earlier form of the mock's layout already shipped and was beaten by hardware:
`game_screen.dart:246-258` records a stretched bar plus three fixed labels that
fitted only while the middle label read `Depth 3/5`, and overflowed a phone by
sixty-four pixels once the dungeon was named. The widget-test surface is wider
than a phone and never saw it. This unit therefore buys the mock's structure and
keeps the scale-down discipline that fixed it.

**Header row.** The place on the left, the depth pair on the right:

- in a dungeon: the node name from `residuumWorld.nodeAt(GameBloc.dungeon).name`,
  rendered in upper case as the mock shows, with `depth / deepest` right-aligned
  as two numbers and a separator;
- on the road: the place reads `THE ROAD` alone, with **no depth pair**, because
  a road fight has no floor and `_whereabouts` already answers `The road`;
- the battle glyph and battle word sit between them, and only when there is
  something to say: `◉ Watched 2` or `✖ Engaged 2`. The existing `_BattleGlyph`
  cell and the existing words are reused; the glyph keeps its fixed-width column.

**Resource row.** Two labelled meters side by side, in the `_SkillRow` grammar
of `packages/app/lib/town/skills_screen.dart:38-60` — a word label, the numbers,
and a monochrome `LinearProgressIndicator` on the `rule` track:

- the HP cell always shows, carrying its label, `shown / ceiling`, and the
  condition word (`Steady`, `Wounded`, `Critical`, `Dead`);
- the Mana cell shows **only when the hero knows a spell**, preserving the rule
  and the reason recorded at `game_screen.dart:290-295`: a pool nobody can spend
  is a number in the way, and a non-casting hero must read the same HUD that
  shipped before magic did;
- `Ward n` joins the Mana cell only while a ward stands, for the same reason it
  joins the line today — it is the one piece of state a player must see mid-fight.

### Nothing ellipsises, ever

No text on either row may ellipsise or clip at any phone width. Each row shrinks
to fit, the way the current line does. The worst case is explicit and must be
measured: the Ruined Keep, engaged with several enemies in sight, warded, with a
casting hero, standing on the bottom floor with something underfoot — the widest
header, the fullest resource row, and `_Controls` at four rows below it.

### Monochrome meters

Neither bar may carry meaning in its hue. Fills are the existing value-contrast
inks; the track is `rule`. Low health is announced by the condition word, which
already exists and already reads in greyscale and aloud. The author is
deuteranomalous and the epic's accessibility lock is not negotiable here — this
is the first place in the reboot where a hue-only resource state could appear.

### The control row stays words

No icon chips. Only two Material icons ship in the entire app
(`Icons.center_focus_strong`, `Icons.close`) and neither carries game meaning,
so chips would be a net-new icon language — deferred to the post-Unit-8 art
pass. The row's labels also carry live counts (`Drink (2)`, `Pack (7)`) and one
data-driven verb (`node!.verb`), and up to five controls divide the row at once.
`doneControl`, `doneAtTheBottom`, `Underfoot:` and `Here:` are untouched prose.

### Unit 8's device gate folds into this unit's

By the user's decision on 2026-09-16, Unit 8's open acceptance criterion 9 is
discharged by Unit 9's device pass rather than a standalone session. Unit 9's
gate therefore carries Unit 8's frames as well, and Unit 8 stays formally open
until it passes.

## Boundaries and invariants

1. `packages/core` and `packages/content` are untouched. Every value the HUD
   needs is already on `GameViewState`: `depth`, `deepest`, `isEncounter`,
   `isBattleOpen`, `enemiesInSight`, `mana`, `maxMana`, `warded`, `maxHp`.
2. `GameBloc`'s events and state are unchanged. No HUD element may dispatch an
   action, and nothing on these rows is interactive. A new app-side getter is
   permitted only as a pure projection of existing state.
3. **No fact currently readable on the status line may disappear**: hit points
   shown and ceiling, the condition word, the place name or `The road`, depth
   and deepest, the `Engaged`/`Watched` word with its count, `Mana m/max` under
   the same known-spells gate, and `Ward n` while one stands.
4. No new text mark codepoint. `✖` (U+2716) and `◉` (U+25C9) are reused as-is;
   the epic's ban stands because Android has resolved a codepoint as colour
   emoji before and no widget test can see it.
5. The map stays the primary surface and stays `Expanded`. The two rows together
   may exceed the current status row's intrinsic height by **at most one text
   row**; anything more is a plan defect, not an implementation detail.
6. Every other crawl element is out of scope and must render identically: battle
   dock, battle shelf, log peek and drawer, recenter affordance, death overlay,
   pack route, control set, and all refusal or explanatory prose.
7. The replaced composition is deleted. The single concatenated `_line` string
   goes away; no hidden fallback, no duplicate formatter, no compatibility
   getter left behind.
8. Accessibility: every state on these rows reads in greyscale through a word,
   a glyph, a number, or value contrast. No meaning is hue-only.

## Explicit non-goals

- No icon chips, icon family, asset pipeline, `assets:` declaration, static art,
  portrait, animation, or new mark codepoint.
- No new control, no control removal, no relabelling, and no rewording of any
  refusal, status, or explanatory sentence.
- No timeline, dock, shelf, log, targeting, pack, town, world, Character, or
  roster change.
- No core, content, save-format, RNG, rule, event, or bloc-ownership change.
- No tablet or landscape layout work.
- No generic "HUD framework", theme abstraction, or second style module. The
  existing `town_style.dart` vocabulary the crawl already imports is what these
  rows use.

## Acceptance criteria

1. In a dungeon, the header renders the node's name and its `depth / deepest`
   pair; in a road fight it renders `THE ROAD` with no depth pair. The name is
   the world's own name for the node, unabbreviated.
2. The resource row renders a labelled HP meter with `shown / ceiling` and the
   condition word at all times; the Mana meter with `mana / maxMana` appears
   exactly when the hero knows at least one spell and is absent otherwise;
   `Ward n` appears exactly while a ward stands.
3. The battle glyph and word still report `Engaged n` and `Watched n` with the
   same counts and the same glyphs, and report nothing when nothing is in sight.
4. At phone width, in the worst case named above, no text on either row is
   ellipsised or clipped; rows scale down instead.
5. Compared with `2b0e0a4`, the dungeon viewport loses no more than one text
   row of height, measured on device.
6. No state, resource, or category on these rows is hue-only; both meters are
   monochrome and every screen still reads in greyscale.
7. Focused tests prove criteria 1–3 and the known-spells and ward gates. The
   fourteen tests across five files that pin the concatenated
   `<name> — depth <n>/<n>` string, and the `Engaged`/`Watched` `textContaining`
   assertions in `battle_characterization_test.dart`, are migrated to assert the
   observable facts rather than one string's composition — rewritten where they
   pin composition, not re-pinned to new text.
8. `dart format --set-exit-if-changed` on touched files, `flutter analyze`, and
   full `flutter test` pass from `packages/app`, with zero changes under
   `packages/core` and `packages/content`.
9. On `Medium_Phone`, colour evidence covers: a fresh crawl with no spells
   known, a casting hero warded mid-fight, a critical-health hero, the bottom
   floor with something underfoot and five controls, and a road fight — plus
   **Unit 8's folded frames**: a fresh/discovery-gated world, a fully discovered
   world, an active journey, the Sea-Cave and Ruined Keep delves, and road
   fights on the lowland, Sea-Cave and Ruined Keep routes. Greyscale twins cover
   the resource row and every frame with a non-neutral regional palette. Unit
   8's two open questions are answered: whether a real screen reader reaches the
   below-fold world-diagram nodes, and whether the Sea-Cave strata and Ruined
   Keep fracture strokes read at phone density. Both device save slots are
   backed up before install and verified byte-identical afterward; read
   `app_flutter/save.json`, never `files/save.json`.

## Verification and review disposition

- **Acceptance review:** required after the integrated implementation, checking
  plan conformance, the fact-preservation list in invariant 3, the deleted
  formatter, test migration quality, and accessibility.
- **Device gate:** required after acceptance-review findings are closed, and it
  carries Unit 8's criterion 9. The AVD is user-started — it segfaults when
  launched from a tool shell. Multi-step capture is delegated to bounded
  `flow-evidence-verifier` capsules.
- **Security review:** skip. Local Flutter presentation over existing state,
  no new external boundary.
