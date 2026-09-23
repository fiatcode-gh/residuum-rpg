# U15 — Proposed Implementation Strategy

## Disposition

**Partial strategy only. Not execution-grade.**

The WHAT is approved. Local `flow-planning` must perform fresh recon and refine exact seams, task briefs, Red/Green/Refactor proofs, interface contracts and escalation conditions.

## Recommended dependency shape

Four sequential tasks are likely cleaner than three because the shared primitive must settle before consumers, and the crawl shelf has its own density/testing risks.

### Task 01 — Shared row/filter/control primitives

Establish the reusable framed-row grammar and custom filter/control skins on top of U14 tokens.

Goals:

- row geometry;
- medallion/art slot;
- title/detail/trailing anatomy;
- available/selected/disabled state treatment;
- no authored production art;
- tests for geometry/semantics/accessibility.

This task should define the consumer facts U16's `flow-assets` contracts will later read.

### Task 02 — Town/Character/Spells/Pack migration

Migrate:

- town destinations;
- Character navigation and stat-row anatomy;
- Spells rows + Locked Spells;
- Pack filter controls;
- Pack item rows;
- All-view empty-section cleanup.

Also fix Character mana capacity presentation here because this task owns Character presentation.

### Task 03 — Forge and Tavern composition

Ground in actual mechanics.

Forge:

- do not invent Craft;
- preserve Smelt and Temper/bench transactions;
- split menu vs work surfaces only if local recon confirms this is a presentational navigation change with unchanged semantics.

Tavern:

- preserve rumor purchase;
- expose affordability more clearly without silently deleting the current refusal path.

### Task 04 — Crawl action-chip grammar

Preserve `_fitFor`'s measure-all-candidates behavior.

Refine:

- stable action id;
- visible label vs metadata/cost;
- plain `+N`;
- armed presentation without row-height reflow;
- unchanged action dispatch;
- unchanged 11-action ceiling.

This task owns the expensive density verification.

## Suggested TDD focus

### Task 01 Red

Pin:

- row semantics;
- medallion-slot dimensions/alignment;
- disabled/selected meaning without hue;
- trailing affordance reachability;
- no implicit Material geometry leak.

### Task 02 Red

Pin:

- existing routes/actions;
- unknown spell identities do not leak;
- pack filters still select the same semantic sections;
- explicit empty filter behavior;
- Character shows mana capacity truthfully without fabricating current mana.

### Task 03 Red

Pin:

- Forge transaction calls and refusal/cost facts;
- Tavern rumor transaction and refusal behavior;
- no new gameplay verb exists.

### Task 04 Red

Pin:

- exact action visibility conditions;
- authoritative dispatch;
- stable id independent of display label/cost;
- arm/unarm behavior;
- no row-height change from armed state;
- worst-legal action set remains fully reachable.

## Integrated gate

After implementation:

- `dart format --set-exit-if-changed --output=none lib test`
- `flutter analyze`
- full `flutter test`
- target-device colour/greyscale evidence
- remeasure exploration / combat typical / combat worst-legal chrome
- record actual device figures, never infer from widget-test dp.

## Escalation conditions

Stop and return to architect if:

- matching the mock would require a new gameplay verb or transaction;
- Forge composition cannot be changed without core/content changes;
- Tavern affordability cue would require changing refusal semantics;
- U15 appears to require authored production art to make layout work;
- the medallion slot cannot be stable without knowing U16 artwork;
- crawl geometry cannot keep the legal 11-action ceiling under 600 dp;
- a proposed simplification would replace `_fitFor` with guessed fixed columns;
- a change touches dungeon rendering, save schema or content balance.

## Completion receipt

Local plan should require each worker to return:

- files changed;
- behavior protected;
- tests added/rewritten and what they defend;
- visual consumer dimensions established;
- any U16 `flow-assets` facts discovered;
- gate results;
- remaining findings;
- whether scope/escalation conditions were hit.

Then stop for the user's merge choice.
