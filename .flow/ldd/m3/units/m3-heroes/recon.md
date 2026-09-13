# Recon — m3-heroes (M3H), 2026-08-21

## VERDICT

The roster is mostly assembly of parts M3S built (multi-hero document,
session rebuild via generation key, boot resume); the genuinely new ground
is the first widget tests in the repository (D31) and one surfaced defect:
merchant stock resurrects across a relaunch, which this unit fixes by
persisting per-hero visit state — legal while format v1 is unshipped
(follow-up 20).

## State verified before measuring

- `main` @ `f758c3f` (M3S merge, PR #3), clean, in sync. 768 tests
  (395 core + 197 content + 176 app) green, measured this session after
  the merge. Survivability baseline 24/40 (D24).

## The measurement

- **Session rebuild precedent exists**: `main.dart` (read in full this
  session) rebuilds the whole bloc tree by bumping a generation counter in
  a `ValueKey` (`_startOver, main.dart:57-68) — switching heroes is the
  same gesture with a different document edit. `_openCrawl(run,
  resumed: true)` is the resume door a switched-to suspended hero reuses.
- **Abandon plumbing to retire**: `onAbandonHero` callback, the
  `abandoned` flag + BlocListener (main.dart:128-134), the town button
  and `_confirmAbandon` dialog (town_screen.dart:79-136), `abandonActiveHero` in boot.dart.
- **Merchant stock resurrection defect (surfaced by saves)**: `TownBloc`
  seeds `stock: merchantStock(profile.worldSeed, profile.visit)` at
  construction; nothing persists purchases, so a relaunch restores the
  full stock. Worse: `merchantStock` is deterministic, so re-buying an
  item yields a second item with the SAME id in the pack — id uniqueness
  breaks, and every by-id operation (sell, equip, deposit) acts on the
  first match. Real defect, reachable by play since M3S.
- **Prices**: `buyPriceOf(item) = sellPriceOf(item) * 2` (economy.dart:48)
  — the markup D28's buy-back guards against. Buy-back at `sellPriceOf`
  needs no new economy function.
- `buyItem(profile, item, price)` takes the price as a parameter — the
  buy-back transaction reuses it unchanged. `sellItem` likewise. No core
  or content-economy change needed.
- **Save document**: hero entries are {label, profile, run} — adding
  visit-state fields (bought ids, sold-back item refs) is a codec +
  golden-fixture change inside the still-unshipped v1.
- **Widget-test ground**: the app package has zero widget tests and no
  `testWidgets` conventions; D31 grants them fully. flutter_test ships
  with the SDK — no new dependency.

## Is each inherited gate real?

- "v1 may still be reshaped" — real: no build has shipped (follow-up 20's
  freeze has not triggered). The golden fixture regenerates once more.

## Findings that change the spec

1. The stock fix belongs here, not in a follow-up: the buy-back list has
   the same persistence need (visit state), so both ride one new
   `{bought, sold}` block per hero.
2. Mutation rows 22/24 from M3S (canPop flipped, didPop guard dropped) and
   the attached-autosaver defect become the acceptance proof of D31: each
   gets a widget test, and the old all-green mutations must now redden.
3. Switching to a hero with a suspended run must land in their crawl —
   the boot-resume path already does exactly this for the active hero, so
   switch = document edit + session rebuild, nothing new in the crawl.

## Proposed shape of the work

One unit, branch `m3-heroes, story M3H (M): roster screen behind a town
door (create with name, switch, delete with confirmation, never zero
heroes), abandon-hero plumbing retired, merchant buy-back + persisted
visit state, CLAUDE.md testing-convention amendment (D31), and the
repository's first widget tests covering the wiring bloc tests cannot see.

## Hazards to carry into the spec

- First widget tests in the repo: establish a style (plain `testWidgets,
  pump the real widgets with fake stores; no golden-image tests).
- Deleting a hero deletes their suspended run with them — the confirm
  dialog must say so when one exists.
- The generation-key rebuild tears down the autosaver (`_saver.close()`)
  — switching must not race a pending write (the store's write is awaited
  in `_abandon`'s precedent).
- Suspend-theorem and golden fixtures update once for the visit-state
  fields; keep the change to one commit so the golden diff reads as one
  format step.

## What this recon did NOT check

- Whether `flutter_test` widget pumping needs a `path_provider` stub for
  the store (likely injectable already — SaveStore takes an interface).
- The exact TownBloc event surface needed by the roster (worker derives
  it from the screen).
- Whether the sold-back list should also survive the death reshuffle
  (visit bump clears it — same as stock; assumed correct since the
  merchant "re-stocks" per visit by design).
