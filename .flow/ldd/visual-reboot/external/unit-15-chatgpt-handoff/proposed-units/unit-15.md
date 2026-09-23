# Proposed U15 Contract — Row, Control and Chip Grammar

## Status

- WHAT: **approved by the user**
- Unit type: parity implementation
- Implementation HOW: requires local execution-grade planning
- Authorization: **not carried**

## Outcome

The application stops presenting the same semantic shape through unrelated widget anatomies.

Town destinations, character navigation, spell rows, pack filters/items, room actions and crawl action chips consume one coherent Residuum grammar built on U14's production tokens/theme.

U15 also leaves stable, measured, empty-ready art slots for future authored assets without generating any new production art itself.

## Scope

### 1. Shared framed row

Establish one reusable row grammar with:

- fixed leading medallion/art slot;
- title;
- optional detail/purpose line;
- trailing affordance or action;
- `panel` fill;
- `rule` hairline;
- approved radius;
- stable alignment independent of whether authored art is present.

The medallion slot must be production-real and dimensionally stable so U16 can fill it without layout changes.

The row must work with an empty/placeholder state that does not pretend placeholder graphics are approved production art.

### 2. Town destinations

Migrate the real destination set to the shared framed-row grammar.

Keep all real destinations. The mock's smaller door count is an intentional presentation difference, not permission to remove gameplay destinations.

No new destination is invented.

### 3. Character

- Replace the Gear / Spells / Skills / Pack full-width button stack with the shared navigation-row grammar.
- Recompose stat rows toward the approved label/value/hairline vocabulary where U15 owns the row grammar.
- Correct the Character mana presentation so capacity is not shown as a permanently full live-resource meter.
- Do **not** add a current-mana field/getter to town state merely to satisfy the mock.

Hero portrait / identity art belongs to U17, not U15.

### 4. Spells

Migrate known spells to the shared framed-row grammar with an empty-ready medallion slot.

Add a `Locked Spells` presentation that does not leak undiscovered spell identities.

The game's real mechanical detail line remains authoritative.

No authored spell medallions are generated in U15.

### 5. Pack

Replace stock `ChoiceChip` presentation with the Residuum filter-control grammar.

Migrate pack items to the shared framed-row anatomy.

In the `All` view:

- absent item categories do not emit repeated apology prose;
- present categories retain clear hierarchy;
- Materials retain their real facts.

When a specific empty filter is selected, local planning may preserve a concise empty state if useful; the unit must not confuse "hide empty sections in All" with "show a blank screen under an explicitly selected empty category".

### 6. Forge

Recompose the Forge toward a menu/navigation grammar **using only real mechanics**.

Current repo reality has no Craft mechanic.

U15 must not create one.

Smelting and tempering/bench work may become navigable sub-surfaces if that is the cleanest way to reach the approved composition while preserving every current transaction and refusal.

No gameplay transaction is renamed, removed, duplicated or invented.

### 7. Tavern

Present the real Tavern action(s) in the shared framed-row grammar.

Preserve the current rumor-purchase semantics.

The U14 follow-up about affordability is in scope for presentation, but local planning must inspect current refusal behavior before deciding whether the action is visually disabled or remains pressable with an explicit affordability cue.

Do not silently remove an existing refusal path.

### 8. Crawl action shelf

Preserve the existing measure-all-candidates / choose-shortest legal layout algorithm.

Recompose action presentation so:

- primary verb/name is distinct from cost/count metadata where appropriate;
- spell mana cost is not part of the semantic/test identity of the action;
- overflow is a plain `+N`;
- armed state no longer requires an extra caption line if the approved non-hue grammar can communicate it through fill/border/weight;
- arming does not change row height or map allocation;
- the eleven-action ceiling still fits under the established 600 dp chrome cap.

Retire label-keyed action identity if local recon confirms it still exists. Prefer a stable action id/test identity independent of display wording or balance values.

## Boundaries

### In scope

Likely consumers include:

- `packages/app/lib/town/town_style.dart`
- `packages/app/lib/town/town_screen.dart`
- `packages/app/lib/town/character_screen.dart`
- `packages/app/lib/town/spells_screen.dart`
- `packages/app/lib/town/pack_screen.dart`
- `packages/app/lib/town/forge_screen.dart`
- `packages/app/lib/town/tavern_screen.dart`
- `packages/app/lib/game/pack_screen.dart`
- `packages/app/lib/game/spell_row.dart`
- `packages/app/lib/game/crawl_action_row.dart`
- `packages/app/lib/game/game_screen.dart`
- shared style/surface code needed for the row/filter/control grammar
- focused tests for the touched behavior/presentation contracts

Exact ownership must be revalidated locally.

### Protected by default

- `packages/core/**`
- `packages/content/**`
- save schema / save compatibility
- dungeon rendering and dungeon assets
- illustration-header composition (U17)
- hero portrait art/identity block (U17)
- authored icon/medallion/item/log art (U16)
- dungeon lighting (U18)
- dungeon structure/props (U19)
- actors (U20)
- combat timeline/log density and target reticle language (U21)

## Locked semantics

- engine authority and determinism;
- no important state by hue alone;
- every touched state remains legible in greyscale;
- real game vocabulary wins over mock text;
- four-region rule: map = space/targets, timeline = time, log = causality, action shelf = verbs;
- melee remains map-first;
- targeted spell remains `arm → map target → tap`;
- circle selection vs square targeting distinction remains;
- activation repetition and hidden-actor secrecy remain;
- `readiedSpellCount` remains 3 unless a separate gameplay/content unit changes it;
- eleven actions remain the legal row ceiling;
- `Flee` never appears inside a dungeon crawl where it is currently impossible;
- `cameraCellSize` remains 36 dp;
- map remains `Expanded`;
- existing refusal/transaction semantics remain authoritative.

## Asset boundary

U15 generates **no new authored production assets**.

It must instead leave concrete consumer slots ready for later `flow-assets` work:

- stable rendered dimensions;
- stable padding/safe area;
- known shape/alignment;
- transparent-capable asset host;
- no tinting assumptions that would conflict with multitone masters;
- contextual tests/evidence sufficient for U16 to derive an asset contract from the real consumer.

Do not create speculative placeholder art and later bless it as production.

## Acceptance criteria

1. One production framed-row grammar exists and replaces the targeted bespoke navigation/list rows.
2. The leading medallion/art slot is stable, empty-ready and measurable.
3. Town uses the shared row grammar for all real destinations.
4. Character routes use the shared grammar.
5. Character mana is no longer represented as a misleading permanently full live-resource meter.
6. Spells use the shared grammar and include a non-leaking Locked Spells section.
7. Pack filters no longer rely on stock `ChoiceChip` presentation.
8. Pack item rows use the shared grammar.
9. Empty categories in Pack's `All` view no longer produce repeated apology prose.
10. Forge is reorganized around only the real mechanics; no Craft mechanic appears.
11. Tavern preserves real rumor semantics while gaining the shared action presentation.
12. Crawl action identity is independent of composed label/cost where local recon confirms label-keying still exists.
13. Crawl costs/counts are presented separately enough that balance values do not define widget identity.
14. Armed/unarmed transitions do not reflow map/chrome.
15. Worst legal crawl density remains below the 600 dp chrome ceiling on target hardware.
16. No new production art is generated.
17. U16 can derive concrete `flow-assets` contracts from the resulting consumer slots without further layout invention.
18. Focused tests plus normal app gates pass.
19. Affected list/control screens are re-shot in colour and greyscale on the target phone.
20. No gameplay/content/save/dungeon behavior changes.

## Evidence targets

At minimum capture:

- Stonebridge destinations;
- Character;
- Spells;
- Pack populated state;
- Pack empty-filter state;
- Forge menu + one work surface if split;
- Tavern;
- exploration action row;
- combat typical;
- combat worst legal;
- armed spell state;
- world map and roster only if U15 changes a shared primitive they consume.

The evidence gate judges parity movement in row anatomy, density, hierarchy and control grammar, not authored icon parity. Empty medallion slots are expected until U16.
