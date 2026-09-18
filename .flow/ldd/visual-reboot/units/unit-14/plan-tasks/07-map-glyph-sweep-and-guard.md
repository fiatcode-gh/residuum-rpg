# Task 07 — The Map Glyph, the Monospace Sweep, and the Standing Guard

Owner: one fresh `flow-plan-executor` on the Unit 14 feature checkout.

Read `../CONTRACT.md` (AC2, and the Traps note on `dungeon_scene.dart:432`,
`:441`), `../PLAN.md` ("The standing guard" and "Task 07 — the closing audit"),
then `packages/app/lib/game/dungeon_scene.dart:415-450`,
`packages/app/lib/game/glyph_marks.dart`,
`packages/app/lib/game/glyph_plan.dart`,
`packages/app/lib/style/tokens.dart`,
`.github/workflows/ci.yml` and `AGENTS.md` before editing.

All commands run from `packages/app` except the CI and `AGENTS.md` edits, which
are at the repository root.

## Starting condition

- Tasks 01–06 are accepted. Every screen and both style seams render from the
  shared tokens; `residuumTheme` is applied at six roots; no stock Material
  control renders in the Material 3 default palette;
- `grep -rn "fontFamily: '" packages/app/lib` returns exactly two hits:
  `lib/game/dungeon_scene.dart:432` and `:441`;
- `grep -rn "monospace" packages/app/lib` returns those two plus up to three
  prose mentions, depending on what earlier tasks caught:
  `lib/game/battle_view.dart:229` (Task 02's),
  `lib/town/town_style.dart:29` and `:203` (Task 04's),
  `lib/main.dart:144` (Task 01's). **Re-run the grep and work from what it
  actually returns**, not from this list;
- `.github/workflows/ci.yml` has no type gate.

Inspect branch, HEAD and worktree before editing. If the grep returns a hit in a
file no earlier task owned, stop and report — it means a task missed a site.

## Behavioral slice

**Task 08 follows this one.** Architect amendment A4 adds a behaviour-neutral
rename leaf after this task, which deletes both seams' alias declarations and
closes AC3. Nothing in this brief depends on it, but do not claim AC3 and do
not delete an alias here — the alias strategy is still load-bearing until
Task 08 retires it in one reviewable commit.

The dungeon's map glyphs render on the authored text face, the word
`'monospace'` appears nowhere in `packages/app/lib`, and CI makes it impossible
for U15 through U21 to bring either the word or a per-screen font family back.

This is the unit's AC2 closer. Its precondition is that every other task has
landed.

## Owned files

- `packages/app/lib/game/dungeon_scene.dart` — `:432` and `:441` only;
- whichever files the sweep grep still names — dartdoc prose only;
- `.github/workflows/ci.yml`;
- `AGENTS.md`.

**Do not edit** anything else in `dungeon_scene.dart`. Not
`_ClippedMaxViewport` or the camera wiring at roughly `:184-222` (that is
`e8bcf29`, U13.1's accepted map-bleed fix), not `_mapPosition`, not
`_applyTreatment`, not `_updateBadge`, not `_updateOutlines`, not
`cameraCellSize`, not `glyphBaseFontScale` (`glyph_marks.dart:2`, value 0.73),
and not the `* 0.30` badge derivation. Do not touch
`dungeon_scene_material.dart`, `dungeon_render_style.dart`, `glyph_marks.dart`,
`glyph_plan.dart`, `dungeon_palette.dart`, `dungeon_material*.dart`,
`grid_geometry.dart`, `art/`, `packages/core` or `packages/content`.

## Locked decisions

### The two map glyph paints

`dungeon_scene.dart:428-435` (`_textPaint`) and `:437-444` (`_badgePaint`) each
build a Flame `TextPaint` whose `TextStyle` carries
`fontFamily: 'monospace'`. Each becomes:

```dart
fontFamily: textFace,
```

importing `tokens.dart`. **That is the entire change to this file — two lines.**

Everything else in both builders is frozen:
`color: cell.ink.withValues(alpha: cell.opacity)`,
`fontSize: cameraCellSize * glyphBaseFontScale` and
`fontSize: cameraCellSize * 0.30`, and `height: 1`.

- the sizes are **derived**, not tokens. The contract is explicit: changing the
  family is in scope, changing the derivation is not;
- `height: 1` stays. Every glyph is centred in its own cell by `Anchor.center`,
  so the line box must be exactly the em box, and `tokens.dart`'s `textGlyph`
  role is **not** used here — its 18 px size is wrong for a cell-derived glyph.
  Build the `TextStyle` inline with the family token, as the file already does;
- do not add `fontFeatures`, `fontWeight`, `letterSpacing` or
  `fontFamilyFallback`. Flame renders through the same text engine, so the
  bundled family resolves by name; the twelve marks Spectral lacks are not map
  glyphs (the map draws `@`, monster letters, `<`, `>`, `*` and superscript
  ordinals, all covered — proved by Task 01's coverage test).

### The sweep

Run the grep, then rewrite each prose hit so the word does not survive while
its meaning does. The two in `town_style.dart` are **Traps the contract
protects** and must keep their warning:

| site | required content after |
|---|---|
| `town_style.dart:26-31` (`markColumn`) | still says the markings are not all one cell wide **in the text face**, and that a column that drifts by two pixels steps sideways on the phone |
| `town_style.dart:202-205` (`MaterialRows`) | still says the ingot bar is wider than the ore diamond, so a padded string aligns on the desktop and steps sideways on the phone, **and that a device pass caught exactly that** |
| `battle_view.dart:229` | "One line of the enemy sheet, in the text face and dim" |
| `main.dart:144` | deleted with `monoLike` in Task 01; verify |

If an earlier task already cleared one of these, leave it. Deleting a warning is
a defect; the word is what goes, not the reason.

### The standing guard

Two things, and this is how AC2 survives the next seven units.

**1. CI.** Append to the `app` leg of `.github/workflows/ci.yml`, after the
`analyze` step and before `test`:

```yaml
      - name: type authority gate
        if: matrix.package == 'app'
        working-directory: packages/app
        run: |
          if grep -rn "fontFamily: '" lib --include='*.dart'; then
            echo "a screen declares its own font family; every text style comes from lib/style/tokens.dart"
            exit 1
          fi
          if grep -rn "monospace" lib --include='*.dart'; then
            echo "monospace was retired in unit 14 and does not come back"
            exit 1
          fi
```

It forbids the family **literal**, not the token reference, so
`fontFamily: textFace` passes and `fontFamily: 'Spectral'` does not. Note the
`if`-block form: a bare `! grep` would invert the wrong exit code and a
`grep` that matches nothing exits 1, which would fail the leg on success.

This is CI, not a test: it asserts nothing about behaviour, allocates no
`TextPainter` and cannot be satisfied by a source-text assertion in the suite —
which the repository's test doctrine forbids. Do **not** write a test that reads
`lib/**.dart` and greps it.

The `matrix.package` guard matters: the step must not run on the `core` or
`content` legs, whose `lib` directories have no such rule.

**2. `AGENTS.md`.** Append one line to the app bullet in the `## Testing`
section's sibling — the `## Craftsmanship` list is the right home:

```text
- **Type:** `fontFamily` appears only in `packages/app/lib/style/tokens.dart`.
  Every text style is a role from that module, varied at a call site only by
  `copyWith(color:)`. Monospace was retired in Unit 14 and does not come back.
```

CI enforces it; `AGENTS.md` is where the next agent reads it before CI has to
teach it.

## Executor discretion

Yours without asking:

- the exact rewording of each prose site, so long as the word goes and every
  warning stays;
- where in `AGENTS.md`'s `## Craftsmanship` list the type rule sits, and its
  exact wording;
- the CI step's name and its two failure messages;
- whether the import in `dungeon_scene.dart` is relative or package-qualified,
  matching the file's neighbours.

Not yours: the two changed lines being the *only* change to
`dungeon_scene.dart`, the frozen derivations, `height: 1`, the `if`-block form
of the CI greps, the `matrix.package == 'app'` guard, or the decision not to
write a source-text test.

## Red proof

There is no new behaviour, so the proof is the audit plus one regression.

### The closing audit

Record the exact output of all four, before and after:

```text
grep -rn "fontFamily: '"  packages/app/lib --include=*.dart
grep -rn "monospace"      packages/app/lib --include=*.dart
grep -rn "Color(0x"       packages/app/lib/game/crawl_style.dart packages/app/lib/town/town_style.dart packages/app/lib/main.dart
grep -rn "TextStyle("     packages/app/lib --include=*.dart
```

Expected after:

1. **nothing** — that is AC2's first half;
2. **nothing** — that is AC2's second half, the grep the contract names;
3. **nothing** — this is AC3's first half. **Architect amendment A4 moves
   AC3's closure to Task 08**, which deletes the seams' alias declarations
   outright and re-runs this grep in its stronger form (`Color(0x\|const
   Color` returning nothing at all). Report this grep's result; do not claim
   AC3 closed;
4. only `packages/app/lib/style/tokens.dart` and
   `packages/app/lib/game/dungeon_scene.dart` (the two cell-derived glyph
   paints, whose sizes cannot be tokens).

Exclude by path, and say so in the receipt: `dungeon_palette.dart`,
`dungeon_render_style.dart`, `dungeon_scene_material.dart` and `glyph_plan.dart`
carry Unit 11's renderer palette, which this unit may not touch.

**Expected Red for greps 1 and 2: two hits each, at `dungeon_scene.dart:432`
and `:441`, plus whatever prose the sweep grep names.**

### The CI gate proves itself

Before committing the gate, run its two greps locally and confirm both are
silent on the migrated tree. Then, as a one-shot check that the gate can
actually fail, temporarily reintroduce `fontFamily: 'monospace'` in a scratch
file **outside** `packages/app/lib` — or simply run the grep against the
pre-sweep commit — and confirm the grep reports it. **Do not** leave a probe in
the tree, and do not mutate a tracked file to test the gate: if you must,
snapshot the exact pre-edit bytes of the file first, restore from that snapshot,
and verify byte-for-byte restoration before continuing.

### Must stay green

```text
flutter test test/game/dungeon_scene_test.dart test/game/glyph_marks_test.dart test/game/glyph_plan_test.dart test/widget/dungeon_scene_bleed_test.dart test/game/dungeon_material_paint_test.dart test/game/dungeon_authored_material_test.dart test/game/dungeon_render_style_test.dart test/widget/palette_test.dart test/grid_geometry_test.dart test/game/hero_off_screen_test.dart test/battle_flow_characterization_test.dart test/style/type_authority_test.dart
```

`dungeon_scene_test.dart:493-504,555-580,705-720` converts a cell coordinate to
a screen point and taps it, so it is the regression proving the glyph family
change moved no cell and broke no hit test. `glyph_marks_test.dart` pins the
renderer's palette hexes — **unchanged by this unit** and must stay so.
`type_authority_test.dart` must stay green because the sweep must not disturb
`tokens.dart`.

## Green proof and package gates

```text
flutter test test/game/dungeon_scene_test.dart test/widget/dungeon_scene_bleed_test.dart
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

## Acceptance

- `dungeon_scene.dart` differs from its starting state by exactly two lines plus
  one import; `cameraCellSize`, `glyphBaseFontScale`, the `* 0.30` derivation,
  `height: 1`, `Anchor.center` and U13.1's viewport fix are untouched, and the
  diff proves it;
- all four closing greps return what the table above says, with the output
  recorded verbatim in the receipt;
- `.github/workflows/ci.yml` carries the type authority gate, guarded by
  `matrix.package == 'app'`, and both its greps are silent on the migrated tree;
- `AGENTS.md` carries the type rule;
- no test reads `lib/**.dart` as text;
- the twelve-file must-stay-green list passes;
- all three package gates green.

## Escalate, do not decide

- a `fontFamily` or `monospace` hit in a file no earlier task owned — it means
  a task missed a site, and the owning task's brief should say which;
- any need to change `glyphBaseFontScale`, the `* 0.30` derivation,
  `cameraCellSize`, `height: 1` or `Anchor.center`;
- any need to add `fontFamilyFallback` to the map glyph, or to reach for
  `textGlyph` instead of building the style inline;
- the CI gate being unable to distinguish the literal from the token reference;
- a dungeon test failing on the family change — that would mean the glyph's
  rendered box changed, which the derivation forbids.

## Receipt

Report: the two changed lines with their before and after; the verbatim output
of all four closing greps, before and after; every prose site the sweep
rewrote, with the warning it preserved; the CI gate as committed; the
twelve-file must-stay-green result; and the three package gates. **State
plainly whether AC2 is now closed.** AC3 is Task 08's to close (A4); report
grep 3's result without claiming it.
