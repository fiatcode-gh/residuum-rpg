# U15 Recon Anchors — observed at `4033de53f96470bfc75dabba6b28bc0ae67816a6`

These are anchors for local freshness recon, not a substitute for it.

## Git/LDD state

- `main` observed at `4033de53f96470bfc75dabba6b28bc0ae67816a6`.
- This is the merge of PR #23.
- Only `main` was present in the remote branch list at observation time.
- `RESUME.md` still described PR #23 as awaiting merge; reconcile this first.
- Canonical U13 `ROADMAP.md` names U15 next.

## U14 production authority now present

- `packages/app/lib/style/tokens.dart`
  - `Spectral` text face
  - `EB Garamond` display face
  - shared value ladder
  - shared text roles
  - `residuumTheme`
- `packages/app/lib/style/surfaces.dart`
  - `ResourceMeter`
  - `LabelledValue`

## Current U15 seams observed

### Crawl

`packages/app/lib/game/crawl_action_row.dart`

Observed:

- `CrawlAction` has `label`, `onPressed`, optional icon, armable/armed.
- row uniqueness and widget keys are based on composed `label`.
- `_fitFor` measures every candidate and selects the shortest legal layout.
- armed state reserves/renders `— armed`.
- U15 should preserve `_fitFor`'s algorithmic behavior.

`packages/app/lib/game/game_screen.dart`

Observed:

- spell action labels include school marking + spell name + mana cost;
- overflow uses `+N`;
- some actions remain iconless;
- action vocabulary/guards are already centralized here.

### Town/shared rows

`packages/app/lib/town/town_style.dart`

Observed:

- `ItemRow` is bespoke;
- `Heading`, `NothingHere`, `Purse`, `MaterialRows`, `CountStepper`, `Commit`, `TownRoom` are current shared town primitives;
- `Commit` still wraps `FilledButton`;
- no shared medallion-row component exists.

### Character

`packages/app/lib/town/character_screen.dart`

Observed:

- Gear / Spells / Skills / Pack are four separate full-width `FilledButton`s;
- mana uses `ResourceMeter(value: mana, ceiling: mana)` and therefore always appears full;
- local U14 record explicitly carries this as a follow-up.

### Spells

`packages/app/lib/game/spell_row.dart`

Observed:

- unframed mark + title + mechanical detail + optional trailing;
- no medallion slot;
- known-spell ordering helper exists;
- U15 can wrap/migrate without changing spell mechanics.

`packages/app/lib/town/spells_screen.dart`

Observed:

- lists known spells only;
- no Locked Spells section.

### Pack

`packages/app/lib/game/pack_screen.dart`

Observed:

- `ChoiceChip` is still used for filters;
- `_PackItemRow` is bespoke;
- All view enumerates every section and emits apology prose for empties.

### Forge

`packages/app/lib/town/forge_screen.dart`

Observed:

- one long screen owns Smelt count/commit plus temper/bench rows;
- no Craft mechanic was found in repository search;
- U15 must not invent one.

### Tavern

`packages/app/lib/town/tavern_screen.dart`

Observed:

- real action is `Ask about the roads`;
- it calls the existing rumor purchase transaction;
- no Rest/Listen/Leave verb set exists here;
- U14 records affordability presentation as a follow-up.

## Canonical appearance authority

Read before planning:

- `.flow/ldd/visual-reboot/units/unit-13/VISUAL-SYSTEM.md`
- `.flow/ldd/visual-reboot/units/unit-13/PARITY-MATRIX.md`
- `.flow/ldd/visual-reboot/units/unit-13/ROADMAP.md`
- `.flow/ldd/visual-reboot/units/unit-14/CONTRACT.md`

Do not resurrect superseded pre-U13 assumptions from older unit text.
