# Recon — m3-magic (M3M): nine skills, spell books, first spells

Date: 2026-08-24, architect session. All figures measured this session unless
marked otherwise. Paths are repo-absolute under
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/`.

## VERDICT

The unit is buildable on today's `main, but it is larger than its D20
one-line scope reads: **nothing of the spell system exists** — no skill
content-entry shape, no damage types, no resource pool of any kind, no ranged
interaction, no consumable concept beyond `heal > 0` — and two of the
costliest sub-decisions (damage-type scope and the cast cost model) are
genuinely open design forks, not implementation details. One save reshape is
unavoidable (a known-spells key plus three new school skills), which
contradicts D53's "campDay was the last sanctioned break" line and needs an
explicit re-sanction from the user.

## State verified before measuring

- `main` = `936ca5b` (M3B merge, PR #10), working tree clean, no worktrees,
  no branches besides `main, nothing in flight.
- Stale local branch `chore/report-layout` found and deleted this session
  (content verified absorbed by squash `bdb190b` before deletion).
- No `m3-magic` spec, prompt, or worktree exists yet.

## The measurement

Suites re-run by this architect on `main` @ `936ca5b`:
**537 core + 418 content + 406 app = 1361 green.** All four band lines
verbatim in my runs:

- `survivability: 20/40 won (50.0%), stalled 0, died at 1:1 2:9 3:4 4:6 5:20`
- `greedy build: 20/40 won; fleetfoot-first build: 14/40 won`
- `sea-cave: 31/40 won (77.5%), stalled 0, died at 2:1 3:7 4:13 5:10 6:9`
- `ruined keep: 28/40 won (70.0%), stalled 0, died at 1:4 2:6 3:1 4:1 5:13 6:9 7:6`

Code facts below were gathered by four read-only agents (skills seam, combat
seam, items seam, state/save/UI seam) and the sharpest claims re-read by this
architect at source: `step.dart:393-416` (`_defend`), `step.dart:260-290`
(`_moveHero`), `economy.dart:32-40` (`sellPriceOf`), `item_codec.dart:70-84`
(skills codec), `survivability_test.dart:179-207` (bot policy), `energy.dart:4-7` (single action cost), `item.dart:61` + `drop.dart:87`
(potion predicate and Common-forcing).

## Is each inherited gate real?

1. **D20: "remaining 9 skills, spell books, first spells" — real but
   understated.** Skills have no content-entry shape at all: the design
   spec's "each a content entry: name, training trigger, per-level bonus,
   milestone perks" does not exist. The four shipped skills are a bare enum
   (`packages/core/lib/src/skills/skill.dart:8`) whose name lives in an app
   switch (`event_messages.dart:61-66`), trigger inline in
   `step.dart:272/401, bonus inline in `loadout.dart:83/96/106`. Also: of
   the nine unbuilt skills, **only the three spell schools (Wrath, Mending,
   Binding) can train inside this unit's scope** — Marksmanship needs ranged
   weapons, Shieldcraft needs blocking, Shadowing needs stealth, Larceny
   needs locks/traps, Herbcraft and Blacksmith belong to m3-craft. "Nine
   skills" is really "three live skills plus a decision about six dead enum
   cases".
2. **D50: "spells + damage types/resistances answer brainless combat" —
   real, and the full section-5 promise is its own unit.** Typing every
   weapon and giving every creature a seven-type resistance table touches
   `Actor, `CreatureSpec, every affix, both copies of the damage formula,
   the `AttackHit` event, the goldens, and all four bands. A middle scope —
   types on **spells only**, one resistance field on creatures, melee stays
   untyped this ring — buys the strategic choice (spell vs steel per enemy)
   at a fraction of the blast radius.
3. **D20: "the save shape must exist before Profile grows spells" — done.**
   M3S shipped; `encodeProfile`/`encodeRun` are the exact touch points.
   No new `SavedHero` key is needed (known spells mirror `skills` in the
   profile and run blocks) — smaller reshape than M3B's campDay.
4. **D53: "campDay was the last sanctioned break before v1 freezes" —
   cannot hold.** A known-spells key is a new required key under the
   never-repair rule, and adding school skills changes every encoded skills
   block. Every pre-M3M save will be refused. Still sanctioned pre-ship
   (follow-up 20), but the user must re-sanction it knowingly — their
   current playtest hero dies at this merge too.

## Findings that change the spec

1. **No resource pool exists besides HP.** `Actor.energy` is the turn clock
   (`energy.dart:4-7`), reset to full at every stairwell (`step.dart:513`)
   and run start — it cannot carry a cost across turns. A real mana pool on
   `Actor` reaches the monster codec, three golden strings, the HUD, the
   town/roster health lines, and the bot. A cost model carried on
   `GameState`/`Profile` only (cooldowns, charges, or a hero-only mana int
   beside `gold`) skips `Actor` and the monster codec entirely — materially
   cheaper. The design spec never says "mana"; the cost model is genuinely
   open.
2. **Every action costs the same 100 energy** (`step.dart:62`); there is no
   per-action cost seam. The spec's "each action costs time" is
   aspirational. A cast that costs more or less than a swing needs a new
   cost function — optional scope.
3. **The survivability bot is melee-only and cannot see spells**
   (`survivability_test.dart:179-207`: `MoveAction` is its only offensive
   verb; `_bestUpgrade` only understands weapon/armour). A cast branch in
   `_decide` re-pins every figure by design. Sharper: **any extra draw from
   `state.rng` re-rolls the entire combat stream for every seed** — all
   forty runs of all four bands move even if the arithmetic is identical
   (`step.dart:373-380` states the discipline; the dodge gate is skipped at
   0 for exactly this reason).
4. **"Consumable" is not a concept.** `isPotion => heal > 0`
   (`item.dart:61`). A spell book satisfies no kind predicate and falls
   through everything: `_sectionOf` files it under Potions
   (`item_presentation.dart:134-138`), `rollDrop`'s Common-forcing skips it
   (`drop.dart:85-97` — affix-bearing books would lie about table rarity),
   and **`sellPriceOf` worths it at 1 gold** (`economy.dart:32-40`: worth =
   attack + armor×2 + heal, all zero for a book, clamped to 1; buy = 2).
   The book needs its own predicate, section, Common-forcing, and a price
   term — or an explicit exclusion from the shop. This is the sharpest
   single gap found.
5. **No per-creature drop hook exists.** Kill drops come off the depth's
   table gated by `dropChance` (`step.dart:291-307`). "Book X drops only in
   dungeon Y" fits the existing idiom: a weighted entry in that dungeon's
   own `dropTables` with weight 0 everywhere else, enforced by a validation
   test exactly as Legendary-never-drops is enforced today. A *guaranteed*
   book (second bottom-floor placement beside the trophy) moves floor
   goldens (`itemCount + 2`) — costlier, optional.
6. **Old saves load with missing skills reading as level 0** —
   `decodeSkills` builds only from the document's entries
   (`item_codec.dart:78-84`), and `levelOf`/`_train`/UI all default absent
   to zero. That quiet degradation is the exact shape the never-repair
   doctrine forbids, so the spec must choose: bump `saveVersion` to 2, or
   make the decoder require every `SkillId.values` entry (both refuse
   pre-M3M saves; the second keeps the version number honest about shape,
   the first is the cleaner statement). Either way the three goldens are
   rewritten by hand in the same commit (campDay precedent, D53). Enum
   order note: **appending the new cases after `fleetfoot`** keeps the
   golden JSON key order stable; inserting in the design spec's table order
   reorders every skills block.
7. **Road danger scales with the sum of all skill levels**
   (`world.dart:320-327`: `trained ~/ roadTierLevels, constant 8,
   calibrated against four trainable skills, capped at 20). Three or more
   new trainable skills accelerate road scaling as a silent side effect —
   the constant needs a ruling and the four pinning tests
   (`world_test.dart:386-460`) re-pin.
8. **No ranged interaction exists.** Tap = orthogonally-adjacent bump only
   (`game_bloc.dart:295-326`; `directionTo` returns null beyond adjacency);
   non-adjacent taps auto-walk. `GameViewState` is rebuilt fresh by every
   handler as a documented safety property, so a tap-to-target mode field
   must be explicitly carried by each handler — real cost. The cheap
   alternative: rule-chosen target (nearest visible monster, deterministic
   tie-break) using the existing `game.visible` / `enemiesInSight`
   primitives; `computeFov` (radius 8) is the only line-of-sight function.
9. **The control row is full.** Five controls already compete on a
   bottom-floor stairs tile and a sixth will not fit on a phone
   (`game_screen.dart:181-192, the ellipsis lesson is written down twice).
   The established escape is the Pack pattern: a pushed route sharing the
   bloc (`game_screen.dart:253-265`). A Spells screen modelled on
   `InventoryScreen, plus optionally a `QuickCast` shortcut mirroring
   `QuickDrinkPressed, is the shape that fits.
10. **`AttackHit` carries a bare `int damage`** (`event.dart:51-67`) and
    the log hardcodes "claws you" for every monster attack
    (`event_messages.dart:20-21`). Typed damage or a resist beat needs a
    field on the event plus new message arms; the sealed switches make the
    compiler enumerate every site.
11. **`designed_difficulty_test.dart` re-implements the damage formula**
    (`_bestBlow` at :72-75, floor deliberately omitted) and pins the
    exempt-nuisance set `{rat, wolf, ghoul, crab}` at :115. Any formula
    change updates this second copy in the same commit or the pin lies.
12. **Accessibility shape is settled by precedent.** A spell school needs a
    core value object carrying a marking glyph plus a word (the `Rarity`
    pattern, `rarity.dart:7-32`); a locked book row needs a reason sentence
    (`ItemRow.reason, `town_style.dart:88-98` — "needs Wrath 25"); school
    sections render in fixed order even when empty (`packSections`
    precedent); the palette test asserts value separation. The content
    validation clause is pre-written in CLAUDE.md: "every spell's school is
    a real skill".
13. **UI details that will bite:** the skill list is data-driven off the
    enum (new rows appear free) but the name column is fixed at 88px and
    "Marksmanship" (12 chars) overflows it; 13 ungrouped rows want
    sectioning. `gear_screen.dart:30-34` builds from weapons + armour only,
    so books are invisible in town until it grows a section — and the
    design ("rare books found early become goals") implies reading in town
    or at camp is the common case, which wants a `readRefusal` shared rule
    in the `wearRefusal` style (`wear.dart:7-22` precedent) wrapped by both
    `step` and a town transaction.
14. **A new base item costs the item codec nothing** — books serialize as
    registry refs under the existing four keys (`item_codec.dart:8-48`).
    The reshape cost is entirely the known-spells key and the skills block.

## Proposed shape of the work

One unit, `m3-magic` (M3M), effort **L**, scoped by four user forks (below).
Recommended resolution, in one sentence each:

- **Types ride the spells only:** spells carry a damage type; creatures gain
  one resistance mapping (content field, defaulted empty); melee stays
  untyped this ring; the full section-5 weapon typing becomes a follow-up
  for M4/M5. This answers "brainless" (spell-vs-steel is now a per-enemy
  choice) without re-typing the whole armory.
- **Cost model: hero-only mana** carried beside `gold` on
  `GameState`/`Profile` (never on `Actor` — monsters do not cast), max
  derived from school skill levels, restored at the inn and by camp/stairs
  policy TBD in spec — OR cooldowns if the user prefers zero new pools.
  This is the user's call; both fit the seams found.
- **Targeting: rule-chosen** (nearest visible enemy, deterministic
  tie-break) this unit; tap-to-target deferred until it provably feels bad.
- **Skills: add the three schools now**, the other six enum cases only if
  the user wants the spec-letter "all 13 skills" — six untrainable rows are
  dead weight in the UI and in every skills block of every save.
- **First spells: six, two per school** (Wrath: a melee-range burn + a
  ranged bolt; Mending: heal + a ward; Binding: a root + a weaken), each a
  content entry with school, required level, damage type, cost; spell books
  as base items, one book per spell, distributed across the three dungeons'
  drop tables (weight 0 elsewhere), merchant shelf carrying the two
  cheapest.
- Bot gains a cast branch; every band figure re-pins by design (M3R/M3B
  precedent); save reshape sanctioned once, goldens by hand.

If the user instead picks the full weapon-typing scope, split into two
sequential units (M3M magic, then M3E elements) — one build branch cannot
carry both re-pin storms.

## Hazards to carry into the spec

- **RNG stream discipline** (finding 3): a cast must draw from `state.rng`
  in a fixed, documented order; any conditional draw is a determinism trap.
  The suspend theorem (resume roll-for-roll) must survive casting.
- **Band re-pin window**: all four exact figures, both build lines, the
  histogram maps, and the 0.45–0.80 soft bands re-pin; the
  designed-difficulty pin's armor is derived from the fixture kit — a kit
  change reddens it by design. The tiered lever rule stands (content tables
  free with a trail; bestiary/hero stats need a ruling) — spells are NEW
  content, but any creature resistance entry is a bestiary edit and needs
  its trail.
- **Road-danger recalibration** (finding 7) rides the same re-pin window.
- **Goldens by hand, old value quoted in the same commit** (house rule);
  enum append order (finding 6).
- **Two copies of the damage formula** (finding 11).
- **Device pass is mandatory** (six device-only catches to date): the
  Spells screen, the locked-book reason rows, greyscale shots, and the
  save-slot copy-aside trap (SHA256-verify the restore) all apply.
- **Merchant economy**: a book must not price at 1 gold (finding 4); the
  economy test pins shelf composition (`economy_test.dart:165-178` counts
  non-potion gear 1–3 — a shelf book breaks that count's meaning).
- The M2Q viewport playtest (follow-up 13) and bottom-floor instrument gap
  (follow-up 28) still stand; nothing here closes them.

## What this recon did NOT check

- Any app widget internals beyond the files quoted; no widget test was run
  in isolation; no AVD/device state was touched.
- Whether any concrete spell numbers hit the 0.45–0.80 bands — no tuning
  was attempted; the spec's targets will need the build's measured trail.
- The M4 perk system's interaction with school skills (perks stay out of
  scope; nothing was verified about them).
- The exact set of first spells against play-feel — the list above is an
  architect proposal, not a measured claim.
- Content of the user's in-progress playtest (verdicts pending); nothing
  here pre-empts a balance follow-up from it.
- Whether `flutter analyze` / `dart format` are clean on main (assumed from
  D54's post-merge verification; will be re-run at spec handoff).
