# Unit 15 — Row, Control and Chip Grammar

Status: **execution-grade local LDD plan**

## Planning basis

- Source/base revision: `main` at `4033de53f96470bfc75dabba6b28bc0ae67816a6`.
- Governing WHAT: `CONTRACT.md` (approved and materially unchanged).
- Current-source facts: `recon.md` plus only the named source/test seams and the `ItemRow` merchant/bank callers required to close the migration map.
- Appearance authority: `../unit-13/VISUAL-SYSTEM.md` sections 2–4 and 6–9.
- Roadmap authority: `../unit-13/ROADMAP.md`, U15.
- Dirty-state assumption: application source and tests match the base revision. Existing staged/shared-ledger changes in `LEDGER.md`, `RESUME.md`, `CONTRACT.md`, `recon.md`, and `external/unit-15-chatgpt-handoff/` are user-owned inputs and must remain untouched. The four tasks run sequentially in the same suitable feature checkout after explicit plan approval.
- A revision change requires targeted revalidation of only the touched seams below; it does not by itself reopen the approved WHAT.

## Locked scope and invariants

Unit 15 changes presentation in `packages/app` only. It must not change `packages/core`, `packages/content`, save/schema behavior, balance, transaction results, BLoC event meaning, dungeon rendering, authored assets, illustration headers, portraits, timeline, or log density.

The following remain authoritative:

- all seven town routes and all four Character routes;
- known-spell ordering and the rule that an unavailable spell's name, school, cost, effect, or other identity is not rendered;
- Pack category membership, stack/action behavior, selected-filter transience, and zero-inclusive fixed material rows;
- Forge's existing `SmeltPressed` and `TemperPressed` transactions only;
- Tavern's single `Ask about the roads` offer, including the existing press-to-refuse path when gold is short and the successful paired `RumorBought`/`RumorHeard` result;
- crawl visibility guards, event dispatch, map-first melee, arm → map target → tap, second-tap disarm, `readiedSpellCount == 3`, no crawl `Flee`, the legal eleven-action ceiling, fixed 36 dp camera cells, and the `Expanded` map allocation;
- `_fitFor` measures every legal column candidate and chooses the shortest legal total row height; it does not become first-fit;
- no state relies on hue. Selected/armed/disabled states retain word, mark, border, weight, value, or semantic cues in greyscale;
- no production art is added. Existing rarity/school markings are facts, not placeholder art, and may occupy the empty-ready medallion host.

## Shared row API and ownership

Task 01 adds one public primitive to `packages/app/lib/style/surfaces.dart`:

```dart
class FramedRow extends StatelessWidget {
  const FramedRow({
    required this.title,
    this.details = const [],
    this.medallion,
    this.medallionKey,
    this.trailing,
    this.onPressed,
    this.titleStyle = textBody,
    this.detailStyle = textLineDim,
    super.key,
  });

  final String title;
  final List<String> details;
  final Widget? medallion;
  final Key? medallionKey;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final TextStyle titleStyle;
  final TextStyle detailStyle;
}
```

The implementation contract is exact:

- outer surface: `panel` fill, `rule`/`hairline` border, `radius == 6`, no elevation, shadow, gradient, or tint;
- outer spacing: `rhythm` below each row; inner padding 8 dp horizontal and 6 dp vertical;
- leading column: always present, 44×44 dp (`tapTarget`) and keyed by `medallionKey` when supplied;
- medallion well: centered 36×36 dp, transparent fill, circular `rule`/`hairline` ring; a null `medallion` leaves that well empty but measurable and does not synthesize an icon, letter, image, or placeholder;
- supplied medallion content is centered, clipped to the 36 dp circle, and rendered without tinting or opacity changes;
- content gap: 8 dp; title uses `titleStyle`, at most two lines with ellipsis; each detail/refusal is a separate line in input order using `detailStyle`;
- trailing content is vertically centered and unconstrained except by the row's remaining width; existing themed buttons remain responsible for their enabled/disabled behavior;
- `onPressed != null` makes the whole row one Material/InkWell control with button/enabled semantics and a 44 dp minimum hit target. A null callback produces a non-button presentation row. Callers must not put an independently tappable trailing control on a whole-row tappable instance.

`FramedRow` owns geometry only. It does not know routes, item/spell models, prices, transactions, filter state, crawl actions, or assets. `town_style.dart::ItemRow` remains a small domain adapter because merchant, bank, and Tavern genuinely share its mark/name/action/refusal contract; its body becomes `FramedRow` plus the existing themed trailing `FilledButton`. It gains `List<String> details = const []`, appends a disabled `reason` after those details, and keeps the 104 dp action slot and current callback semantics. This is a composition adapter, not a second row anatomy.

## Consumer migration map

| Surface | Production seam | Planned representation | Preserved behavior |
|---|---|---|---|
| Merchant, Bank, Tavern item/offer rows | `town_style.dart::ItemRow` and its existing callers | `ItemRow` composes `FramedRow`; rarity/`[!]` mark is medallion content, action remains trailing | prices, refusals, callbacks, stacking, order |
| Seven town destinations | `town_screen.dart::_Door` | delete `_Door`; seven keyed `FramedRow(onPressed: …)` instances with the same labels/purposes and empty medallions | route order, targets, two-bloc propagation, short-phone reachability |
| Four Character routes | `character_screen.dart` | four keyed whole-row `FramedRow`s, same labels/callbacks, empty medallions | route targets and TownBloc identity |
| Character mana | `_Stats` | `LabelledValue(label: 'Mana capacity', value: '$mana')`; remove `characterManaMeterKey` and the false full meter | capacity fact only; no fabricated current value |
| Known spells | `spell_row.dart::SpellRow` | compose `FramedRow`; school marking in medallion, spell name title, cost/effect/refusal detail lines, existing optional trailing action | ordering, cast/refusal behavior in crawl overflow |
| Locked spells | `spells_screen.dart` | `KNOWN SPELLS` and `LOCKED SPELLS` sections; one generic locked summary row showing only count and `Unknown until learned.`; zero case says `No spells remain locked.` | no unknown name, school, cost, effect, kind, or ordering leak |
| Pack filters | `_PackContentsState` | private `_PackFilterControl` using Material/InkWell, not `ChoiceChip`/`Chip` | same six keys, local selected state, no game/town mutation |
| Pack rows | `_PackItemRow` | compose `FramedRow`; rarity marking in medallion, current detail lines in current order, current primary action then Drop in a vertical 104 dp trailing column | Drink/Read/Wear/Drop behavior and refusals |
| Forge | `forge_screen.dart` | root Forge menu with only `forge-route-smelt` and `forge-route-temper`; private Smelting and Tempering screens behind it | only existing Smelt/Temper transactions |
| Tavern affordability | `tavern_screen.dart` | `ItemRow.details` carries the exact affordability sentence while the Ask button remains enabled | poor press still refuses; success still updates both blocs |
| Crawl shelf | `crawl_action_row.dart`, `game_screen.dart::_actionsFor` | required stable action id plus separated metadata; widgets key by id | guards, dispatch, arm/disarm, measurement, map allocation |

### Pack filter state grammar

`_PackFilterControl` is private to `game/pack_screen.dart` and has `label`, `selected`, and `onPressed`. It keeps each existing `pack-filter-<name>` key. It renders at a minimum height of `tapTarget`, 12 dp horizontal padding, `radius`, and:

- unselected: `raised`, `rule`/`hairline`, `textLabel`;
- selected: `armedFill`, `ink`/2 dp, `textLabelStrong`, and a visible `✓` before the label;
- semantics: button, enabled, and selected flags; tapping the already selected filter is a no-op but remains semantically enabled.

No `ChoiceChip` or `Chip` remains in Pack. `All` emits only non-empty item sections, then always emits Materials. Selecting an empty item category emits its heading and exactly its existing concise `NothingHere` sentence. Materials always show all fixed rows, including zeroes.

### Forge navigation and Tavern cue

`ForgeScreen` becomes a stateless menu retaining the Forge title, purse, notice, and existing Forge illustration, followed by two empty-medallion `FramedRow` routes:

- `forge-route-smelt`: title `Smelt`, detail `Turn ore into ingots.`;
- `forge-route-temper`: title `Temper`, detail `Work carried or worn steel.`.

Each route pushes a private screen in the same file under `BlocProvider.value` with the same TownBloc. `_SmeltingScreen` owns the existing local pending-count state and renders purse → notice → materials → the unchanged stepper/Smelt commit/refusal. `_TemperingScreen` renders purse → notice → materials → the existing worn/carried steel sections; `_TemperRow` composes `FramedRow`. The menu contains no commit control, and no third work route is introduced.

Tavern keeps `Ask $rumorPrice` enabled whenever a rumor is offered. Its detail is exactly:

- `Affordable — costs $rumorPrice gold.` when `town.gold >= rumorPrice`;
- `Need ${rumorPrice - town.gold} more gold — costs $rumorPrice gold.` otherwise.

This is a non-destructive cue. The poor path still calls `_ask`, dispatches the existing result to both blocs, changes neither gold nor discovered destinations, and exposes `you cannot afford that` through the existing notice path.

### Crawl identity, metadata, and geometry

`CrawlAction` gains required `String id` and optional `String metadata = ''`. `label` becomes visible verb/name only. `CrawlActionRow` asserts id uniqueness and `_ActionChip` uses `ValueKey(action.id)`; neither label, count, cost, nor metadata participates in identity.

The exact id/visible vocabulary in `_actionsFor` is:

| id | label | metadata |
|---|---|---|
| `drink` | `Drink` | `×<potionCount>` |
| `spell:<spell.id>` | `<school marking> <spell name>` | `<manaCost> mana` |
| `spells-overflow` | `+<known - readiedSpellCount>` | empty; no icon |
| `wait` | `Wait` | empty |
| `pick-up` | `Pick up` | empty |
| `gather` | current authoritative `node.verb` | empty |
| `pack` | `Pack` | `×<inventory length>` |
| `flee` | `Flee` | empty; encounter only, never crawl |
| `move-on` | `Move on` | empty |
| `ascend` | `Ascend <` | empty |
| `descend` | `Descend >` | empty |
| `leave-dungeon` | `Leave` or `Finish` from the existing ending rule | empty |

The overflow remains visually plain `+N`: no More icon and no invented word. Semantics reads label followed by metadata when metadata is non-empty.

`_fitFor` remains a measure-all-candidates minimizer. For every candidate it measures each label in its heaviest possible state, each non-empty metadata string in `crawlCaption`, and the armed caption. It rejects a candidate if a label exceeds `crawlChipMaxLabelLines`, if any metadata/armed caption wraps, or if any widest word does not fit. The chosen common chip height includes the maximum label block, one reserved metadata block when any action has metadata, and the already-reserved armed-caption block when any action is armable. Missing metadata/armed text gets an equal-height spacer. Arming therefore changes border/weight/caption content but not row height or the map rectangle. Every chip still reserves the icon envelope, including the plain overflow, so widths/heights remain common.

## Task graph

```text
01-shared-framed-row
  -> 02-list-consumer-cutover
      -> 03-forge-tavern-presentation
          -> 04-crawl-stable-action-geometry
              -> Main integration gates and target-device evidence
```

These tasks are intentionally sequential because each consumes production APIs or repository state produced by its predecessor. Each brief is a fresh-executor capsule:

1. `plan-tasks/01-shared-framed-row.md`
2. `plan-tasks/02-list-consumer-cutover.md`
3. `plan-tasks/03-forge-tavern-presentation.md`
4. `plan-tasks/04-crawl-stable-action-geometry.md`

Task 02 is one coherent named-consumer cutover: a handoff with only some of the contract's town/Character/Spells/Pack target anatomies migrated would leave two production grammars and would not satisfy the shared-grammar boundary. Its brief still separates Red/Green proof by owning test file so failures remain local.

## Final integration gates owned by Main

Run only after all four task receipts have been accepted and the final source diff has been inspected against this plan:

```sh
cd packages/app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Then inspect the final diff and prove:

- no changes outside `packages/app` plus the tracked U15 ledger artifacts;
- no authored assets or asset-manifest entries;
- no `ChoiceChip`/`Chip` in Pack and no old `_Door` or bespoke `_PackItemRow` layout body;
- no unknown spell identity rendered;
- no new gameplay/content/save/dungeon/timeline/log behavior;
- no action id derived from label, cost, count, or metadata;
- the worst-legal crawl fixture still renders exactly eleven action controls, with no crawl `Flee`.

Any post-acceptance production correction reopens scoped acceptance for the changed dependency surface before device evidence is accepted.

## Target-phone evidence owned by Main

Use the repository's target phone and capture each named state in colour. Keep
text scale at the normal acceptance setting, and additionally retain the
focused 1.3× crawl widget proof from Task 04.

- Town: Stonebridge and Northgate, all seven destination rows reachable, empty medallion alignment visible.
- Character: overview showing `Mana capacity` and all four routes.
- Spells: a mixed known/locked profile and an all-known profile; confirm no unavailable identity appears in pixels or accessibility output.
- Pack: populated `All`, empty `All`, an explicitly selected empty item category, Materials, and a row with two actions/refusal as available.
- Forge: menu, Smelting console, Tempering console with both a live and refused steel row.
- Tavern: affordable, unaffordable after pressing Ask (notice visible), and exhausted offer.
- Crawl: exploration, typical combat, worst legal combat, and armed targeted spell. Record measured total crawl chrome for the worst legal state and require `< 600 dp`; capture the map rectangle before/after arming and require equality. Confirm each camera cell remains 36 dp and the map remains the `Expanded` child by source/diff inspection plus the unchanged on-device viewport behavior.

Selection, disabled, armed, affordable, and refused state must remain
communicated by marking, words, border/value, or weight rather than hue alone.
U16 must be able to derive the 44 dp host, 36 dp untinted well,
padding/alignment, and null-content fallback from these real consumers. World
map and roster are unchanged by this unit and need no new U15 capture unless
the final diff unexpectedly reaches either surface; that condition is an
escalation, not automatic scope growth.

## Plan quality gate

- **COR — PASS:** ownership, public API, row geometry, route/transaction preservation, Pack empty semantics, locked-spell secrecy, Forge navigation, Tavern refusal path, crawl identity vocabulary, measurement algorithm, armed no-reflow invariant, and integration order are decided. Failure paths have explicit non-destructive behavior.
- **TTC — PASS:** each changed behavior maps to a named proof file and Red/Green assertion in the task capsules. Negative/boundary proof covers empty Pack modes, unknown-spell leakage, poor Tavern press, absent Forge work routes, stable ids under visible changes, all eleven legal crawl actions, 1.3× text, and the 600 dp ceiling.
- **CRF — PASS:** one geometry owner (`FramedRow`) replaces bespoke layouts; `ItemRow` remains only as a justified town-domain adapter; filter and crawl controls keep state/measurement local; no model-layer abstraction, compatibility shim, duplicate row family, or speculative asset resolver is planned.
- **SEC — SKIP (not applicable):** this is local presentation over existing in-memory trusted models with no new I/O, persistence, authorization, parsing, network, or secret boundary. Information disclosure is relevant and is covered under COR/TTC by the unknown-spell identity prohibition.

Residual implementation risks are evidence risks, not open design decisions: Spectral metrics may pressure the 600 dp physical-device ceiling; nested trailing controls can accidentally create duplicate tap semantics if a caller also sets row `onPressed`; and the generic locked count must be revalidated if the content map changes from the base. Each is paired with a focused escalation condition in the task brief. No material product or architecture decision remains delegated to an executor.
