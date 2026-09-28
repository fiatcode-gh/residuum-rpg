# 10 — Direction docs: VISUAL-SYSTEM supersession

Governing: `../CONTRACT.md` scope §8; `../PLAN.md` §3, §5. Documentation
only — no code, no tests.

## Starting repository state

Tasks 01–09 committed. `.flow/ldd/visual-reboot/units/unit-13/VISUAL-SYSTEM.md`
(tracked shared ledger file) still states, in §7 "Locks that parity may not
reopen": the four-region rule with "action shelf = verbs … combat has one
action row"; the `readiedSpellCount` / "eleven chips is the true row ceiling
and `Flee` never appears in a crawl" bullet; the U16.5 blockquote naming the
16 × 20 dp cell and 24 dp aiming; the U16.5 blockquote on fixed chrome per
mode and the 45 %/35 % floors; and §5's "action shelf" consumers.
`docs/specs/2026-08-20-dungeon-game-design.md` has no crawl layout claim.

## Owned files

`.flow/ldd/visual-reboot/units/unit-13/VISUAL-SYSTEM.md` only.
Not yours: `LEDGER.md`, `RESUME.md` (Main updates the locked section and
RESUME at integration), `AGENTS.md`, the spec, CI.

## Locked decisions

Do not rewrite history. After each stale passage add one blockquote,
`> **Superseded by Unit 16.6 (2026-09-24):** <sentence> See units/unit-16.6/CONTRACT.md.`:
1. Four-region bullet: verbs are split between the persistent bottom menu
   (Quests, Spells, Quick, Hero), the log-side Wait/Flee, on-map place
   pop-ups and the map itself; turn order and the target card float over
   the map, and there is no action row.
2. `readiedSpellCount` bullet: readied spells live in the Spells pop-up
   (three, plus the grimoire); Flee sits beside the log whenever fleeing is
   legal; there is no chip row or ceiling.
3. After the U16.5 cell blockquote: the map cell is 24 × 30 dp; the camera
   keeps the hero centred on every floor with bounded pan; a tap within
   48 dp of the hero steps by dominant axis and monsters keep a 24 dp
   radius.
4. After the U16.5 chrome blockquote: the chrome is one fixed composition in
   every crawl state (HUD, map, log row, bottom menu); the map rectangle is
   identical in exploration, Watched, battle and armed; the 45 %/35 %
   floors, the five-slot contextual bar and the three-column hero and combat
   panels are retired.
5. §5 table rows naming "action shelf": one blockquote under the table:
   the action shelf is retired; verb and spell marks appear on the bottom
   menu, the pop-ups and the log-side controls.
6. §8 "Superseded" list gains one bullet: **16 × 20 dp cell / fixed chrome
   by mode / five-slot bar / hero and combat panels / "action shelf =
   verbs"** — superseded by Unit 16.6 (2026-09-24), see
   units/unit-16.6/CONTRACT.md.

## Proof

`git diff --stat` touches only VISUAL-SYSTEM.md; every pre-existing line is
unchanged (`git diff` shows additions only); each blockquote renders as
Markdown (no broken list nesting — keep a blank line where the file's
existing blockquotes do).

## Executor discretion

Exact sentence wording within the locked meaning; placement of each
blockquote directly after its passage.

## Escalate when

A passage the contract names cannot be found, or another passage asserts a
retired rule as current and is not in this list.

## Completion receipt

Diff stat, list of blockquotes added with their line anchors. Commit:
`docs: mark crawl layout rules superseded by Unit 16.6`.
