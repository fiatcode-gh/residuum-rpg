# Story spec — M3M `m3-magic`: three schools, spell books, six first spells

Decisions: D20 (unit split), D50 (spells answer "brainless combat"), D55
(forks locked). Recon: `m3-magic-recon.md` (same directory). Base:
`main` @ `936ca5b, 1361 tests green, four band lines verbatim (quoted in
the recon).

## Goal

The hero can learn spells from consumable spell books and cast them in the
crawl. Casting spends a hero-only mana pool, trains the three new school
skills (Wrath, Mending, Binding), and deals TYPED damage that creature
resistances and vulnerabilities modify — so which enemy you burn, freeze,
bind, or simply hit becomes a decision. Melee stays exactly as it is: **all
four survivability band lines must return byte-identical** — they are this
unit's controls, not its re-pins. The save format bumps to version 2 (the
sanctioned break, D55); every pre-M3M save is refused.

## Shape — precedents to follow, read from this codebase

- **Injected content registry:** `GameState.dropTables` — content data
  carried by identity in state, injected at `startRun`
  (`run_boundary.dart:55/86`), never exposed in `copyWith`. The spell
  registry rides the same way.
- **Learned capability that survives death:** `skills` — on `Profile` AND
  `GameState, copied at the four run-boundary doors (`startRun:84, `endRun:110, `suspendRun:149, `resumeRun:209`), in `Profile.props`.
  `knownSpells` mirrors it exactly.
- **Consumable with an action:** the healing potion — `DrinkAction`
  (`action.dart:59-69`), refusal in `_refuse` (`step.dart:205-212`), effect
  + filter-by-id removal (`step.dart:113-122`), `PotionDrunk` event,
  message arm. `ReadAction` is its sibling, including the doctrine that
  a wasteful use is NOT refused (drinking at full health wastes the turn).
- **Shared refusal rule between dungeon and town:** `wearRefusal`
  (`loot/wear.dart:7-22`) — one plain-string rule, wrapped by `step` as
  `ActionRefused` and by town as `TownRefusal`. `readRefusal` is written
  the same way.
- **Category encoded without hue:** `Rarity` (`rarity.dart:7-32`) — a
  marking glyph plus a word. The spell school value carries both.
- **Disabled control that says why:** `ItemRow.reason`
  (`town_style.dart:88-98`) — "needs Wrath 15" is a sentence, never a
  greyed color.
- **New save field, done deliberately:** the campDay reshape (D53) —
  strict decoder that refuses absence, goldens rewritten BY HAND in the
  same commit with old values quoted.

## New files

- `packages/core/lib/src/magic/spell.dart` — `Spell, `SpellKind, `DamageType, `School` marking/word helper.
- `packages/core/lib/src/magic/read.dart` — `readRefusal`.
- `packages/content/lib/src/spells.dart` — the six spells + `spellsById`.
- `packages/content/lib/src/spell_books.dart` — six book `BaseItem`s (or
  ride `armory.dart` if the worker prefers; pre-declare either way).
- `packages/core/test/magic/spell_test.dart, `packages/core/test/engine/step_cast_test.dart, `packages/core/test/engine/step_read_test.dart, `packages/content/test/spells_test.dart` (content validation additions
  may live in `content_validation_test.dart` instead),
  app tests per surface touched.

## Changed files (exact; anything else needs a pre-declared deviation)

- `packages/core/lib/src/skills/skill.dart` — three enum cases APPENDED
  after `fleetfoot`; `untrainedSkills` grows to 7.
- `packages/core/lib/src/engine/actor.dart` — `resists` and
  `vulnerableTo` (`Set<DamageType>, default empty), `copyWith` untouched
  (the sets never change mid-run), `toString` extended.
- `packages/core/lib/src/engine/action.dart` — `ReadAction(itemId), `CastSpellAction(spellId)`.
- `packages/core/lib/src/engine/step.dart` — the two switch arms each in
  the dispatch and `_refuse`; ward absorb in `_defend`; bound-skip in the
  monster phase; mana refill in `_arriveOn` (beside the energy reset, `step.dart:513`).
- `packages/core/lib/src/engine/game_state.dart` — `mana, `warded, `bound` (`Map<String, int>`), `knownSpells` (`Set<String>`), `spells`
  registry (identity-carried like `dropTables`); `copyWith` exposes
  `mana`/`warded`/`bound`/`knownSpells` only.
- `packages/core/lib/src/engine/event.dart` — `SpellLearned, `SpellHit, `MendCast, `WardRaised, `WardStruck, `MonsterBound, `MonsterBanished` (worker may consolidate; pre-declare).
- `packages/core/lib/src/loot/item.dart` — `BaseItem.teaches: String?, `isSpellBook, `isConsumable => isPotion || isSpellBook`.
- `packages/core/lib/src/loot/drop.dart:87` — Common-forcing switches
  from `isPotion` to `isConsumable`.
- `packages/core/lib/src/loot/loadout.dart` — `heroMaxMana(loadout)`.
- `packages/core/lib/src/town/town.dart` — `readBook` transaction;
  `restAtInn` (`:77`) refusal learns that empty mana is also "something
  wrong with you" (rest restores mana too — but mana is run state, see
  contract 4; the inn clause applies only if the worker finds a
  profile-side mana need; otherwise pre-declare and leave `restAtInn`
  untouched).
- `packages/core/lib/src/town/run_boundary.dart` — `knownSpells` through
  all four doors; `mana` starts full at `startRun`/`resumeRun` per
  contract 4; `spells` registry injected.
- `packages/core/lib/src/town/profile.dart` — `knownSpells` + `props`.
- `packages/content/lib/src/bestiary.dart, `sea_cave.dart, `ruined_keep.dart` — resistance/vulnerability entries (content tables,
  free with a trail per the tiered rule; creature hp/attack/pierce are
  NOT open).
- `packages/content/lib/src/drop_tables.dart, `sea_cave.dart, `ruined_keep.dart, `economy.dart` — book weights per contract 7; the
  book price term in `sellPriceOf`.
- `packages/content/lib/src/new_game.dart` — fresh hero knows no spells,
  mana per `heroMaxMana`.
- Save: `packages/content/lib/src/save/save_codec.dart`
  (`saveVersion = 2`), `profile_codec.dart` (`knownSpells`), `run_codec.dart` (`mana, `warded, `bound, `knownSpells`), `actor_codec.dart` (`resists, `vulnerableTo`), `item_codec.dart`
  (books ride the existing item shape free; `encodeSkills` grows by
  enum).
- App: `game/game_bloc.dart` (`ReadPressed, `CastPressed, view-state
  `mana`/`maxMana`/`knownSpells`/reasons), `game/inventory_screen.dart`
  (Spells section + Read button + Books pack section), `game/item_presentation.dart` (`PackSection.books, `_sectionOf` loses
  its fall-through), `game/event_messages.dart` (new arms), `game/game_screen.dart` (mana readout in the status area — word plus
  numbers, no sixth control), `town/gear_screen.dart` or a Books section
  (town reading), `town/town_bloc.dart` (`ReadBookPressed`).
- Tests as listed; three golden save strings rewritten by hand.

## Per-item contract

1. **Skills.** `SkillId` gains `wrath, `mending, `binding` — appended
   after `fleetfoot` (golden key order stays stable — D55). Each trains
   ONLY via `_train` on a successful cast of its school (one xp, same as
   a landed swing). No other trigger. The six remaining design-spec
   skills do NOT enter the enum (D55).
2. **`Spell`** (core value object, self-validating): `id, `name, `school` (must be one of the three school `SkillId`s — assert), `manaCost > 0, `requiredLevel >= 0, `kind`
   (`bolt | mend | ward | bind | banish`), `type` (`DamageType?` — required
   for `bolt, null otherwise), `min <= max` (damage for bolt, heal for
   mend, absorb for ward as `min == max, unused for bind/banish).
   `DamageType` ships with exactly `fire` and `frost` (YAGNI — the other
   five arrive with weapon typing, M4/M5).
3. **The six spells** (content; numbers are the worker's to tune WITH A
   TRAIL, gates and shapes are fixed):
   | id | school | kind | type | gate | cost | effect |
   |---|---|---|---|---|---|---|
   | firebolt | Wrath | bolt | fire | 0 | 2 | 2–4 to nearest visible |
   | frost-lance | Wrath | bolt | frost | 15 | 4 | 4–7 to nearest visible |
   | mend | Mending | mend | — | 0 | 3 | heal 8, capped at missing |
   | ward | Mending | ward | — | 10 | 3 | absorb pool 6, replaces |
   | bind | Binding | bind | — | 0 | 3 | nearest visible skips 3 turns |
   | banish | Binding | banish | — | 15 | 4 | nearest visible relocated |
4. **Mana is run state only.** An `int` on `GameState` (never on `Actor,
   never on `Profile` — it starts full at `startRun` and `resumeRun`
   restores whatever `suspendRun` wrote, roll-for-roll). Max is
   `heroMaxMana(loadout) = 4 + (wrath + mending + binding levels) ~/ 2`
   (constants tunable with a trail). Refills to max in `_arriveOn`
   beside the energy reset — mana is a per-floor budget. HUD shows
   `Mana n/m` as words and numbers.
5. **`ReadAction(itemId)`** — refusals via shared `readRefusal`: not a
   book ("X is not something to read" — mirror the drink wording), spell
   already known ("you already know Y"), school level below the gate
   ("needs Wrath 15"). Missing item refusal matches Drink's. Reading a
   book you COULD save for later is not refused (Drink doctrine). Effect:
   spell id into `knownSpells, book removed by the filter-by-id idiom, `SpellLearned` emitted, the turn passes (falls through to the monster
   phase). Town twin: `readBook(profile, itemId)` wraps the same rule in
   `TownRefusal`; learning in town costs nothing but gold never enters
   it.
6. **`CastSpellAction(spellId)`** — refusals, in order: unknown spell, `mana < cost` ("not enough mana"), and for bolt/bind/banish no
   visible enemy ("no enemy in sight"). Mend at full health is NOT
   refused (wastes turn and mana — Drink doctrine, dartdoc it). Effects:
   - **Targeting rule (all targeted kinds):** the visible enemy with the
     smallest Chebyshev distance; ties broken by `byRowThenColumn` on
     position. Deterministic, no draw.
   - **bolt:** one `state.rng.rollRange(min, max)` draw; if the target
     `resists` the type, damage is halved rounding down, floor 1; if
     `vulnerableTo, doubled (resist and vulnerable are mutually
     exclusive by content validation). `SpellHit` emitted; kill flows
     through the existing death path INCLUDING `_spoilsOf` (drops draw
     from `lootRng` exactly as melee kills do).
   - **mend:** heal capped at missing hp, no draw, `MendCast(healed)`.
   - **ward:** `warded` set to the pool value (replaces, never stacks),
     no draw, `WardRaised`.
   - **bind:** `bound[targetId] = 3, no draw, `MonsterBound`.
   - **banish:** target moves to a walkable, unoccupied, non-hero tile
     chosen by ONE `state.rng` draw — an index into the candidate list
     sorted `byRowThenColumn` (documented draw order), `MonsterBanished`.
   - Every successful cast: mana decremented, school trained via
     `_train, turn passes.
7. **Ward in `_defend`:** after the existing floor-of-one damage is
   computed, `absorbed = min(warded, damage)`; hp loses
   `damage - absorbed`; `warded` shrinks by `absorbed`; `WardStruck`
   emitted when `absorbed > 0`; `AttackHit` emitted only when hp actually
   drops. Defence still trains on the blow either way. **No new RNG draw
   on this path** (the dodge gate stays exactly as written).
8. **Bound monsters** skip their scheduled actions; each skipped
   scheduled turn decrements the counter; at 0 the entry is removed.
   Bound monsters still take damage and die normally; `bound` entries for
   dead or banished-then-killed monsters must not leak (filter on death).
9. **Spell books:** `BaseItem.teaches` names a spell id;
   `isSpellBook => teaches != null`; glyph `?` (subject to the glyph
   collision test — if it reds, pick the next free glyph and pre-declare).
   Books force Common in `rollDrop` via `isConsumable` — the potion's
   reasoning applies verbatim (an affixed book lies about table rarity).
   Distribution (weights tunable with a trail, EXCLUSIVITY is the
   contract): crypt drops `bind` and `firebolt` books; sea-cave drops
   `mend` and `frost-lance`; ruined keep drops `ward` and `banish`;
   weight 0 in every other table including `roadDropTable` and the
   trophy tables; the merchant's `marketTable` carries the two ungated
   starter books (`firebolt, `mend`) at low weight. Validation tests
   enforce all of it (pattern: `content_validation_test.dart:433-449`).
10. **Economy:** `sellPriceOf` gains a book term — a book is worth
    `10 + requiredLevel` before the rarity multiplier (content can look
    the spell up by `teaches`; numbers tunable with a trail). The
    `economy_test.dart:165-178` shelf-count pin must be extended
    knowingly, not silently loosened.
11. **Save version 2.** `saveVersion = 2`; version 1 documents are
    refused by the existing version gate ("a new hero begins" fallback
    chain — device-prove it). New required keys, never defaulted
    (never-repair): profile block `knownSpells` (sorted list); run block
    `mana, `warded, `bound` (sorted by monster id), `knownSpells`;
    actor blocks `resists, `vulnerableTo` (sorted name lists, present
    even when empty). `encodeSkills` grows to 7 entries by the enum.
    Three goldens rewritten by hand, old strings quoted in the same
    commit (campDay precedent). **Follow-up 20 restated: this is the
    LAST sanctioned break before v1... now v2... freezes at the first
    shipped build.**
12. **App surfaces:** Spells section at the TOP of the pack screen
    (known spells with school word + marking, mana cost, Cast button,
    reason sentence when disabled: "not enough mana", "no enemy in
    sight"); Books rows get Read with a reason when locked ("needs
    Wrath 15"); `PackSection.books` renders in the fixed section order;
    NO sixth control in the HUD row — the mana readout joins the status
    area as `Mana n/m`. Town: books visible and readable (reason
    sentences identical to the dungeon's). Every new surface reads in
    greyscale; school markings are glyph + word, never hue (`Rarity`
    pattern). Log lines: "You read the Book of Firebolt." /
    "Your firebolt burns the ghoul for 5." (bolt verb by type: burns /
    freezes) / "The ghoul is bound." / "The ghoul vanishes and reappears
    elsewhere." / "Your ward takes 3." — exact wording is the worker's,
    the INFORMATION each line carries is the contract.
13. **Resistances (content):** each themed dungeon gets at least one
    resistant and one vulnerable creature against the types its local
    books teach... the INTERESTING direction is cross-dungeon (the
    sea-cave teaches frost; sea creatures resist frost and burn well —
    fire from the crypt's book is the answer). Concretely, as a starting
    trail: ghoul + wight vulnerable to fire; drowned creatures resist
    frost, vulnerable to fire; keep's armored men resist fire, vulnerable
    to frost. Bestiary resistance fields are content-table edits (free
    with a trail); no creature's hp/attack/pierce/speed/dropChance may
    move (tiered rule, D55).

## Behaviour arguments that must land in documentation

- Why mana lives on `GameState` and not `Actor` or `Profile` (monsters do
  not cast; a per-floor budget that starts full makes town-side mana
  meaningless — and the monster codec stays out of it).
- Why the bands are CONTROLS here: the bot never casts, so identical
  lines prove the melee game and its RNG stream are untouched. A moved
  line is a defect, never a re-baseline (D55).
- Why reading or casting wastefully is not refused (the Drink doctrine,
  cited).
- Why ward absorb adds no RNG draw and sits after the floor-of-one.
- Why book rarity is forced Common (the potion's argument, extended).
- Why the six dead skills are NOT in the enum (D55 — honest UI, lean
  saves).
- The auto-target rule and its tie-break, stated where the cast lands.

## Test plan

**Characterization first (all must pass against UNMODIFIED code):** the
existing 1361 tests, the four band lines, and the three goldens ARE the
characterization layer. Before any change, the worker re-runs all suites
and quotes the four band lines from its own run as the baseline block of
the report. One new characterization test to write before the codec
changes: a version-1 document (lift the current golden) is REFUSED by the
version-2 gate with the version sentence — write it red against the new
gate, but the fixture itself must be today's golden, captured before the
goldens are rewritten. (Sequencing trap: capture the v1 fixture string
FIRST.)

**Unit tests (red → green per behavior):** every refusal sentence of
`ReadAction`/`CastSpellAction`/`readBook`; each spell kind's effect;
resistance halving with the floor; vulnerability doubling; mutual
exclusivity validation; targeting nearest + tie-break; ward absorb
ordering and depletion; bound skip/decrement/cleanup-on-death; banish
candidate rule; mana spend/refill-at-stairs/starts-full; school training
per cast; `heroMaxMana` derivation; `knownSpells` through all four
run-boundary doors and death (survives like skills); codec round-trips for
every new key; the suspend theorem extended: suspend mid-run with
mana spent, a ward up, and a monster bound — resume must be
roll-for-roll identical.

**Content validation:** every spell's school is a real school skill (the
CLAUDE.md clause, pre-written); every book's `teaches` names a real spell;
every spell has exactly one book; book exclusivity per dungeon (weight 0
in the others, in `roadDropTable, and in trophy tables); resist and
vulnerable sets disjoint per creature; glyph set assertion grows to
`{')', '[', '!', '?'}`; the "every base item draws as..." test learns
books.

**Mutation table (run each on committed code from the worktree root, pwd
quoted, reds reported as NAMED SETS, revert clean):**

| # | Mutation | Expected |
|---|---|---|
| 1 | `firebolt` min/max +2 in `spells.dart` | REDS the spell content pin and the bolt damage test |
| 2 | resistance halving branch deleted in the bolt path | REDS the resist test |
| 3 | vulnerability doubling deleted | REDS the vulnerability test |
| 4 | mana decrement deleted (casting is free) | REDS the mana-spend test |
| 5 | `requiredLevel` clause deleted from `readRefusal` | REDS the locked-book refusals, dungeon AND town (both halves reported) |
| 6 | `_train` call on cast deleted | REDS the school-training test |
| 7 | ward absorb deleted from `_defend` | REDS the ward tests |
| 8 | bound decrement deleted | REDS the bind-expiry test |
| 9 | targeting takes the FARTHEST visible enemy | REDS the targeting + tie-break tests |
| 10 | `knownSpells` dropped from `encodeProfile` | REDS the profile round-trip and the town golden |
| 11 | Common-forcing reverted to `isPotion` | REDS the book-rarity validation |
| 12 | book term deleted from `sellPriceOf` | REDS the book-price test |
| C1 | — (no mutation) all four band lines re-run on the final commit | GREEN AND BYTE-IDENTICAL to the baseline block — the unit's central control |
| C2 | — designed-difficulty pin re-run | GREEN (melee formula untouched; `_bestBlow`'s copy not edited) |
| C3 | — crypt floor characterization goldens | GREEN (generator untouched) |
| C4 | mutation 4 re-run against the CONTENT suite only | GREEN there (the bands never cast) — the two halves of row 4 show the bands do not cover spells |

Sequencing traps: rows 1–12 mutate NEW code — they run only after the
behavior ships, on committed code. The v1-refusal fixture must be captured
before the goldens change (above). Prefer constant shifts that cannot
coincide with fixture values (D47 doctrine — e.g. +2 on firebolt cannot
coincide because the pin is exact).

## Hazards

- **The RNG stream is the whole game's spine.** No new draw on any
  non-casting path; the dodge gate's zero-skip stays; bolt = exactly one
  draw; banish = exactly one; mend/ward/bind = zero. The band-identity
  control (C1) is the detector — treat any moved line as YOUR defect and
  stop.
- Two copies of the melee damage formula exist
  (`designed_difficulty_test.dart:72-75`) — this unit must NOT touch
  either.
- Goldens by hand, old value quoted in the same commit; skills enum
  APPENDED, never reordered.
- The `_sectionOf` fall-through files unknown kinds under Potions — fix
  it WITH the books section or every book renders as a drink.
- `gear_screen.dart:30-34` hides non-wearables — town books need their
  own section or they are invisible.
- Analyze from the WORKTREE ROOT with pwd quoted; mutation reds as named
  sets (follow-up 27).
- Device pass is MANDATORY (six device-only catches to date): shots of
  the Spells section, a locked book's reason row, the mana readout, a
  cast beat in the log, greyscale copies; copy BOTH device save slots
  aside before pushing any acceptance save and SHA256-verify the restore
  (the M3X trap); pin every adb/flutter command to `emulator-5554`.
- The five-control row is full — do not add a HUD control; label
  ellipsization on device is a known killer (D53's "Finish").
- `flutter test` from each package dir; content suite prints the band
  lines — quote them verbatim, never summarize.

## Follow-ups to log (not this unit)

- A spell-casting bot variant band (informational line first), so magic
  balance gets an instrument; until then spell feel is human-judged only
  (extends follow-up 28's spirit).
- Weapon typing and the remaining five damage types (M4/M5, D55).
- The six remaining skills arrive with their mechanics (m3-craft, M4+).
- Quick-cast HUD affordance if two-taps-to-cast feels slow in play.
- Skill list UI: 7 rows render fine, but the 88px name column dies on
  "Marksmanship" the day it arrives — note for that unit.

## Definition of done

- All three suites green from their package dirs; total strictly above
  1361; declaration-count cross-check consistent with the report.
- **All four band lines byte-identical to the baseline block, quoted from
  the worker's own final-commit run** (histograms included, fleetfoot
  included).
- `dart analyze .` clean from the worktree root (pwd quoted);
  `dart format --set-exit-if-changed .` clean.
- Mutation table: rows 1–12 red as named sets with clean reverts; C1–C4
  green; row-4 both halves reported.
- Three goldens rewritten by hand; the old golden strings quoted in the
  commit message or report; v1-refusal test green with the pre-change
  fixture.
- Suspend theorem extended and green (mana/ward/bound roll-for-roll).
- AVD pass done with the shots listed, greyscale copies included; both
  device save slots copied aside and SHA256-verified restored; v1 save
  refusal proven ON DEVICE ("a new hero begins").
- No commit touches `docs/epic/`; report mirrored to
  `docs/reports/BUILD-REPORT.md`; plan in `docs/plans/`; commits
  `; conventional commits; PR NOT opened
  (the architect does that on user approval).
