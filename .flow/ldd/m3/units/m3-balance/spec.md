# Story spec — M3B `m3-balance`: the rebalance

Unit `m3-balance, branch `m3-balance, base `b9d7c21` (main, post-PR #9).
Scope locked by D49/D50; recon in
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-balance-recon.md`
(read it first — the numbers below are all sourced there). Baseline: 529
core + 396 content + 371 app = **1296 green**; survivability lines:
crypt `24/40 (60.0%), 1:1 2:9 3:6 5:24, fleetfoot 7/40, sea-cave
`34/40 (85.0%), keep `31/40 (77.5%)`.

## Goal

The playtest's five verdicts die in one wave: enemies stop dealing a
universal 1 damage (the floor-of-one stops being the whole game), the item
flood dries up and loot moves to kills, camps expire so the leave/resume
loop has a price, the road scales with the hero, discovery becomes
something rumors sell rather than walking gives away, and the game starts
talking — a discovery is named, the bottom of a delve is a moment, a
completed delve ENDS, and a disabled button says why. Every survivability
figure re-pins by design; the crypt's layout stays byte-identical while
its numbers move.

## Scope fence (what this unit is NOT)

- No spells, no damage types, no resistances (m3-magic). No chests
  (deferred, D50). No new tiles. No monster armor stat.
- No new dungeons, no depth changes, no generator layout change of any
  kind — `floorSeed, `generateFloor, layout goldens untouched.
- No save-version bump (one sanctioned v1 reshape: the `campDay` key).
- No theme-shaped generators (rectangular floors stay — logged follow-up).
- No touching `dungeonSalt`/`delveDepth`/`dungeonFor` — floor STREAMS stay
  identical; what changes is what stands and lies on the floors.

## Design rulings (architect authority; the user may veto before launch)

1. **Discovery: `arrivingAt` stops revealing neighbours — that is the
   whole rule change.** It unions in only the node arrived at (which the
   hero could already name). No route-discovery state, no new save key:
   the `[?]` rows already carry "somewhere exists", and rumors + the
   traveler become the only doors to new places. This implements D50 fork
   4 with zero new machinery; the fork's "reveal routes" wording is
   superseded by this cheaper shape. The rumor purchase now NAMES the
   place: a second log line "<Name> is on your map now." beside the
   flavour line (composed in the app; `Rumor.reveals` finally rendered).
   The traveler line already names its reveal.
2. **Delve completion: leaving from the bottom floor ENDS the run alive.**
   `game.depth == game.deepest` forks the Leave control: it reads
   "Leave — the delve is done" and sends `RunEnded(state, died: false)`
   (the event and handler exist; the autosaver clears the camp for free).
   Above the bottom, Leave suspends exactly as today. THE CONTRACT
   `_onRunEnded` must gain: preserve the D36 merchant semantics — keep
   `MerchantVisit` when the visit did not move, exactly as suspend does
   (today it drops it unconditionally; completing after a resume must not
   resurrect stock). The world fork's "Resume the crawl (depth N)" gains
   the delve's size ("depth 3 of 6") while we are in that string.
3. **Beats are app-level; core gets NO boss machinery** (M4 owns that).
   Three composed lines/moments, the `roadOpeningLog` precedent:
   arrival on the bottom floor appends "This is the bottom of the
   delve."; an `ActorDied` whose id starts `boss-` appends "<Name> is
   slain. The delve is yours." (the id prefix is the content contract M3D
   shipped); completing (ruling 2) confirms via dialog before ending —
   "The delve is done. Leave with your spoils?" — because it is
   irreversible where suspend is not.
4. **Camp expiry (resolves follow-up 24): K = 3 days.** A new hero-level
   save key `campDay` (null exactly when no camp; written at suspend from
   `world.day`; cleared on resume, completion, abandon, death). The check
   is LAZY: wherever the resume fork is offered or resume is attempted, `world.day - campDay >= 3` means the camp is OVERRUN — the fork shows
   "Your camp was overrun" (a notice/log line: "Residue has refilled the
   wound. The camp at <name> is lost.") and offers plain Enter; the next
   entry bumps the visit as any fresh entry does. Gear, bank, profile
   untouched (the hero was synced home at suspend — abandonment was
   always free of data loss). At `world.day - campDay == 2` the fork
   carries a warning line ("One more day and the camp is overrun.").
   Sanctioned v1 reshape: goldens by hand, missing-key + inconsistency
   refusal rows per the established net (`campDay` set with no run →
   refused; camped with no `campDay` → refused).
5. **Difficulty: the floor-of-one stays; pierce and deep attack ranges
   re-scale so it stops being the norm.** The mechanism is not changed —
   the numbers are. THE CONTRACT is a new content test (the
   designed-difficulty pin), and it is depth-scoped to honor the
   shallow-floors-reward-armor intent: **every creature that appears in
   any spawn table at depth 3 or deeper must, against the survivability
   fixture kit (armor 8), have `maxRoll − max(0, 8 − pierce) >= 2`** —
   i.e. its best blow breaks the floor of one by at least 2. Creatures
   whose homes are only depths 1–2 are exempt and asserted AS exempt, by
   name. The arithmetic consequence the worker tunes to:
   `pierce >= 10 − maxRoll` for every depth-3+ creature — reachable by
   raising pierce, raising the deep attack ceiling a notch, or both;
   which lever per creature is the worker's call WITH A TRAIL, measured
   against the ruling-11 bands after every delta. Monster hp untouched
   (hero offense is fine). Hero formulas and the fixture kit untouched.
6. **Loot: litter cut hard, kill drops up.** First guesses: crypt litter
   4–6 → 1–2 per floor; sea-cave 3–5 → 0–2; keep 4–6 → 1–2. Drop chances
   +10 across every non-boss creature (rat 35, wolf 40, ghoul 50,
   skeleton 60, wight 70; crab 45, sailor 55, eel 40, hag 65; hound 40,
   deserter 50, man-at-arms 60). Bosses stay 100; trophies untouched.
   Merchant gear stock 2–4 → 1–3. Prices, inn, rumor, bank all UNCHANGED:
   the currency heals through scarcity of income, not dearer sinks — and
   `innPrice < buyPriceOf(potion)` stays pinned. The no-arbitrage rule
   stays by construction.
7. **Road: danger scales with the hero, and the two new roads get themed
   tables.** A content function `dangerOn(route, profile)` = route danger
   + progression tier (tier = total skill levels ÷ 8, capped +20),
   threaded into `travelOneDay` as a value the app computes — the
   `travelerChance` precedent; core still never sees a Profile. Themed
   road spawn tables (the seam `world.dart:205-208` earmarked): the
   sea-cave road rolls crabs/sailors, the keep road hounds/deserters;
   the three old roads keep the lowland table. Road drop table untouched.
8. **Follow-ups 14 and 15 are ruled and done in this window:** the equip
   hit-point clamp unifies (both paths clamp on take-off AND wear — one
   rule, one home, both sides' pins updated), and the
   cap-overflow-on-displacement quirk is FIXED (displacement respects
   `inventoryCap`; the refusal names the full pack). Both re-baseline
   costs are already being paid this unit.
9. **Disabled controls say why.** `ItemRow` gains an optional `reason`
   (a `monoDim` second line, rendered only while disabled — the
   gear-screen two-line grammar). Merchant buy/buy-back: "you cannot
   afford this". Inn: the gold half gets its sentence ("a night costs
   12 and you carry N"). World Walk when unreachable: "no road runs
   there from here". Bank rows: "your purse/vault does not have it".
   The crawl keeps its build-don't-disable philosophy untouched.
10. **The xp dartdoc's "eighty hits" becomes the true forty** (prose fix;
    the curve itself is untouched — pacing was never the complaint).
11. **Bands re-designed with the re-pins:** every exact figure dies and
    re-pins (crypt included — the D43 promotion keeps wins + histogram
    asserted, at NEW values). Targets the worker tunes toward: crypt
    fresh-hero 18–28/40 (45–70%); cave and keep with the fixture kit
    20–32/40 (50–80%). The band assertions tighten to 0.45–0.80 all
    three. Stalled stays 0. The fleetfoot comparison re-measures. If a
    target cannot be reached inside the first-guess deltas, STOP and
    message the architect with the measured trail — do not invent new
    mechanisms.

## New and changed files

Core: `world/whereabouts.dart` (ruling 1), `world/travel.dart` (danger
value threading, ruling 7), `town/town.dart` (rulings 8). NOTHING else in
core — `step.dart, `generator.dart, `game_state.dart, `run_boundary.dart, `loadout.dart` byte-untouched (the skills prose fix is `skills/skill.dart`
dartdoc only).
Content: `bestiary.dart, `sea_cave.dart, `ruined_keep.dart` (pierce,
drop chances, litter), `drop_tables.dart` (litter), `economy.dart`
(merchant gear count), `world.dart` (themed road tables, `dangerOn`), `save/save_codec.dart` + `save/save_read.dart` (`campDay`).
App: `world/world_screen.dart` (fork: overrun/warning/completion wording), `world/world_bloc.dart` (rumor-names-the-place line, expiry notice), `town/town_bloc.dart` (completion merchant-keep, campDay plumbing), `game/game_bloc.dart` + `game/game_screen.dart` (beats, Leave fork,
completion dialog), `town/town_style.dart` (`ItemRow.reason`), `town/inn_screen.dart, `town/merchant_screen.dart, `town/bank_screen.dart, `save/autosaver.dart` + boot (`campDay`).

## Behaviour arguments that must land in documentation

- Why arrival reveals nothing beyond itself (walking is travel, not
  cartography; the tavern sells the map — and the `[?]` rows are the
  standing invitation) — on `arrivingAt, replacing the current argument.
- Why completion ends and suspend keeps (a delve with nothing below is a
  promise kept; offering to resume it is a lie the fork used to tell) —
  on the Leave fork and `_onRunEnded`.
- Why the floor of one SURVIVES the rebalance (armor may never make a
  monster harmless) while pierce outruns armor again — on the pierce
  values, superseding the current curve prose.
- Why K=3 (an inn trip fits the window; a shopping tour does not — the
  loop is priced, not closed) — on `campDay`.
- Why prices did not move (income scarcity, not dearer sinks, is what
  makes a currency matter; the no-arbitrage and inn-under-potion pins
  survive untouched) — on the drop tables' new numbers.
- The named-exception shape of the designed-difficulty pin (a nuisance is
  a design decision, so the test names its nuisances) — on that test.

## Test plan

### Characterization first (must pass against UNMODIFIED code)

- The full existing net, run and quoted before any change: all four
  survivability lines, both themed bottom goldens, the litter-by-id pins,
  golden saves, generator layout goldens.
- NEW pre-change pin: a test asserting today's `arrivingAt` adjacency
  union (it exists: `whereabouts_test.dart:97-108`) is REWRITTEN red-first
  when the rule lands — quote the old assertion in the commit message.

### The re-pin ledger (deletions this spec sanctions, nothing else)

Survivability exacts + histograms (all three + fleetfoot), the two themed
bottom-floor goldens, litter-by-id pins, golden saves (campDay + litter
volume), the arrivingAt adjacency assertions, the two clamp/cap quirk pins
(follow-up 14/15 tests), the flat-road-table assumption tests. Each
deletion lands in the SAME commit as its replacement, old value quoted.

### Mutation table (run on COMMITTED code; both halves; extend it)

| # | Mutation (architect re-runs at least one with own sed) | Expected |
|---|---|---|
| 1 | drop `campDay` from the hero encoder | golden red + missing-key refusal red |
| 2 | expiry K: 3 → 999 | overrun test red (a 3-day-old camp resumes) |
| 3 | remove the K-1 warning | warning test red |
| 4 | `arrivingAt` re-adds `...map.adjacentTo(node)` | reveals-only-itself test red (core) + world-screen discovery test red (app) |
| 5 | completion sends `RunSuspended` from the bottom | completion test red (camp survives a done delve) |
| 6 | completion drops the merchant keep | D36-keep-on-completion test red |
| 7 | boss beat: id key `boss-` check removed | boss-slain beat test red |
| 8 | bottom-arrival line removed | beat test red |
| 9 | `ItemRow` renders no reason while disabled | widget test red |
| 10 | revert the wight's pierce to its old value | designed-difficulty pin red, naming the wight |
| 11 | keep road rolls the lowland table | themed-road content test red |
| 12 | `dangerOn` ignores the tier | scaling test red (content) |
| G1 | litter cut only (before other tuning) | generator LAYOUT goldens GREEN (the M3X prefix property — litter volume cannot move a layout); survivability moves (re-measured) |
| G2 | any pierce change | core suite GREEN at 529 (pierce is data; the equation is untouched) — truthful weak half, say so |

Sequencing: rows 2–3 need campDay landed; row 10 needs the new pin; the
survivability re-pins land only after tuning converges (one commit, old
figures quoted). Rows red on one layer and green on another report both
halves.

## Hazards

- Every ledger environment trap verbatim in the build prompt, including
  the two newest: analyze from the WORKTREE ROOT (pwd quoted); copy BOTH
  device save slots aside before any acceptance push.
- Goldens BY HAND, never tooling (D29); reds reported as NAMED SETS;
  coincidence-capable mutants under-report — prefer constant shifts
  (D47).
- The duplicated undiscovered-scan (`rumorOnOffer` app /
  `_firstUntold` core) must stay agreeing under ruling 1 — one test per
  layer.
- The world log is view-state and the tavern borrows it — the
  names-the-place line will appear under "What you have been told";
  check it reads sanely there.
- `RoadDay` carries no discovery delta — under ruling 1 no arrival
  discovery exists, so DON'T add the delta field (YAGNI; the need died
  with the union).
- Death on the road calls `arrivingAt(home)` — under ruling 1 it no
  longer re-reveals home's neighbours; nothing depends on that (they were
  revealed on first arrival and discovery never shrinks) — but say so in
  the report.
- The completion dialog is the FIRST irreversible confirm in the crawl —
  widget tests for both branches (confirm ends, cancel stays).
- The tuning loop is bot-driven: measure after every delta, keep the
  trail (the M3D four-step trail is the format).
- A physical phone may be attached: pin to `emulator-5554`.

## Must-not list

- No edit to `step.dart, `generator.dart, `game_state.dart, `run_boundary.dart, `loadout.dart, `dungeons.dart, `dungeon_spawn.dart, `armory.dart, `affix_pool.dart`. No hero formula, kit, or price change.
- No save-version bump; no golden edits via tooling; no unseeded Random;
  no body comments; no hue-only signal.
- No new events in core (`event.dart` untouched — the beats are composed
  lines, ruling 3).
- Never commit under `docs/epic/` or `docs/reports/`. Never touch a
  physical phone. No pushing, no PR — the architect handles external
  writes on the user's approval.

## Follow-ups to log (do not do them)

- Theme-shaped generators (rectangular floors — spec section 4 / M5).
- Chests (D50 deferral stands).
- A road-survivability instrument (the bot still never travels).
- `ItemRow.reason` on the remaining silent disables if any survive.
- Whether the traveler's free reveal undercuts the tavern once players
  learn to fish for it (watch the next playtest).

## Definition of done

1. Suites green in the worktree; counts quoted; declaration-count
   cross-check run; deletions confined to the re-pin ledger, each with
   its replacement in the same commit.
2. All survivability lines re-pinned inside the ruling-11 targets, with
   the FULL tuning trail (every delta, every re-measure). The
   designed-difficulty pin green with its two named exceptions.
3. Core diff confined to the three named files; must-not list untouched
   (`git diff main --name-only` quoted); generator layout goldens
   byte-identical.
4. Mutation table complete on committed code, both halves, reds as named
   sets, extensions where the spec is blind.
5. Save: `campDay` refusal rows in place; goldens hand-regenerated;
   a camp round-trip proving expiry (suspend day N → travel 3 days →
   fork shows overrun → enter bumps visit).
6. AVD pass (mandatory; copy BOTH device save slots aside first):
   fresh hero → crypt delve feels the new numbers (quote the HUD damage
   lines) → complete a delve at the bottom (dialog, run ends, world fork
   offers plain Enter) → camp somewhere → walk 3 days → overrun notice
   seen → buy a rumor and see the place NAMED in the log → a disabled
   merchant row shows its reason. Greyscale shots of the new
   reason/beat lines. State the acceptance fixture's stat delta FIELD BY
   FIELD if any save is seeded (D47 doctrine).
7. Analyze from the WORKTREE ROOT (pwd quoted) and format clean,
   project-wide.
8. Report mirrored to `docs/reports/BUILD-REPORT.md`; plan in
   `docs/plans/`; every spec claim checked and found wrong, with sources.
