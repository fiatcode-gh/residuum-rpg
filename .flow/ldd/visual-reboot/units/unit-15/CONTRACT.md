# Unit 15 — Row, Control and Chip Grammar

Status: **approved WHAT, reconciled 2026-09-22.** The validated external
planning handoff records the user's approval of this materially unchanged
boundary. Implementation requires a separately approved execution-grade plan.

Base: `main` at `4033de53f96470bfc75dabba6b28bc0ae67816a6`.
Appearance authority: `../unit-13/VISUAL-SYSTEM.md` sections 2–4 and 6–9.
Source grounding: `recon.md`.

## Outcome

The application presents its remaining town destinations, character routes,
known-spell and pack-item lists, pack filters, room actions, and crawl shelf
through one coherent Residuum row/control/chip grammar. Existing game actions,
vocabulary, dispatch and information boundaries do not change.

The shared row has a stable, measurable, empty-ready leading medallion host.
It intentionally contains no newly authored production art; Unit 16 will use
these real consumers to derive asset contracts.

## In scope

- One framed row/control primitive built from U14 tokens: panel fill, rule
  hairline, 6 dp radius, fixed leading medallion envelope, title, optional
  detail/refusal and trailing affordance.
- All seven real town destinations, the four Character routes, known-spell
  rows and Pack item rows consume that primitive or its direct grammar.
- Spells gains a `Locked Spells` presentation that reveals no unknown spell
  identity.
- Character represents mana capacity without a full live-resource meter or a
  fabricated current-mana town fact.
- Pack filters stop rendering as stock `ChoiceChip`s. `All` omits empty item
  sections; an explicitly selected empty category retains a concise empty
  state. Materials retain their fixed, zero-inclusive rows.
- Forge is reorganized only around its existing smelting and tempering work.
  Tavern presents its existing `Ask about the roads` transaction with a
  visible affordability cue while preserving its press/refusal behavior.
- Crawl actions gain identity independent of their composed label/cost;
  visible verb and metadata may be separated. The `+N` overflow remains plain
  and arming changes no row height or map allocation.

## Protected boundaries

- No changes in `packages/core`, `packages/content`, save schema, balance,
  dungeon rendering, authored art, illustration headers, portraits, timeline
  or log density.
- Existing routes, BLoC event dispatch, transaction outcomes, refusals,
  known-spell ordering, pack category semantics and item actions remain
  authoritative.
- No new Craft mechanic, no mock-only Tavern verbs, no current-mana addition
  to `TownViewState`, and no unknown-spell identity leak.
- No important state may depend on hue. OS-level greyscale capture is not an
  acceptance requirement.
- Crawl retains measure-all-candidates/shortest-legal-layout, its eleven-action
  ceiling, `readiedSpellCount == 3`, map-first melee, arm → map target → tap,
  a fixed 36 dp camera cell and an `Expanded` map.

## Acceptance criteria

1. One production row/control grammar replaces the named bespoke target rows.
2. Its medallion host has stable dimensions, transparent-capable empty state,
   fixed alignment/padding and a measurable fallback with no placeholder art.
3. Town destinations and Character routes preserve every current route.
4. Character mana reads as capacity, not a permanently full current pool.
5. Known spells use the grammar; `Locked Spells` leaks no unavailable names.
6. Pack filters preserve selected semantics and category contents without stock
   `ChoiceChip`; `All` has no repeated empty-category apology prose.
7. Forge retains only Smelt and Temper transactions. Tavern still spends and
   reveals on a successful rumor purchase and still exposes its existing
   insufficient-gold refusal.
8. Crawl stable identifiers no longer change when counts, costs or visible
   labels change; action visibility, dispatch, arm/unarm semantics and the
   legal 11-action ceiling remain intact.
9. No authored production art is added. U16 can derive actual asset envelopes,
   padding, alignment, untinted expectation and absent-art fallback from U15.
10. Focused behavior/presentation tests, app formatter/analyzer/full suite,
    and target-phone colour evidence pass. Worst legal crawl chrome is measured
    below 600 dp on device.

## Non-goals

No artwork generation, new gameplay verbs, navigation semantics, content or
save work. No global Material theme change. No speculative icon pack or
placeholder promoted as production art.

## Proof expectation

Workers first make focused widget/BLoC proof fail for the observable behavior
they change, then restore it while preserving the existing transaction and
route tests. Final acceptance includes the package gates from `packages/app`
and target-device colour evidence for every affected list/control surface and
the exploration, typical combat, worst legal combat and armed-skill crawl
states.
