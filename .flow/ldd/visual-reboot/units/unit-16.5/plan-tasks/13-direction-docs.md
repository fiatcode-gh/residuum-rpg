# 13 — Direction docs: design spec Visuals line and VISUAL-SYSTEM supersession

Governing: `../CONTRACT.md` scope item 5, acceptance 10; `../PLAN.md` §3
(docs split). Documentation only — no code, no tests.

## Starting repository state

Tasks 01–12 committed. `AGENTS.md` Type rule already names the mono role
(Task 01); `.github/workflows/ci.yml` already has the strict `fontFamily:`
gate and no monospace grep (Task 02). Still stale:
- `docs/specs/2026-08-20-dungeon-game-design.md` line 37 (Visuals row:
  glyphs "first", tile atlas "later").
- `.flow/ldd/visual-reboot/units/unit-13/VISUAL-SYSTEM.md` §1 (monospace
  retired), §5 row "Dungeon structure" (authored dungeon art), §7 bullets
  (`cameraCellSize` 36 dp; 600 dp ceiling budget), §8 bullet on U12.5
  dominance ("dungeon's material/light/structure/actor rendering"), §9
  "Monospace is retired entirely".

## Owned files

`docs/specs/2026-08-20-dungeon-game-design.md` (Visuals row only),
`.flow/ldd/visual-reboot/units/unit-13/VISUAL-SYSTEM.md`.
Not yours: `LEDGER.md`, `RESUME.md` (Main updates the locked-contract
section and RESUME at integration), `AGENTS.md`, CI.

## Locked decisions

1. Spec Visuals row becomes:
   `| Visuals | Coloured monospace glyphs on a grid are the permanent direction (Unit 16.5): IBM Plex Mono map glyphs with code-drawn light, fog and depth. The renderer stays separable from rules, but no tile atlas is planned |`
2. VISUAL-SYSTEM.md: do not rewrite history. Under each stale passage add a
   blockquote line
   `> **Superseded by Unit 16.5 (2026-09-23):** <one sentence>` —
   §1: IBM Plex Mono returns as a third role for map glyphs, log sentences,
   numbers and data; EB Garamond display and Spectral text stay.
   §5 "Dungeon structure" row: dungeon structure is typographic glyphs plus
   code-drawn light and fog; no authored dungeon art is planned.
   §7 `cameraCellSize` bullet: the map cell is 13 × 16 dp; aiming is by
   intent within 22 dp (`map_touch.dart`), not by large cells.
   §7 chrome-budget bullet: chrome is fixed per mode; the floors are map
   ≥ 45 % (exploration) and ≥ 35 % (battle) of logical height; the 600 dp
   ceiling and `_fitFor` are retired.
   §8 dominance bullet: the dungeon rendering gap is closed by the U16.5
   glyph/light/fog direction.
   §9 monospace bullet: superseded as in §1.
   Append to §8 a new bullet:
   `- **Monospace retired / 36 dp camera cell / 600 dp chrome ceiling / ink-only light** — superseded by Unit 16.5 (2026-09-23), see units/unit-16.5/CONTRACT.md.`
3. After editing, `grep -rn "monospace\|cameraCellSize\|600 dp\|600dp" AGENTS.md docs .github`
   returns no line asserting a retired lock as current.

## Proof

No Red/Green (docs). Proof = the grep in 3 plus
`git diff --stat` showing only the two owned files, and a reread of each
inserted line against CONTRACT scope item 5.

## Executor discretion

Exact placement of each blockquote within its section; wording of the one
sentence within the locked meaning.

## Escalate when

A tracked doc outside the two owned files still asserts a retired lock as
current (list it for Main; do not edit it).

## Completion receipt

Grep output, diff stat, list of inserted supersession lines. Commit:
`docs: record the U16.5 glyph direction and superseded locks`.
