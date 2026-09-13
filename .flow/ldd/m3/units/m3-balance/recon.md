# Recon — m3-balance (M3B): the rebalance the playtest demanded

Date: 2026-08-24. Two read-only agents (economy/difficulty numbers;
discovery/beats plumbing) on `main` @ `b9d7c21`; the architect re-verified
the load-bearing claims at source (floor-of-one, litter constants, the
xp-comment error, prices, `arrivingAt, the merchant disable condition).

## VERDICT

Every playtest verdict has a measurable root cause, and most levers are
content numbers. The smoking gun for "too easy": **13 of the game's 14
creatures deal exactly 1 damage to the graduate-kit hero** — the
floor-of-one rule (`step.dart:409, ✓ read) with armor totals (worn +
bulwark÷2 = 8 on the fixture) that outran every pierce value. The item
flood: flat litter 4–6 per floor at every crypt/keep depth (✓ read), 3–5 in
the cave — 20–43 litter per delve plus 9–16 kill drops against a 20-slot
pack. The dead currency: one gold source (selling), three sinks, ceiling
sale 72 (Epic maul), inn 12 flat forever, lifetime rumor spend 45, bank
free and uncapped. The discovery giveaway is one expression:
`arrivingAt` unions `map.adjacentTo(node)` — dropping that union alone
achieves D50's fork with NO new state (routes need no discovery model; the
`[?]` rows already carry the mystery). No camp timestamp exists anywhere;
the natural shape is a new hero-level key snapshotting `world.day` at
suspend.

## The numbers that matter (all agent-swept, spot-verified)

- **Damage equation:** `max(1, roll − max(0, wornArmor + bulwark÷2 −
  pierce))`. Fixture hero: armor 8, attack 6–11, 20 hp + 4 potions = 60
  effective. Only the rusted man-at-arms (pierce 4) and the two bosses
  break the floor of one against it.
- **Hero-side combat has NO monster mitigation** — monsters have no armor;
  difficulty on the offense side is monster-hp only.
- **Litter:** crypt 4–6 ×5 floors, cave 3–5 ×4–6, keep 4–6 ×5–7 (+1
  trophy). Monster counts: crypt 25–33/delve at 25–60% drop chances.
- **Prices:** `sellPriceOf = (atkMin+atkMax+2·armor+heal) × (1+affixCount)`
  — reads BASE stats only, affixes rolled are priceless; `buyPriceOf = 2×`
  (no-arbitrage by construction). Inn 12 (pinned only `< 20`), rumor 15,
  potions always 10/20. Merchant stock: 3 potions + 2–4 gear per town per
  visit. Bank: no fees, no caps, items and gold both.
- **Skills:** Arms/Might `level÷2` to both attack ends (uncapped — level
  100 = +50/+50); Bulwark `level÷2` armor; Fleetfoot 3%/level dodge CAPPED
  at 30% (levels 11–100 buy nothing). Max HP/speed come only from affixes.
  XP: +1 per trigger, `xpToNext = 4+2·level`; **the dartdoc says "eighty
  hits" to level 5 — the sum is 40** (✓ read; 2× documentation error).
- **Road:** dangers 15/25/30/30/40; the roll sees ONLY the route constant
  and the day — no profile, no gear (`travelOneDay` signature). ONE flat
  road spawn table (2–3 rats/wolves) for all five roads; its dartdoc
  earmarks themed road tables for exactly this era. `travelerChance` is
  the precedent for threading a content parameter into travel.
- **Camp/day:** the day advances in exactly one line (`travel.dart:195`) —
  road only; not at the inn, not camped. A camp on disk =
  `run != null, dungeon != null, inside: false`. NO pitched-day exists;
  `world.day` is per-hero, monotonic, already in the document. The visit
  arithmetic is explicitly rejected as a derivation base
  (`save_read.dart:105-111`).
- **Discovery:** `discovered` is a node set only; NO route state anywhere.
  `arrivingAt` = move + home-promote + union {node, adjacents} + journey
  drop. Rumors/travelers add exactly one node (`hearingOf`). The world
  screen: `_Place` self-censors undiscovered; `_Unheard` emits one `[?]`
  row per unknown node (count leaks, deliberate). `destinationsFrom` =
  discovered ∧ route-exists; `beginTravel` refuses undis­covered by name.
- **Beats plumbing:** the world screen HAS a log ("The road so far", `WorldViewState.log, view-state); the tavern borrows it. Town screens
  have only `notice`. NO world event stream — lines are composed in
  handlers (`travel_messages.dart`). `RoadDay` carries no
  newly-discovered delta (`arrivedAt` is the add-a-field precedent). The
  rumor purchase NEVER names the revealed place — only the flavour line.
- **Bottom floor:** `Descended` fires identically at every depth; no
  bottom/boss event exists. Controls: bottom floor offers Ascend+Leave on
  the arrival tile (hero lands on stairsUp). The world fork reads
  `camp.depth` never `deepest` — it offers "Resume the crawl (depth 6)"
  on a completed delve. **`endRun(died:false)` and `suspendRun` are the
  same six-field carry; the entire difference is the caller.**
  `_onRunEnded` clears camp+dungeon and the autosaver follows for free;
  BUT it also drops `MerchantVisit` unconditionally where suspend keeps
  it when the visit is unmoved — a regression to decide deliberately.
- **Boss death:** "The drowned captain dies." in the dim log, same as a
  crab. Boss ids are `boss-<node>` (a usable app-level key). The trophy
  is pre-placed litter, silent about being one.
- **Disabled controls, exhaustive:** merchant buy/buy-back (gold),
  world Walk (!reachable/travelling), bank ×4, inn (gold half
  unexplained). `ItemRow` has NO subtitle slot; the two-line body grammar
  exists in gear/inventory screens. The crawl's philosophy is
  build-don't-disable (`game_screen.dart:181-187`).
- **Band blindness confirmed:** 0.50–0.95 cannot fail on "too easy" —
  cave 85% and keep 78% sit inside it.

## Is each inherited gate real?

- D50 fork 4 as worded ("arrival uncovers connected ROUTES") is HEAVIER
  than its goal needs: route discovery = new save collection + codec +
  goldens + a third row kind + a walkability decision. Dropping the
  adjacency union alone gets "rumors are the real door" with zero new
  state. Proposed as the ruling; the user may veto.
- Follow-up 24's design (camp expiry ~3 days) is buildable: snapshot
  `world.day` into a new hero-level `campDay` key at suspend (v1 reshape,
  goldens by hand, refusal rows per the established net).
- Follow-ups 14/15 (clamp unification; cap-overflow quirk) are in scope
  per D50's grant — both are town.dart-sized fixes whose re-baseline cost
  is already being paid.

## Hazards to carry into the spec

- EVERYTHING re-pins: crypt 24/40 + histogram, cave 34/40, keep 31/40,
  fleetfoot 7/40, both themed bottom goldens (litter counts change), the
  characterization pins on litter-by-id, possibly the seeded-floor golden
  saves (litter volume changes floor contents → run-block goldens with
  groundItems change → hand-regenerated). The generator layout goldens do
  NOT move (layout is itemCount-independent — the M3X prefix property).
- Two scans duplicate the "undiscovered" definition (`rumorOnOffer` app, `_firstUntold` core) — a reveal-rule change must keep them agreeing.
- The completion path must preserve D36 merchant semantics (keep the
  visit-unmoved memory), or completing a delve after a resume resurrects
  the M3H stock defect in reverse.
- The inn's "nothing wrong with you" line covers only half its disable.
- `xpToNext` dartdoc: decide 40 (fix prose) or 80 (double the curve) —
  a pacing decision, not a typo fix.

## What this recon did NOT check

- No device run; all app claims from code and suites.
- The agents' unquoted tails; architect re-verified the floor-of-one,
  litter constants, xp comment, prices, arrivingAt, and the merchant
  disable only.
- What the RIGHT difficulty numbers are — the worker measures against
  re-designed targets; nothing here claims tuned values.
- Whether dropping the adjacency union starves discovery in practice
  (rumor pool order + traveler chance should carry it; playtest confirms).
