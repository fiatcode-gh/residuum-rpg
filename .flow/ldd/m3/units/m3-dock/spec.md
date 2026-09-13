# Spec — `m3-dock` (story M3V — the dock fix)

App-only unit on `main` @ `fda107f`. No changes to `packages/core` or
`packages/content` are expected; if a found defect forces one,
pre-declare in the mailbox BEFORE code. Rulings folded in: D90 (the
trap and its root-cause chain), D91 (DOCK OVER MAP — locked; the map is
always visible; no full swap ever; no AI change, no trigger narrowing,
no new approach verb). Recon: `docs/epic/m3-dock-recon.md`.

## Goal

While a monster holds reach on the hero, the battle pieces dock over a
map that never leaves the screen: stage cards and turn strip above the
map slot, skill bar below it, the `GlyphGrid` rendered and tappable
throughout. The player closes on a ranged holder by walking the map —
the D90 trap dies by construction. When nothing holds reach, the dock
rows disappear and the screen is the crawl as it was. Measurable
effect: with a spitter holding reach at distance 3, the map is on
screen, tapping a floor tile between hero and spitter moves the hero,
and the spitter dies to two moves plus one swing — the same fight the
rules already allowed.

## Shape — precedent to follow, read from the codebase

- **`isBattleOpen` stays the trigger** (pure getter over `game, `game_bloc.dart:315-318`) — it now controls the dock rows' presence,
  not the map slot's contents.
- **Rows in the existing `Column, not a `Stack` overlay**: the current
  column is `[map-slot, _HitPoints, _Controls, _MessageLog]`
  (`game_screen.dart:51-75`). The dock inserts rows — stage cards +
  turn strip above the map slot, skill bar between the map slot and
  `_HitPoints` — present exactly while the fight holds. No
  hit-testing overlap, no `Stack` restructure.
- **The dock grammar is D89's, carried**: stage card (glyph, name, HP
  bar by length and number, range marking), turn strip, skill bar
  (marking + name + cost, wrap-flow, hidden for non-casters, tap arms /
  tap-card casts at a guess-never target).
- **Refusals speak in the log** — the house rule; the new guidance
  refusal is no exception.
- **Greyscale doctrine binds the dock**: state by shape, marking,
  position, word — never hue. The dock inherits D89's grammar; nothing
  new is coloured.

## New files

- None required. If the worker prefers to split the dock widgets out of
  `battle_view.dart` into a new file, pre-declare the path first.

## Changed files (exact paths)

- `packages/app/lib/game/game_screen.dart` — the map slot always
  renders `GlyphGrid`; dock rows (stage cards + turn strip; skill bar)
  appear above/below it while `isBattleOpen`.
- `packages/app/lib/game/battle_view.dart` — becomes (or is replaced
  by) the docked header + skill bar; the widget set it already ships
  is reused, not re-designed.
- `packages/app/lib/game/game_bloc.dart` — only if the guidance refusal
  needs a derived fact (it should not: the stage card already knows the
  monster's position and the hero's).
- Tests: `packages/app/test/battle_view_test.dart` — rewrite of the
  swap group plus new dock tests; `game_bloc_test.dart` if the refusal
  path adds a bloc-level case.

## Per-item contract

1. **The map never leaves.** While `isBattleOpen, the map slot renders
   `GlyphGrid` with the same palette, `onTap` and `onPan` wiring as the
   crawl. Tapping a floor tile during a fight moves the hero exactly as
   in the crawl (including the watched-refusal on far auto-path — that
   rule stands, D6-era teeth, unchanged).
2. **Dock rows, above:** stage cards (one per `monstersHoldingReach,
   D89 grammar) then the turn strip, in a non-scrolling column above
   the map slot. **Below:** the skill bar between the map slot and
   `_HitPoints, hidden for non-casters exactly as D89 shipped.
3. **Stage-card tap, adjacent monster (one orthogonal step):** the
   D89 grammar exactly — no armed skill = bump-attack (`TileTapped`);
   armed skill = `CastPressed` with `targetId`. Unchanged. (File
   layout per approved deviation 2: `battle_view.dart` keeps the dock
   widgets; `game_screen.dart` owns row placement.)
4. **Stage-card tap, beyond one step:** lands a guidance refusal
   sentence in the log (name the monster, tell the player to walk to
   it — exact wording is the worker's, but it must name the monster and
   say walking), and changes nothing else. The current behaviour it
   replaces is the watched-refusal line ("Something is watching. You
   stay put.") — measured in D92, worse than silence. App-side event
   per approved deviation 1: `StageCardTapped` (carrying the monster)
   in `game_bloc.dart`; its handler appends the sentence. Core is NOT
   touched: the sentence is app-side presentation around the tap, not
   a new engine refusal.
5. **The dock closes when nothing holds reach** — the rows leave, the
   screen reads as the crawl. No hysteresis, no animation required.
6. **What must NOT change:** `isBattleOpen`'s definition; the ambush
   beat; the arrivals formula (D86); the skill bar's dock grammar; the
   crawl HUD's one-string status line; any core or content file; all
   five band lines (controls — they must hold byte-identical).

## Behaviour arguments that must land in documentation

- **Why the map stays visible during a fight** — the D90 chain in one
  sentence on the dock widget: a view over a live simulation shows the
  field the simulation runs on; hiding it stranded every player whose
  only reach-holder stood beyond arm's length. This is a preserved-
  defect-inverse note: the swap is retired on purpose, so nobody
  "restores" the full-screen battle as a cleanup.
- **The watched auto-path refusal during a fight is deliberate** —
  closing on a shooter means tile-by-tile commitment while it shoots;
  the dock makes that cost visible instead of papering over it.
- **The card-tap guidance sentence is presentation, not an engine
  refusal** — core never sees the tap; the log line is the app
  translating a useless gesture into information.

## Test plan

Characterization tests FIRST, against unmodified code — these are the
D90 trap, stated as current behaviour. If they do not pass against
unmodified `main, stop and report:

- C1 — with a spitter holding reach at distance 3 (in LOS), the map
  glyph grid is NOT on screen (the swap, as shipped).
- C2 — with a spitter holding reach at distance 3 (in LOS), tapping
  the spitter's stage card emits a state change whose log gains
  EXACTLY the watched-refusal line ("Something is watching. You stay
  put."), moves nobody, and lands no blow (the lying refusal, as
  measured in D92 — this corrects the spec's original silent-no-op
  claim).

Then the new behaviour, in the same files:

- T1 — the map slot renders `GlyphGrid` WHILE the dock is up (spitter
  at distance 3): map visible AND stage card visible in one pump.
  This is the anti-trap test; it must fail on unmodified code and pass
  after.
- T2 — tapping a walkable floor tile one step toward the spitter, while
  the dock is up, moves the hero (state advances; dock stays up).
- T3 — tapping a stage card beyond one step with no armed skill adds
  the guidance sentence (naming the monster) to the log INSTEAD of the
  watched-refusal line, and emits no other state change.
- T4 — adjacent stage-card tap keeps the D89 grammar (bump-attack; and
  armed-cast names the target) — the two rewritten D89 tests.
- T5 — the dock rows leave when the last reach-holder dies or breaks
  LOS; the screen is the crawl (the rewritten swap-return test).
- T6 — a non-caster sees no skill bar row; a caster sees marking +
  name + cost (carried from D89's group, re-pointed at the dock).
- T7 — the whole screen fits at the phone surface (`_onAPhone,
  1080×2424 @ 2.625) with dock up AND with dock down, no overflow
  exceptions — map, HP, controls and log all visible in both.
- T8 — determinism/bands untouched: no core/content diff exists
  (asserted by the diff itself in verification, not a test).

### Mutation table (both halves)

| # | Mutation (by sed) | Expected red | Expected green |
|---|---|---|---|
| M1 | Dock gate: make the stage/strip rows unconditional (drop the `isBattleOpen` gate) | T5, T7 (dock-down overflow or assertion on absent rows) | T1, T2 (map/dock independent) |
| M2 | Map slot: restore the swap (`isBattleOpen ? BattleView : GlyphGrid`) | T1, T2 | T6 (bar content unchanged) |
| M3 | Guidance sentence: drop the log line from the far card tap | T3 | T4 (adjacent tap path untouched) |
| M4 | Far card tap: emit the plain `TileTapped` (the watched-refusal line, no guidance sentence) | T3 | T4 |
| C-1 (control) | Stage card HP-bar length | existing D89 stage test reddens | T1–T7 unaffected |
| C-2 (control) | Skill-bar cost label | existing D89 skill-bar test reddens | T1–T5 unaffected |

Sequencing trap: M2 re-introduces code the change REMOVES — it is
meaningful only as a temporary re-insertion; run it, report, then
revert to the dock. Report every row's named red set, greens included.

## Hazards

- Widget traps, verbatim: `find.textContaining` is case-sensitive with
  no parameter — match literal casing or use a regex;
  `scrollUntilVisible` scrolls ONE way — assertion sequences on a long
  screen must be monotonic in document order; size at least one widget
  test like a phone (`_onAPhone, 1080×2424 @ 2.625).
- The dock eats vertical map space on a phone; the AVD pass is
  MANDATORY (ten device-only catches on record) — check the crawl fits
  and every dock row is reachable by thumb with dock up.
- AVD/install traps restate verbatim from the build prompt when it is
  written (save-slot copy-aside before ANY install; `flutter install`
  data-wipe; emulator storage; serial pinning).
- Greyscale deliverables: dock-up and dock-down acceptance shots, plus
  greyscale variants, into `docs/reports/shots/m3-dock/` in the MAIN
  repo.

## Follow-ups to log

- None new expected. If the dock makes the spitter fight feel trivial
  or the ambush feel muted, that is a balance verdict for the user's
  next playtest, not a code change here.

## Definition of done

- `packages/core` and `packages/content` have ZERO changed files
  (`git diff main -- packages/core packages/content` empty).
- All three suites green from the worktree root, counts from result
  files against a FRESHLY measured baseline (measure before the first
  change; `dart analyze .` from the worktree root, pwd quoted).
- C1/C2 pass pre-change; T1–T7 pass after; every mutation row reported
  with its named red set, greens included.
- `dart format` clean; no commit under `docs/`.
- AVD pass complete; greyscale shots saved; device findings (if any)
  fixed or pre-declared.
- REPORT.md mirrors the verification block to the channel.