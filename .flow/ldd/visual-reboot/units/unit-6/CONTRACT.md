# Unit 6 — Character, Spells, and Pack Contract

Status: **approved product contract; planning and implementation are separate
authorization steps.**

## Outcome

Replace the duplicated long management pages with a phone-first information
architecture:

- **Character** is a concise town hero overview and route hub.
- **Gear**, **Spells**, and **Skills** are focused views reached from Character.
- **Pack** is carried-object management, reached from Character in town and the
  existing crawl shelf in a run.

The unit changes presentation and navigation only. Existing core-owned item,
spell, equipment, skill, material, save, and transaction semantics remain
unchanged.

## Locked product decisions

### Character is an overview with routes

The existing town `Character` door opens a short overview, not a tabbed
management dashboard and not a long scroll. It shows only source-backed hero
facts useful at a glance:

- current health and the existing town/run-derived combat facts;
- concise progression facts backed by known spells and skills; and
- explicit routes to **Gear**, **Spells**, **Skills**, and **Pack**.

The overview does not invent a player name, portrait, character level,
Strength/Dexterity/Will/Lore attributes, quest progress, favorites, or any
other mock-only concept. The current `Profile` has no authority for them.

### Focused detail routes

- **Gear** shows the six existing equipment slots in their established order
  and preserves town `Take off` behavior for a worn item.
- **Spells** is a dedicated, read-only known-spell grimoire. Every row retains
  the existing school marking plus school word, name, mana cost, and supported
  effect information. It never offers `Cast` in town or crawl.
- **Skills** shows every existing skill and its current progression data. It
  does not introduce a derived character-level system or perk selection.
- **Pack** shows carried objects and materials only. It does not repeat
  derived combat stats, worn gear, learned spells, or the skill list.

A town Pack preserves its existing carried-item actions: wear eligible gear,
read eligible books, and surface the existing refusal where an action is
unavailable. A crawl Pack preserves its existing context-valid actions:
drink, read, wear, and drop exactly one represented item. Neither route
invents a town drink action, a bank action, or any other new transaction.

### Spell access stays exhaustive without duplicate UI

The Unit 3 combat shelf and its `+N` overflow remain the sole crawl spell-cast
entry. They already expose every known spell; removing the Pack's duplicate
learned-spell section therefore does not hide or restrict a spell. This unit
must not add favorites, persistence, a prepared kit, or a second casting path.

### Pack category filter

Pack has a local, transient filter for exactly these source-backed choices:
**All**, **Weapons**, **Armour**, **Potions**, **Books**, and **Materials**.

- `All` is the default and presents every carried object/material in the
  existing source-defined ordering.
- The four item filters use the current `PackSection` categories and retain
  their stacking, sort order, labels, rarity markings, stat lines, and action
  semantics.
- `Materials` shows every existing material row, including zero-count rows.
- Changing the filter spends no game turn, dispatches no core action, and is
  not saved or restored.

## Boundaries and invariants

1. `packages/core` and `packages/content` remain untouched. No game rule,
   content value, deterministic stream, balance band, item id, or save shape
   changes.
2. `Profile`, `GameState`, `GameViewState`, `TownViewState`, and their existing
   blocs remain the authority for facts and actions. A widget may choose a
   route/filter but cannot derive or mutate gameplay state outside those paths.
3. `SpellRow`, `packSections`, item presentation, stat delta, and material-row
   semantics remain single sources of presentation truth. New screens reuse or
   deliberately extract them; no screen-specific copy may drift.
4. The category filter and navigation are presentation state only. They do not
   alter carried order, stack membership, which item an action reaches, a
   refusal sentence, mana, health, equipment, materials, skills, or saves.
5. Accessibility remains non-negotiable: every category/state distinction has
   a label, position, number, or distinct mark. No new meaning is hue-only;
   normal-colour and greyscale phone evidence remain required.
6. Full spell access and all current transactional/refusal paths remain
   observable. Removing an old long-page section is a clean cutover, not a
   hidden compatibility surface.

## Explicit non-goals

- No static art, portrait, asset pipeline, HUD chrome, or icon-language work.
- No town/world/merchant/bank/forge/alchemist/inn/tavern/roster redesign.
- No new item categories, spell schools, spell availability states, item
  details, item actions, sorting rules, or inventory capacity rule.
- No changes to the crawl action shelf, readied-spell count/order, overflow,
  targeting, timeline, log drawer, map, Flame, camera, combat, balance,
  generator, RNG, content, or saves.
- No tabs on Character and no generic management-shell abstraction.

## Acceptance criteria

1. Town Character is a compact overview with explicit Gear, Spells, Skills,
   and Pack navigation and no duplicate long list of gear, spells, carried
   objects, materials, and skills.
2. Gear shows every current equipped slot in the established order; taking off
   an item sends the existing action and updates the observed town profile.
3. Spells lists every known spell once with the existing non-hue school
   identity and factual effect/cost data, offers no cast action, and does not
   create locked/unavailable spell states unsupported by content.
4. Skills lists every current skill and its existing progression facts once.
5. Pack defaults to All, filters only the six locked choices, retains the
   source-backed item stacks/order and zero-material rows, and has no duplicated
   stats/spells/worn/skills content.
6. Crawl Pack keeps drink/read/wear/drop behavior and its rule-owned refusals;
   town Pack keeps wear/read behavior where the existing town rules permit it,
   while Gear keeps the existing take-off path. Neither route invents an action.
7. Every known spell remains castable from the Unit 3 shelf/overflow, and no
   Pack or grimoire `Cast` control remains.
8. Existing M3 rules, content, deterministic behavior, item identities,
   transactional/refusal semantics, save version/document, and balance bands
   remain byte-for-byte outside `packages/app` presentation work.
9. Touched app formatting, `flutter analyze`, and the full `flutter test` suite
   pass from `packages/app`; focused widget and bloc tests demonstrate the new
   consumer-visible navigation/filter/action contracts.
10. Final current-phone AVD evidence shows Character, each focused route, and
    filtered Pack in normal colour and greyscale. It proves filter/navigation
    changes cost no turn, confirms no hue-only state, and backs up/restores both
    device save slots before/after any install.

## Verification and review disposition

- **COR:** run — moving the only visible paths to wear/read/take-off/drink/drop
  can silently remove transactional behavior.
- **TTC:** run — route/filter state, no-turn behavior, refusal visibility, and
  exhaustive spell access are behavioral contracts.
- **CRF:** run — the unit must reduce duplication without creating a generic
  management framework or a second presentation grammar.
- **SEC:** skip unless implementation adds a new external/security boundary;
  this unit is local Flutter presentation over existing state.
