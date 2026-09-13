# Story spec — M3H "Heroes" (unit `m3-heroes`)

Decided in ledger D28 (roster, buy-back, uncapped) and D31 (widget tests
granted in full). Recon: `m3-heroes-recon.md`. Base: `main` @ `f758c3f,
768 tests (395 core + 197 content + 176 app), measured fresh 2026-08-21.
Survivability baseline: exactly 24/40.

## Goal

The multi-hero document gets its face: a roster screen in town to create
(named), switch, and delete heroes — the game never has zero — replacing
the Abandon Hero button. The merchant forgives accidents: everything sold
this visit can be bought back at the price they paid, and purchases finally
survive a relaunch (today the stock resurrects and re-buying duplicates an
item id). The repository gains its first widget tests (D31), and the three
formerly-invisible wiring mutations (canPop, didPop guard, autosaver
attachment) must now redden.

## Shape — precedents to follow

- **Session rebuild**: `main.dart`'s generation-key pattern
  (`_startOver, ValueKey) — switching and deleting heroes reuse it.
- **Resume door**: `_openCrawl(run, resumed: true)` — switching to a hero
  with a suspended run lands in their crawl through the same door.
- **Town door + dialog**: the Gear door and `_confirmAbandon`
  (town_screen.dart) are the navigation and confirmation precedents.
- **Transactions**: `buyItem`/`sellItem` take the price as a parameter —
  buy-back is `buyItem(profile, item, sellPriceOf(item))`. No core or
  economy change.
- **Document evolution**: M3S's roster commit — one commit, golden
  regenerated with the format step, argued in the message.

## New files

- `packages/app/lib/town/roster_screen.dart` (+ a creation dialog/screen
  as the worker sees fit).
- `packages/app/test/widget/` — the first widget tests (route guard, boot
  wiring, roster flows). Establish the style: plain `testWidgets, real
  widgets over injected fake stores, no golden images.
- Codec/test additions for the visit-state fields.

## Changed files

- `packages/content/lib/src/save/*` — hero entry gains visit state.
- `packages/app/lib/main.dart, `town/town_bloc.dart, `town_screen.dart, `save/boot.dart, `save/autosaver.dart` — roster wiring, abandon
  retirement, buy-back state.
- `packages/app/lib/town/merchant_screen.dart` — buy-back section.
- `CLAUDE.md` — the D31 testing amendment (exact text below).
- Golden fixture regenerated once.

## Per-item contract

### 1. Save document: per-hero visit state

- Hero entry gains `{bought: [stock item ids], sold: [item references]}`.
  Both empty on a fresh hero, both CLEARED when the visit bumps (endRun —
  the merchant re-stocks per visit by design).
- v1 is reshaped in place one more time (legal: unshipped, follow-up 20
  not yet triggered). Golden fixture regenerated in the same commit.
- Decoder: missing block in an otherwise-valid v1 document is a structured
  failure (the format never shipped; there is exactly one shape).

### 2. Merchant: no resurrection, and buy-back

- Displayed stock = `merchantStock(worldSeed, visit)` minus `bought` —
  purchases survive relaunch; the id-duplication defect dies. Pin it: a
  decoded document's stock excludes bought ids.
- Selling appends the item (full reference) to `sold`. The merchant
  screen shows a Sold-back section: each item re-buyable at EXACTLY
  `sellPriceOf(item)` — the price paid, not the markup. Re-buying removes
  it from `sold`; gold and pack cap rules are `buyItem`'s, unchanged.
- Both lists persist through kill/relaunch (they live in the document)
  and clear on the next visit.

### 3. Roster

- A `Heroes` door on the town screen (Abandon Hero button, its dialog, `abandonActiveHero, the `abandoned` flag and its BlocListener are all
  RETIRED — deleted with their tests, argued in the commit).
- The roster lists every hero: label, plus a derived line — hp/maxHp,
  carried and banked gold, visits, and the word `below (depth N)` when a
  run is suspended. Words and numbers, never hue (greyscale rule).
- **Create**: asks a name, prefilled `Hero <n>`; rolls a world seed from
  the sanctioned clock site; new hero becomes active; session rebuilds.
- **Switch**: tapping another hero makes it active, saves the document,
  rebuilds the session; a suspended hero resumes straight into their
  crawl. No confirmation (nondestructive).
- **Delete**: confirmation dialog naming the hero — and saying the
  suspended run dies with them when one exists. Deleting the active hero
  makes the first remaining hero active. Deleting the last hero flows
  directly into creation: **the game never has zero heroes** and the
  document on disk never holds an empty roster.
- What it must not do: no rename-after-creation (follow-up), no slot cap,
  no reordering.

### 4. The D31 testing amendment (CLAUDE.md)

Replace the app line of the Testing section with exactly this sense (the
worker may polish wording, not meaning):

> **app:** BLoC-level tests (events → states) are the default. Widget
> tests are permitted wherever a bloc test cannot observe the behavior —
> route guards, boot wiring, navigation, dialogs. No golden-image tests;
> look and feel are still verified manually on device.

### 5. The wiring tests the exception exists for

- Back guard: `canPop` is false on the crawl route; a declined pop logs
  the stairs line; `didPop == true` dispatches nothing.
- Boot wiring: the autosaver is attached before first interaction (the
  M3S severe defect, now pinned); a boot with a run block navigates into
  the crawl.
- Roster flows: delete requires the confirmation; last-hero delete lands
  in creation; switch rebuilds onto the other hero.

## Behaviour arguments that must land in documentation

- Why bought/sold live in the save document and not in view state (the
  resurrection defect; ids duplicating on re-buy).
- Why buy-back charges the price paid (an undo, not a trade — the
  merchant made no margin on your mistake), at the transaction site.
- Why the game never has zero heroes, at the delete flow.
- The roster/delete/switch rebuild rides the generation key — why (the
  autosaver and blocs must be torn down, not re-pointed), beside the key.

## Test plan

Characterization first, against UNMODIFIED code:

- C1 (bloc): selling an item today leaves no trace but gold — pin, then
  supersede with the sold-list assertion (deleted with argument, like
  M3S's C1).
- C2 (content): today's decoder accepts a hero entry without visit-state
  fields — this test is DELETED in the format commit (one shape rule).

Then: codec round-trips (bought/sold, two heroes with distinct visit
state), clear-on-visit-bump, stock-excludes-bought after decode, buy-back
price and removal, roster bloc events, and the widget tests of section 5.

### Mutation table

| # | Mutation (one line, revert after; code committed first — house rule) | Must go red | Must stay green (control) |
|---|---|---|---|
| 1 | buy-back charges `buyPriceOf` | buy-back price test | sell price tests |
| 2 | `bought` not persisted (stock from tables alone) | stock-excludes-bought decode test | in-session stock test |
| 3 | visit bump keeps `sold` | clear-on-bump test | mid-visit buy-back test |
| 4 | delete skips the confirmation dialog | roster widget test | delete bloc test |
| 5 | last-hero delete leaves an empty roster | never-zero widget/bloc test | non-last delete test |
| 6 | switch edits `active` in memory but never saves | switch-persists test | in-session switch test |
| 7 | crawl route `canPop` flipped to true (M3S row 22) | back-guard widget test — THE D31 PROOF | bloc suite |
| 8 | `didPop` guard dropped (M3S row 24) | back-guard widget test | log-line bloc test |
| 9 | autosaver never attached (the M3S boot defect, reintroduced) | boot-wiring widget test | codec suite |
| 10 | CONTROL — no mutation | — | all suites green; survivability exactly 24/40 |

Rows 7–9 are the unit's acceptance in miniature: each was invisible to
768 tests before D31. If any stays green with its widget test in place,
the test is wrong — stop and fix the test, not the row.

### Sequencing traps

- C1/C2 run at base and are deleted-with-argument in their commits.
- The format change and golden regeneration are ONE commit.
- Every mutation row runs against committed code (house rule from M3S).

## Hazards

- First widget tests: keep them wiring-level; a screenshot-shaped widget
  test would creep toward the goldens the amendment forbids.
- Deleting or switching away must not race a pending autosaver write —
  await the store like `_abandon` does today.
- The roster shows data from EVERY hero while blocs exist only for the
  active one — read the document, not the blocs.
- Retiring the abandon plumbing deletes tests; every deletion is argued.

## Follow-ups to log

- Hero rename after creation.
- Roster ordering (most-recently-played first?) once heroes accumulate.

## Definition of done

- All three suites green; baseline was 395/197/176 = 768 (fresh,
  2026-08-21, `f758c3f`); report new counts and every deleted test with
  its argument.
- `flutter analyze` clean; `dart format --set-exit-if-changed .` clean.
- Mutation table fully run (rows 7–9 red), both halves reported.
- Survivability exactly 24/40, stalled 0; forbidden levers untouched.
- CLAUDE.md amendment landed as one commit.
- AVD acceptance, screenshot-paired: create a second named hero; switch
  to a suspended hero and land in their crawl; delete the active hero;
  delete down to the last hero and get the creation flow; sell an item,
  kill the app, relaunch, buy it back at the paid price; buy an item,
  relaunch, confirm it stays gone from stock. Greyscale check of the
  roster and merchant screens.
- `BUILD-REPORT.md` mirrors the verification block, hashes pasted.
