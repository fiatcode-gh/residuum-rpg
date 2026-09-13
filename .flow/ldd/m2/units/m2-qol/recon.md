# Recon — m2-qol (M2Q), 2026-08-21

## VERDICT

All five QOL items plus the three architect additions are buildable in one
M-sized unit. Four are pure app-layer presentation; only town equip touches
core, and it can reuse the dungeon's equip rule by extraction. One inherited
"defect" dissolved (negative HP already clamps) and one hidden defect was
found (silently refused walks).

## State verified before measuring

- `main` @ `8596adb` (README) ← `0824d8d` (M2T), working tree clean, in sync
  with `origin/main, no worktrees besides the main checkout. Measured this
  session via `git log`/`git status`/`git worktree list`.

## The measurement

- Test baseline, fresh this session (`flutter test` per package):
  **352 core + 95 content + 67 app = 514 green.**
- `flutter analyze`: no issues. Toolchain: Flutter 3.47.0 stable (no fvm).
- Tap-target size: `GridGeometry.fit` fits the whole floor
  (`grid_geometry.dart:14`); floors are `24+(depth-1)*2 × 16+(depth-1)`
  (`generator.dart:215`), so depth 5 = 32×20 tiles → ~12dp cells on a ~400dp
  screen. Android guideline: 48dp.
- Silent refusal: `game_bloc.dart:171` — a tap on a far tile while any monster
  is visible returns with no event, no log line, no state change.
- Watching predicate: `_somethingIsWatching` (`game_bloc.dart:304`) = any
  monster whose position is in `game.visible`. One expression; the Engaged
  chip can share it.
- Item stats already computed: `Item.attackMin/attackMax/armor/maxHp/speed`
  getters (`item.dart:167-175`); nothing in the UI shows them.
- Inventory rows: rarity marking + `displayName` + buttons only
  (`inventory_screen.dart:_CarriedRow`); no grouping, no stacking, no stats.
- Town transactions precedent: `Transacted = (Profile, TownRefusal?)` pure
  functions in `town.dart`; `TownBloc` wraps each in an event handler.
- Dungeon equip rule: validation at `step.dart:181-192` (not carrying / not
  wearable / shield-while-two-hander refused), mutation in private `_equip`
  (`step.dart:310`): displacement is asymmetric (two-hander displaces shield;
  shield vs two-hander refused), events ItemUnequipped per displaced then
  ItemEquipped. Unequip refuses on full pack (`step.dart:197`). Equipment
  changes clamp hp to the loadout ceiling with a floor of one
  (`_clampedToMaxHp, `step.dart:348`).

## Is each inherited gate real?

- Follow-up 6 (negative HP label) — **dissolved**: `game_screen.dart:54`
  already clamps to zero. Closed in the ledger (D19).
- "Tap targets too small" — real and measurable (12dp vs 48dp guideline).
- "No equip in town" — real: equipment mutation exists only as a dungeon
  `GameAction`; `Profile` has no equip transaction.

## Findings that change the spec

1. **Equip displacement can exceed the pack cap** in the dungeon today:
   equipping a two-hander while wearing weapon + shield removes one carried
   item and adds two displaced ones (net +1) with no cap check. Town equip
   must mirror this exactly; "fixing" it in one place would fork the rules.
   Pin it with a test as a preserved behavior.
2. **The refusal fix and the Engaged chip must share one predicate** —
   `_somethingIsWatching`'s expression — or the chip can lie about why a walk
   was refused.
3. **Camera can be pure geometry**: `GridGeometry` already separates origin
   math from painting and tap math (`positionAt` is origin-relative), so a
   camera is a new origin computation, testable exactly like
   `grid_geometry_test.dart` tests `fit`.
4. **Snap-back can be bloc-owned and therefore testable**: every action
   already constructs a fresh `GameViewState`; if the camera pan lives there,
   snap-back on the next hero action happens by construction and BLoC tests
   cover it — no widget tests needed (app convention).

## Proposed shape of the work

One unit, branch `m2-qol, story M2Q. Core: extract the equip rule to a
shared pure module + two new town transactions. App: camera geometry + pan
event, inventory presentation module (stat lines, grouping, stacking,
worn-deltas), Engaged chip + refusal log line, town gear screen, potion count
on the quick-drink button. No content changes at all.

## Hazards to carry into the spec

- Event order in `step` must be byte-preserved by the extraction (events
  drive the log and future quest triggers).
- Town unequip must clamp hp like the dungeon does (floor of one).
- Balance levers: nothing in this unit may touch bestiary, hero base stats,
  drop/spawn tables, or the xp curve. The survivability run must come back
  exactly 25/40.
- Greyscale rule: deltas and the Engaged state are shape + word + number,
  never hue.

## What this recon did NOT check

- On-device feel of 36dp cells (chosen from the Android guideline, not from
  play) — the worker may tune the constant and must report the value shipped.
- Whether pan and tap gestures conflict in practice on the real device.
- Merchant stock and bank lists were not audited for stacking (scoped out;
  follow-up).
- The exact rendering cost of painting all tiles under a camera (32×20
  TextPainters was already the fitted-view cost; assumed fine, not profiled).
