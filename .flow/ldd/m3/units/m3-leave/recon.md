# Recon — the D34 world scope (serves units m3-leave, m3-world, m3-dungeons)

Date: 2026-08-22. Architect recon for the work D34 locked. Read-only fan-out on
four angles (run boundary/suspend, save document, generation/themes,
town/navigation); every load-bearing claim below re-verified by the architect's
own reads at the cited lines.

## VERDICT

The D34 scope is three sequential units, not one. The suspend door (leave at
stairs) is a small self-contained unit with two known landmines already located;
the overworld is a large unit that reshapes app navigation; the two new themed
dungeons are a content unit that must not touch the crypt's generation path,
because the exact 24/40 pin depends on the crypt's draw order byte-for-byte.
One design consequence the brainstorm did not name: if Leave always suspends,
an alive run never ends, resume never reshuffles, and the farming loop dies —
the town door must offer Resume OR Delve-anew (abandoning the camp).

## State verified before measuring

- `main` = `f7bd6b1` (M3H, PR #4), tree clean, no worktrees, nothing in flight.
- Toolchain: Flutter 3.47.0 stable (measured this session).

## The measurement

All fresh this session, my own runs:

- Suites: 395 core + 212 content + 222 app = **829 green**.
- `flutter analyze`: clean across the monorepo.
- Survivability, live: **24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6
  5:24**; greedy 24/40 vs fleetfoot-first 7/40. Identical to the ledger's
  D24/D32 figures — the determinism cross-check holds.

## Is each inherited gate real?

- "Suspend machinery is built and resume is roll-for-roll" — REAL.
  `run_codec.dart:55-83` rebuilds `GameState` with `Rng.fromState, the suspend
  theorem test proves stream identity, and `loadRun`'s dartdoc carries the
  binding rule: *resuming is not entering, so the visit is not bumped*.
- "Switch-into-suspended-crawl is unreachable by play" — REAL, and the reason
  is structural: `boot.run != null` is only consulted at `_Session.initState`
  (`main.dart:138-147`); the only alive exit (`leaveDungeon, `game_screen.dart:241-248`) ends the run via `RunEnded` → `endRun`.
- "The save document is {version, active, heroes}" — STALE BY ONE FIELD: a
  hero entry is `{label, profile, run, merchant}` — the merchant block is
  REQUIRED, not optional (`save_codec.dart:37-42, 122-134`). The codec never
  repairs; new fields must be required or the never-repair stance is broken.
- "Themes are content, not code" — TRUE BUT INSUFFICIENT TODAY: content has no
  theme, dungeon-id, or node concept anywhere (grep: zero hits). One dungeon,
  singular, is assumed at every layer (see findings 5–6).

## Findings that change the spec

1. **A `Leave` control already exists at every stairs landing**
   (`game_screen.dart:221-227`), gated by
   `canLeave => !game.isGameOver && (canDescend || canAscend)`
   (`game_bloc.dart:132`). D34 changes what this door means; no new gate or
   button placement is needed.
2. **Landmine — town transactions erase a suspended run.**
   `TownBloc._settled` (`town_bloc.dart:289-299`) rebuilds `TownViewState`
   without any run field, and the Autosaver takes `_run = state.run` from every
   town emission (`autosaver.dart:54`). Today unreachable; the moment a hero
   can shop while a crawl is suspended, one purchase erases the camp from disk.
   The merchant block was hardened against exactly this class
   (`town_bloc.dart:96-99`); run was not. Must be fixed and pinned by mutation.
3. **Boot disambiguation.** `run != null` on disk currently means "app died
   mid-crawl → resume into the crawl" (`boot_wiring_test.dart:32-45`). With
   in-town suspension the document must distinguish inside-the-crawl from
   camped-away, or a shopping hero boots into the dungeon. An explicit
   per-hero field is needed (a derived discriminator exists — mid-crawl
   `profile.visit == run.visit - 1, after suspend they are equal — but a rule
   hanging off an arithmetic coincidence is not a contract).
4. **If Leave always suspends, the grind loop dies.** Today leave→re-enter
   reshuffles (visit++) and refills the dungeon; that is the farming economy
   (D14). With suspend-only exits and no-reshuffle resume, floors exhaust and
   never refill while the hero lives. Consequence: the town's Enter Dungeon
   door must fork when a camp exists — Resume (roll-for-roll) or Delve anew
   (abandon the camp, confirmation dialog, normal visit-bumping entry).
   Abandoning is free of data loss: suspend already synced the hero home.
5. **`floorSeed(worldSeed, depth, visit)` has no dungeon-identity slot**
   (`generator.dart:20-27, verified). Two dungeons at the same visit would lay
   out identical floors modulo theme. Content already has the salt precedent
   (`lootStreamSalt, `_marketSalt`): a per-node salt XORed into worldSeed
   gives each dungeon its own floor stream. The crypt's salt must be the
   identity (no XOR) so its floors stay byte-identical to today.
6. **One-dungeon assumptions to unpick for M3W/M3D** (all verified):
   `deepestDepth = 5` is a global core constant read by the generator, the
   HUD, and the survivability won-condition; spawn/drop tables are keyed by
   depth only; `loadRun` hardcodes `residuumDungeon(worldSeed)(visit)` — a
   resumed run cannot yet know which dungeon it is in. The run block needs a
   dungeon identity the day a second dungeon exists (M3W/M3D), not before.
7. **Open encounter maps do not fit the current generator.**
   Size is a function of depth (24+2(d−1) × 16+(d−1)), stairs are placed
   unconditionally by depth, the shipped validator rejects stairless floors
   and monsters visible from spawn, and the "neither cramped nor an empty
   cave" test pins walkable ratio < 0.6. An open map is precisely an empty
   cave. A second generator function is the honest shape; reusing
   `findProblem` in production inverts its documented purpose.
8. **`Tile` is four values** (wall, floor, stairs up/down) — water, traps,
   chests, doors do not exist. The tile↔char mapping is triplicated
   (floor_map, generator `_render, glyph_grid), all exhaustive switches, and
   `FloorMap.toAscii()` IS the save format — a new tile character changes
   on-disk documents. Terrain variety is M3D-or-later scope, consciously.
9. **The exact 24/40 depends on the crypt's draw order, not only its tables.**
   `buildFloor` draws count → itemCount → layout → creatures → items off one
   stream (`new_game.dart:71-89`); inserting any roll re-rolls every floor.
   The M3R re-baseline was exactly this class. New dungeons must be NEW
   functions beside the crypt's path, never edits inside it.
10. **No boss machinery exists** (no flag, no victory event; M2E spec
    deferred bosses to M4). The design spec's "bottom floor holds a boss and a
    guaranteed rare" can land lightly for the two NEW dungeons (a named
    bottom-floor creature in content + pre-placed guaranteed-rare litter via
    the content seam, `new_game.dart:87-91`) without core changes; the crypt
    gets none this ring or the pin moves.
11. **Precedent confirmed for where per-hero world state lives:** the
    `SavedHero.label` argument — things no rule reads stay out of core
    Profile; things rules read may join it. Position/discovery/day are
    rule-read (travel cost, encounter rolls) but belong to M3W; the suspend
    unit needs only the boot discriminator (finding 3).
12. **Inn-heal note for the suspend unit:** suspend → inn (12 gold, full heal)
    → resume is a paid mid-dungeon full heal with zero risk until M3W adds
    travel days and road encounters. Accepted interim per D34 (the user chose
    the exit-not-heal fork knowing the inn exists); the real cost arrives with
    the overworld. The survivability bot never suspends, so the pin is blind
    to this either way — say so, never cite the band here.

## Proposed shape of the work

Three sequential units (D8/D23 precedent), replacing the single M3W row:

1. **`m3-leave` (M3L, S/M)** — the suspend door. Core: `suspendRun`/
   `resumeRun` beside `startRun`/`endRun` in run_boundary. Content: per-hero
   `inside` field (v1 reshape, goldens regenerate). App: Leave-at-stairs
   suspends and lands in town (interim landing until the overworld exists);
   Enter Dungeon forks Resume / Delve-anew; the finding-2 landmine fixed and
   pinned; boot disambiguation. Resolves the play-value of follow-ups 8/22
   immediately.
2. **`m3-world` (M3W, L)** — overworld node map (2 towns + crypt node),
   travel days, encounters (open-map generator, flee at edge, traveler/quiet
   events), tavern rumors as discovery, world save block, navigation rework
   (world screen at the stack bottom), death wakes at the last town. The
   leave landing moves from town to the overworld here.
3. **`m3-dungeons` (M3D, M)** — sea-cave + ruined keep: bestiaries, spawn and
   drop tables, glyph palettes, per-node floor salts, light bottom-floor
   bosses + guaranteed rares, per-dungeon survivability bands; run-block
   dungeon identity.

## Hazards to carry into the specs

- The never-repair codec: new fields are REQUIRED; goldens regenerate in the
  SAME commit as the format change; no tooling on golden literals (the re.sub
  burn, D29).
- Autosaver subscriptions stack across repeated in-session leave/resume
  cycles (`close()` clears all at once; `watchGame` is called per `_openCrawl`)
  — the resume path must not leak or double-write.
- `GameState` has no `operator==`; the autosaver's settled-skip is identity
  (`state.game == _run`) — a resume handing back the same instance would
  suppress the first save.
- Suspend must clear the merchant visit block (the visit id changes when the
  profile absorbs the run's visit; stale buy-back lists reference dead stock
  ids).
- Widget tests never await bloc close (deadlocks the test clock — D32).
- The message log is view state and drops on resume (follow-up 19) — an
  in-session resume makes the one-line "The crawl resumes." far more visible.

## What this recon did NOT check

- No AVD/device run this session; all app behavior claims are from code and
  the existing test suite, not from live play.
- The four agents' own "NOT checked" tails apply; the architect re-verified
  the load-bearing claims (floorSeed, generateFloor hardcodes, leaveDungeon,
  canLeave, `_settled, `replacingActive`) but not every quoted line.
- `step.dart`'s monster phase and combat math were not re-read; the suspend
  unit does not touch them, and nothing here depends on their internals.
- Performance of flow-field/FOV on large open maps: unmeasured (M3W concern).
- Whether `flutter test` timings change with the new widget tests: unmeasured.
- The design spec's sections 6 (skills), 7.1 (crafting), 9 (quests) were not
  re-read; nothing in this scope touches them.
