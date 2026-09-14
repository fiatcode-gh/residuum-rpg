# Unit 5 — Log Drawer

Status: **specified 2026-09-14** from `recon.md` plus the three contract forks
settled with the user this session. Implementation requires normal local
execution authorization.

## Goal

Make the history reviewable during combat without shrinking the map. A player
who has just been hit by something they did not see can read back through what
happened, tell each line's kind at a glance, and return to the newest entry —
without losing the dungeon, spending a turn, or scrolling a three-line box.

## Authority

- Follows accepted Units 1–2, merged Unit 3, and Unit 4 (PR #13, merge
  user-owned). Unit 4's identity-correct event names are an input: Unit 5 never
  re-labels an actor.
- The visual-reboot ledger plus handoff sections 8.1–8.4 and 9.5 are the
  product authority; the approved mock is the visual authority.
- `GameBloc` and core `GameState`/`step` remain authoritative. The log stays
  app-owned view state.

## Settled forks

1. **Structured entry now.** `GameViewState.log` stops being `List<String>` and
   becomes a list of an app-only presentation entry carrying the sentence and a
   category. Deferring only moves the same migration into a later unit that is
   not about the log.
2. **Unit 5 moves the peek above the controls**, as the mock shows. This
   discharges one item of the otherwise unowned HUD-chrome list.
3. **Death wins.** Game-over collapses the drawer and disables its handle; the
   death overlay keeps the screen and its single working control.

## Product contract

### The entry

- Each entry is a sentence plus exactly one category from a closed set. The
  category is chosen from the `GameEvent` variant where `describeEvent` already
  switches on it, and from the call site for every line the app injects itself
  (`_watchedRefusal`, `_backRefusal`, `_roadBackRefusal`, `roadOpeningLog`,
  `_openingLog`, `_asSentence`). **No line's category is ever inferred by
  matching sentence text.**
- The mapping is exhaustive: every event that produces a sentence resolves to
  one category, and the compiler enforces it. An event that produces no
  sentence produces no entry.
- The set must distinguish, at minimum: harm arriving on the hero, the hero's
  own offense landing, a death, something coming into view, movement or a
  change of depth, and the game refusing an action. Everything else must still
  resolve to exactly one member — no catch-all `other`.
- Category names are taken from vocabulary already in `core`'s event names or
  the design spec. Inventing a synonym for a concept the codebase already names
  is a defect.
- The entry is view state. It is never persisted, never placed in core or
  content, and the save document does not change. A resumed crawl still opens
  with its one explanatory line and a fresh crawl still opens empty.
- The history stays exact: Unit 5 never re-derives, re-sorts, de-duplicates, or
  truncates the list. Refusals stay in the same stream, in causal order.

### The peek

- The peek sits **above** `_Controls` and keeps its fixed compact height —
  about three lines at the phone target. It does not grow with history.
- Newest-last ordering and the existing value-only contrast between the newest
  line (`0xFFE6EAF0`) and older lines (`0xFF8A919E`) are preserved, because
  that contrast already survives greyscale.
- The peek scrolls in place and carries one unmistakable expansion handle.
- It reads naturally on a short history. A road encounter builds a fresh
  `GameBloc` with an empty log; the peek must look deliberate when empty or
  one line long, not like a broken box.

### The drawer

- Expansion is an **overlay** over the dungeon: peek → half (about 40–50% of
  height) → full. It never reflows the column into a permanently smaller map,
  and collapsing restores the previous composition exactly.
- The expanded log draws the per-line category as a glyph in a leading column,
  plus the category as a word in the accessibility label. Shape and word carry
  the category; **hue never carries it alone.** The glyph column must stay
  distinguishable in a greyscale reading.
- The drawer offers both the handle and an explicit close affordance, as the
  mock shows.
- Opening, resizing, closing, and scrolling the drawer cost no turn and mutate
  no gameplay, FOV, RNG, arm, walk, or selection state.

### Follow state

- Auto-follow holds while the reader is at the newest entry: new lines arrive
  and stay visible.
- Scrolling away from the newest entry stops follow. New lines then accumulate
  without yanking the viewport.
- While follow is off and lines have arrived, the drawer offers a `↓ N new`
  affordance that returns to the newest entry and resumes follow. `N` is the
  count accumulated since follow stopped and is shown as a number, not a dot.
- Returning to the newest entry by scrolling also resumes follow and clears the
  count.

### Death

- Entering game-over collapses the drawer to peek and stops the handle
  responding. The `_DeathOverlay` scrim keeps the screen and remains the one
  interactive surface; its control is never unreachable behind drawer chrome.
- Leaving and re-entering a crawl starts with the drawer collapsed and follow
  on.

## Non-goals

- No core, content, save, economy, balance, or generator change.
- No tap-to-actor navigation from a log line (handoff section 8.4 rules it out
  for this unit).
- No severity, timestamp, filtering, search, category toggles, or per-category
  muting.
- No unread badge on the collapsed peek beyond what the peek already shows, and
  no notification surface outside the log.
- No HUD chrome beyond the peek reorder: the depth header, labelled HP/Mana
  bars, and icon control chips stay unowned.
- No asset pipeline. Category glyphs are drawn from the existing text/icon
  vocabulary, not from imported art.
- No timeline, shelf, character, pack, town, or world change.

## Acceptance criteria

1. Every sentence-producing `GameEvent` variant and every app-injected line
   yields exactly one category, chosen from the variant or the call site; no
   code path matches sentence text to decide a category.
2. The peek renders above the controls at a fixed compact height, newest last,
   with the existing newest/older value contrast intact and one visible
   expansion handle.
3. The handle takes the log peek → half → full and back; at half and full the
   dungeon is overlaid, and on collapse the pre-expansion composition is
   byte-for-byte the same widget arrangement as before.
4. In the expanded log each line shows its category glyph and exposes the
   category as a word to accessibility; the column is readable in greyscale and
   no category is distinguished by hue alone.
5. With the reader at the newest entry, an arriving line stays visible. After
   scrolling up, arriving lines do not move the viewport and `↓ N new` reports
   the exact number accumulated; using it returns to newest and resumes follow.
6. Scrolling back to the newest entry resumes follow and clears the count
   without the affordance being used.
7. Opening, resizing, scrolling, and closing the drawer leave `game`, `pan`,
   `autoPath`, `walkId`, `armedSpellId`, `selectedActorId`, and the log itself
   unchanged, and spend no turn.
8. On game-over the drawer is collapsed, the handle is inert, and the death
   overlay's control is reachable and functional.
9. A fresh road encounter's empty log and a one-line log both render without
   layout exception and read as deliberate.
10. `packages/core` and `packages/content` gain no Flutter dependency and no
    log-category concept; no save document changes and no save-version bump.
11. Scoped `dart format`, `flutter analyze`, and the full `flutter test` suite
    pass from `packages/app`.
12. Phone AVD evidence in colour **and** greyscale covers: the peek in its new
    position, peek → half → full → collapse over a live map, the category glyph
    column, follow held at newest, follow broken with `↓ N new` and its return,
    a short/empty log in a road encounter, and the drawer collapsed under the
    death overlay.

## Verification strategy

- Bloc tests: category assignment per event variant and per injected line;
  exhaustiveness of the mapping; history exactness across view-only
  transitions; follow-state transitions and unread count; drawer state cleared
  on game-over; no gameplay field mutated by a drawer interaction.
- Widget tests: peek position relative to the controls; handle drives the three
  states; overlay does not reflow the map; collapse restores composition; empty
  and one-line logs at phone size; death overlay control reachable with the
  drawer present.
- Category-glyph tests: every category maps to a distinct glyph and a distinct
  accessibility word.
- Then scoped format, analyzer, and the full `packages/app` suite, followed by
  one phone AVD colour and greyscale session covering criterion 12.

## Review disposition

- One integrated `flow-acceptance-reviewer` pass after the coherent
  implementation: plan conformance plus independent correctness of the category
  mapping, follow state, overlay composition, and accessibility.
- Device-only evidence goes to a bounded `flow-evidence-verifier`; the
  architect stays the acceptance judge.
- Security review: skip — no external or trust boundary is introduced.

## Risks and traps

- The `List<String>` → entry migration touches 8 test files and 87 references
  in `packages/app/test`. That is mechanical churn, not judgment; it must not
  be allowed to change any asserted sentence.
- Do not leave a `List<String>` compatibility accessor, adapter, or parallel
  category list beside the entry list. Clean cutover.
- Do not let the overlay's animation or sizing shrink the map permanently, and
  do not rebuild the Flame scene on a drawer state change.
- Do not let the unread count drift: it counts lines appended while follow is
  off, not total history length.
- The mock is untracked evidence at
  `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`.
- Device scenes must be probed at `visit: 1`; a first delve bumps `visit`.
