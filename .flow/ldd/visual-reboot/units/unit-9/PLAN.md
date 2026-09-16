# Unit 9 — Crawl HUD Chrome: Execution Plan

Status: **execution-grade; planning only.** This artifact does not authorize
production implementation. The user approves the plan separately before any
executor runs.

Derived from the user-approved `CONTRACT.md` (approval recorded at
`../../LEDGER.md:1236-1239`), `units/unit-9/recon.md`, the Unit 9 records in
`../../LEDGER.md:1177-1239`, the epic's locked cross-unit contracts
(`../../LEDGER.md:69-116`), and `AGENTS.md`.

## Source base and dirty-state assumption

The source base is `2b0e0a4` on `main` — the merged Unit 8 head, in sync with
`origin/main`. Every path in this plan was re-read at that revision by the
planner; the recon's references were confirmed rather than trusted.

`packages/` is **clean** at that base. The worktree is dirty only in
architect-owned LDD authority: modified `.flow/ldd/visual-reboot/LEDGER.md` and
`RESUME.md`, plus the untracked `units/unit-9/` directory holding the approved
contract, the recon, this plan and its task brief. Executors preserve those
bytes and never stash, revert, commit or edit them.

A changed app revision requires targeted revalidation of the named seams below,
not automatic replanning.

## Execution boundary and dependency graph

Implementation is **prohibited on `main`**. After explicit user approval of this
plan, use one non-isolated feature checkout branched from `2b0e0a4`, by house
convention `residuum-visual-reboot-9`.

```text
01-two-row-crawl-status
  -> Main integrated gates (format / analyze / full flutter test / scope audit)
  -> integrated acceptance review and corrections
  -> user-started Medium_Phone device gate (carries Unit 8 criterion 9)
```

**One task, deliberately.** The split of `_HitPoints._line` into two rows is a
single Red→Green proof cluster with no valid intermediate handoff state:

- `_line` (`game_screen.dart:259-269`) is one function that concatenates every
  fact on the row. Invariant 7 requires it deleted, and every fact it carries
  must land on the new rows in the same change. Landing "half the facts" means
  inventing a third composition nobody reviews and the contract forbids.
- twenty-five assertion sites across six test files observe that one string or
  its absence. The composition change breaks or hollows out every one of them,
  so no partition of the work leaves `flutter test` green between halves.
- a header-first / resource-row-second split would require an interim
  `_HitPoints` that renders a header *and* a residual concatenated line — throwaway
  code, explicitly banned by invariant 7.

The brief is therefore one capsule, not padding and not a bundle of independent
clusters. It is sized by one deletion, one new file, one wiring line and one
test migration that are inseparable.

Only `packages/app` may change. **Nothing under `packages/core` or
`packages/content` may change.** Save code/data, dependencies, generated files,
assets, `main.dart`, town/world/Character/roster screens, battle dock/shelf,
log drawer/peek, `_Controls`, the death overlay and LDD authority are out of
scope.

## Revalidated source seams

All read at `2b0e0a4`.

| Seam | Current fact | Planned consequence |
| --- | --- | --- |
| `lib/game/game_screen.dart:124` | `_HitPoints(state: state)` is the fourth child of the crawl `Column`, between `BattleShelf` and `LogPeek`. | Becomes `CrawlStatus(state: state, dungeon: bloc.dungeon)` in the same slot. `bloc` is already in scope at `:61`. Nothing else in `GameScreen.build` changes. |
| `game_screen.dart:76-121` | The dungeon viewport is `Expanded`. | Unchanged. Every pixel the new rows add comes out of the map silently, which is why the height budget below is locked and device-measured. |
| `game_screen.dart:197-244` | `_HitPoints.build`: `Padding(horizontal: 12, vertical: 6)` over a `Row` of a 56-px bar (`minHeight: 14`, track `0xFF23262E`, fill `0xFFDDE1E7`), `_BattleGlyph`, and an `Expanded FittedBox(scaleDown)` holding `_line`. | Deleted whole. Replaced by `lib/game/crawl_status.dart`. |
| `game_screen.dart:204-207` | `ceiling = state.maxHp`; `fraction = ceiling == 0 ? 0.0 : hero.hp / ceiling`; `shown = hero.hp.clamp(0, ceiling)`. | Preserved verbatim in `_ResourceRow`. The zero-ceiling guard and the clamp are behaviour, not incidental. |
| `game_screen.dart:246-269` | `_line` plus its device-history Dartdoc. | Deleted. The history it records is the reason the scale-down discipline survives; see "Shrink-to-fit". |
| `game_screen.dart:271-280` | `_battleWord`: `Engaged n` when `isBattleOpen`, `Watched n` when `enemiesInSight > 0`, else `''`. | Moved verbatim to `crawl_status.dart` as a private top-level function. |
| `game_screen.dart:282-300` | `_magic`: `''` unless `knownSpells` is non-empty, else `'  Mana m/max'` plus `'  Ward n'` while one stands. | **Deleted as a formatter.** Its two rules become structure: the Mana cell exists iff a spell is known; the ward is the Mana cell's note iff `warded > 0`. No string builder survives. |
| `game_screen.dart:302-321` | `_whereabouts` reads `context.read<GameBloc>().dungeon`, returns `The road` for an encounter, `Depth n/m` for a null dungeon, else `<name> — depth n/m`. | **Deleted.** Replaced by `_placeName` plus a separate depth-pair cell; the node id arrives as a constructor input instead of a second bloc read. |
| `game_screen.dart:323-328` | `_condition(fraction)`: `Dead` / `Critical` / `Wounded` / `Steady` at `<= 0`, `< 0.25`, `< 0.6`. | Moved verbatim to `crawl_status.dart`. Thresholds and the unclamped input are preserved exactly. |
| `game_screen.dart:344-375` | `_BattleGlyph`: `SizedBox(width: 18)` over a centred `Text` of `✖` / `◉` / `''`, styled inline `monospace 14 #DDE1E7`. | Moved to `crawl_status.dart`. Width, glyph selection and centring are byte-identical; only the inline style becomes `mono`. |
| `game_screen.dart:17` | `import '../town/town_style.dart' show ink, dim;` | Unchanged — `ink`/`dim` are still used by the battle shelf (`:766, :776, :800, :873, :893, :897, :904, :911`), so the import must not be trimmed. |
| `game_screen.dart:377-525` | `_Controls`, `doneAtTheBottom`, the underfoot/here prose. | Frozen. No control, label, row count or sentence changes. |
| `lib/town/skills_screen.dart:28-61` | `_SkillRow`: label `SizedBox(88)`, level `SizedBox(24)`, `Expanded ClipRRect(radius 2) LinearProgressIndicator(minHeight: 8, backgroundColor: rule, valueColor: ink)`, `SizedBox(56)` of `monoDim`; progress guarded by `cost == 0 ? 0.0 : (xp / cost).clamp(0, 1).toDouble()`. | **Not edited.** Its grammar is duplicated once in `_Meter`; see "Duplicate, do not extract". |
| `lib/town/town_style.dart:9-24` | `ink #E6EAF0`, `dim #8A919E`, `panel #15181F`, `rule #2A2E38`, `mono` (monospace 14 ink), `monoDim` (monospace 12 dim). | The whole vocabulary of both new rows. The crawl's local `#DDE1E7` literal is retired in favour of `ink`, as the contract's "existing `town_style.dart` vocabulary" requires. |
| `lib/game/game_bloc.dart:328, 336, 339, 436, 495, 500, 503, 506, 575` | `depth`, `deepest`, `isEncounter`, `isBattleOpen`, `enemiesInSight`, `mana`, `maxMana`, `warded`, `maxHp` are all pure projections on `GameViewState`. | Read as-is. No getter is added, renamed or moved. |
| `game_bloc.dart:630` | `final NodeId? dungeon;` on `GameBloc` — the stable session identity, null for road fights and for bare test harnesses. | Passed into `CrawlStatus` by `GameScreen`. Not moved into `GameViewState`, not serialized, not defaulted. |
| `packages/core/lib/src/engine/step.dart:296-303` | `warded` is set only by `SpellKind.ward`, which requires a known ward spell. | Justifies the ward rule below: `warded > 0` with no known spell is unreachable under current rules. |
| `test/support/phone.dart:9-13` | `onAPhone` sizes the surface to 1080×2424 at DPR 2.625 — **411.4 × 923.4 logical pixels** — and restores it on teardown. | **Recon trap 3 is superseded in part.** A widget test *can* now run at real phone width; `world_screen_test.dart:1665-1689` already uses it as an overflow guard with `tester.takeException()`. Layout arithmetic and `RenderFlex` overflow are widget-provable; font metrics and real pixels remain device-only. |

## Locked architecture and interfaces

### 1. File and widget decomposition

Add `packages/app/lib/game/crawl_status.dart`. It owns both rows and nothing
else. `game_screen.dart` is already 916 lines and `AGENTS.md` says a large file
means a concept wants splitting; the two-row status is exactly such a concept,
and keeping it inline would trade a 133-line deletion for a ~150-line addition
in the same oversized file. The new file also lets the rows stay free of
`flutter_bloc`.

```dart
const hpMeterKey = Key('hp-meter');
const manaMeterKey = Key('mana-meter');
const depthPairKey = Key('crawl-depth');

class CrawlStatus extends StatelessWidget {
  const CrawlStatus({required this.state, required this.dungeon, super.key});

  final GameViewState state;
  final NodeId? dungeon;
}
```

File-private below it: `_HeaderRow`, `_ResourceRow`, `_Meter`, `_BattleGlyph`,
`_placeName`, `_battleWord`, `_condition`. The three public keys follow the
existing crawl precedent (`recenterKey`, `shelfKey`, `controlsKey`,
`logPeekKey`) and exist because tests must tell two meters apart and must
observe the *absence* of the depth pair on a road. No other public surface is
added. **No Dartdoc is required on these app widgets** — the repository limits
Dartdoc to public API of `core` and `content`.

`CrawlStatus.build`:

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _HeaderRow(state: state, dungeon: dungeon),
      const SizedBox(height: 4),
      _ResourceRow(state: state),
    ],
  ),
)
```

**Height budget (invariant 5).** Today: `6 + 6` padding over a row whose height
is the tallest of a 14-px bar and a 14-px monospace line box (≈18) → ≈30 px.
Planned: `4 + 4` padding, header line box ≈18, 4-px gap, resource line box ≈18
→ ≈48 px. The delta is ≈18 px — one text row, the contract's entire allowance.
The vertical padding drops from 6 to 4 precisely to buy that; it is not an
aesthetic choice and must not be "tidied" back to 6. Criterion 5 is measured on
device against `2b0e0a4`.

The dungeon name arrives as `NodeId? dungeon` rather than being fetched from the
bloc inside the leaf, because the rows are a pure projection (invariant 2) and
`GameScreen.build` already holds `bloc` at `:61`. `crawl_status.dart` therefore
imports `package:residuum_core/core.dart` (for `NodeId`),
`package:residuum_content/content.dart` (for `residuumWorld`), `game_bloc.dart`
(for `GameViewState`) and `../town/town_style.dart`, and **does not import
`flutter_bloc`**. No core or content file is edited to obtain the name.

### 2. Header row

```dart
Row(
  children: [
    Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(_placeName(state, dungeon), style: mono),
      ),
    ),
    const SizedBox(width: 8),
    _BattleGlyph(state: state),
    const SizedBox(width: 4),
    Text(_battleWord(state), style: mono),
    const SizedBox(width: 8),
    if (!state.isEncounter)
      SizedBox(
        key: depthPairKey,
        width: 64,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text('${state.depth} / ${state.deepest}', style: mono),
        ),
      ),
  ],
)
```

`_placeName` is the whole naming recipe and the only place upper-casing happens:

```dart
String _placeName(GameViewState state, NodeId? dungeon) {
  if (state.isEncounter) return 'THE ROAD';
  if (dungeon == null) return '';
  return residuumWorld.nodeAt(dungeon).name.toUpperCase();
}
```

Locked consequences:

- `THE CRYPT`, `THE SEA-CAVE`, `THE RUINED KEEP`, `THE ROAD`. The name is the
  world's own, unabbreviated, upper-cased at the presentation edge; no content
  string is changed and no cached/derived name is stored anywhere.
- **The road has no depth pair at all** — the `SizedBox` is absent, not empty,
  so `find.byKey(depthPairKey)` is the observable proof of criterion 1's road
  half.
- **Null dungeon, not an encounter** keeps the depth pair and shows no place.
  This replaces the old `Depth n/m` fallback (`:319`). No production path
  reaches it — `_openCrawl` always passes a `dungeon` and road fights set
  `isEncounter` — but bare test harnesses (`craft_surfaces_test`,
  `log_drawer_test`, `battle_*`) do, and the depth pair keeps the fact those
  screens showed. An empty `Text('')` inside a `FittedBox` is safe:
  `applyBoxFit` returns zero sizes for a zero-width input rather than dividing.
- **The glyph keeps its fixed 18-px column in every state**, empty included, so
  the place cell and the depth pair do not shift when a monster appears. The
  battle word is the empty string when nothing is in sight and then occupies no
  width; the 8/4/8-px gaps remain, which is the contract's "fixed-width column".
- The header place uses `mono`, **not** `placeName`/`roomName`. Those carry
  `letterSpacing` 5 and 4; `THE RUINED KEEP` is fifteen characters, and 4 px of
  extra tracking per character is 60 px bought from the one string that is
  already the longest on the row. Upper case alone carries the header reading.

**Why the battle word is the row's only intrinsic-width text.** The place cell
is `Expanded`, so it absorbs all slack and the depth pair stays hard right. The
non-flex content is at most `8 + 18 + 4 + width('Engaged NN') + 8 + 64`. At the
device monospace advance of ≈0.6 em (8.4 px at 14 px) that is ≈186 px of the
387.4-px content width, leaving ≈201 px for the name — and `THE RUINED KEEP` is
≈126 px, so the worst realistic header does not need to scale at all, with ≈75 px
of headroom. Keeping the live count and the depth numbers at full size while the
static proper noun is the only thing that ever shrinks is the deliberate
priority. The phone-width worst-case test asserts no overflow exception in
exactly this configuration.

### 3. Resource row and the meter grammar

```dart
Row(
  children: [
    Expanded(
      child: _Meter(
        key: hpMeterKey,
        label: 'HP',
        value: shown,
        ceiling: ceiling,
        note: _condition(fraction),
      ),
    ),
    if (state.game.knownSpells.isNotEmpty) ...[
      const SizedBox(width: 12),
      Expanded(
        child: _Meter(
          key: manaMeterKey,
          label: 'Mana',
          value: state.mana,
          ceiling: state.maxMana,
          note: state.warded > 0 ? 'Ward ${state.warded}' : '',
        ),
      ),
    ],
  ],
)
```

`_Meter` is the `_SkillRow` grammar, once:

```dart
class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.value,
    required this.ceiling,
    required this.note,
    super.key,
  });

  final String label;
  final int value;
  final int ceiling;
  final String note;

  @override
  Widget build(BuildContext context) {
    final fill = ceiling == 0 ? 0.0 : (value / ceiling).clamp(0, 1).toDouble();
    return Row(
      children: [
        Expanded(
          flex: 8,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('$label $value / $ceiling', style: mono),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 8,
              backgroundColor: rule,
              valueColor: const AlwaysStoppedAnimation(ink),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(note, style: mono),
          ),
        ),
      ],
    );
  }
}
```

Locked consequences:

- **Monochrome, both meters, always**: track `rule`, fill `ink`, `minHeight: 8`,
  `ClipRRect` radius 2 — the exact values `_SkillRow` ships. The mock's red and
  blue are rejected; nothing on these rows is hue-coded. Low health is announced
  by the condition word, which reads in greyscale and aloud.
- **One numeric grammar across the whole HUD**: `HP 20 / 20`, `Mana 3 / 5`,
  `1 / 4`. Today HP prints `20 / 20` and Mana prints `Mana 3/5`; two spacing
  rules on one row is a thing the eye trips on, and the preserved fact is the
  pair, not the whitespace. No test pins `Mana 3/5` (verified by sweep).
- **The note column is `mono`, not `monoDim`.** `_SkillRow` dims its trailing
  fraction because xp progress is secondary; the condition word is the
  low-health announcement and the ward is mid-fight state. Neither may be the
  quietest thing on its row.
- **The zero-ceiling guard lives in `_Meter`** and covers both meters with one
  rule, mirroring `_SkillRow:37`. `_ResourceRow` still computes the unclamped
  `fraction = ceiling == 0 ? 0.0 : hero.hp / ceiling` for `_condition`, exactly
  as `_HitPoints:206` does, so a hero above their ceiling still reads `Steady`
  and the meter still fills to 1.0. This is preserved behaviour, not new.
- **The HP cell widens to the full row when there is no Mana cell.** Both cells
  are `Expanded`, so absence is structural: with one child the HP meter gets all
  387 px and its bar grows to ≈113 px. A half-row of dead space would read as
  missing information, and a hero learns their first spell once and permanently,
  so this is not a column that jitters.
- **The note column stays reserved when the ward is absent.** The ward lands
  mid-fight; a bar that resized at the instant a ward went up would move under
  the player's eye. The empty note costs 6/20 of a cell and buys a stable column.

#### Duplicate, do not extract

`_Meter` duplicates `_SkillRow`'s shape rather than sharing it, and
`skills_screen.dart` is not touched. `AGENTS.md` says duplicate twice before
extracting; this is the second occurrence, in a different feature, with
different inputs (label/value/ceiling/note versus skill/level/xp/cost) and a
different note style. The contract's non-goals forbid a "generic HUD framework,
theme abstraction, or second style module". A third occurrence may justify
extraction; this one does not.

### 4. Shrink-to-fit: where the scale boundary sits

**Each cell scales independently; neither row scales as one unit.** Two reasons,
both binding:

1. A `FittedBox` lays its child out unconstrained. A `Row` containing `Expanded`
   children cannot live inside one, and a meter bar that is not width-driven is
   not a meter. Wrapping a row as a unit would therefore require giving up the
   bars.
2. Per-cell scaling shrinks the long static string (the dungeon name) while the
   live numbers, the battle count and the condition word keep their size. Row-wide
   scaling shrinks the numbers to pay for the name, which is backwards.

**Overflow is structurally impossible on both rows, not merely arithmetically
unlikely.** Every child is either `Expanded`/`Flexible`-bounded, a fixed
`SizedBox`, or — on the header only — the battle word, whose maximum intrinsic
width is bounded above by `Engaged NN` and is an order of magnitude inside the
slack computed in section 2. Inside every text cell, `FittedBox(scaleDown)`
shrinks rather than clipping. **No `Text` on either row sets `overflow`,
`maxLines`, `softWrap: false` or `TextOverflow.ellipsis`** — the 64-pixel
overflow (`game_screen.dart:246-258`) and the two ellipsised-label device passes
(`:569-593`) are the recorded reasons, and the contract's ban is absolute.

Resource-row arithmetic at 411.4 logical px (content width 387.4):

| Case | Cell width | Label+numbers (flex 8) | Bar (flex 6) | Note (flex 6) |
| --- | --- | --- | --- | --- |
| HP alone (no spells known) | 387.4 | 150.2 | 112.6 | 112.6 |
| HP + Mana | 187.7 each | 70.3 | 52.7 | 52.7 |

At the device monospace advance (≈8.4 px per character at 14 px): `HP 20 / 20`
is ≈84 px and `Critical` ≈67 px, so the common no-spells case renders at full
size and the two-meter worst case scales those cells to ≈0.83 and ≈0.79 — about
an 11-px effective glyph, with the bar still ≈53 px, which is the width the
current HP bar already ships at (`:213`). These numbers are the design's
intent; the device gate decides whether 11 px reads, and bounded correction is
allowed only in the flex weights and gaps, never in the structure.

### 5. What is deleted, what survives

| Symbol | Fate |
| --- | --- |
| `_HitPoints` (`:197-329`) | Deleted entirely, class and all statics. |
| `_line` (`:259-269`) | **Deleted.** No replacement formatter, no fallback, no compatibility getter anywhere in the app. |
| `_magic` (`:296-300`) | **Deleted.** Both of its rules become structure (cell presence, note content). |
| `_whereabouts` (`:315-321`) | **Deleted.** Replaced by `_placeName` plus the separate depth-pair cell. |
| `_condition` (`:323-328`) | Survives verbatim as a private top-level function in `crawl_status.dart`. |
| `_battleWord` (`:276-280`) | Survives verbatim as a private top-level function in `crawl_status.dart`. |
| `_BattleGlyph` (`:344-375`) | Moves to `crawl_status.dart`; width 18, glyph selection and centring unchanged; inline style becomes `mono`. |

After the change, a repository-wide search must find no `_HitPoints`, no
`_line`, no `_magic`, no `_whereabouts`, no `Depth ${` fallback, and no second
place that composes a status string. `✖` (U+2716) and `◉` (U+25C9) remain the
only marks and no codepoint is added.

### 6. Edge semantics, decided

| Edge | Rule |
| --- | --- |
| `maxHp == 0` | `_ResourceRow` keeps `fraction = 0.0`; `_Meter` keeps `fill = 0.0`; the numbers read `HP 0 / 0` and the condition reads `Dead`. Two independent guards, matching `:206` and `_SkillRow:37`. |
| `hp > maxHp` | `shown = hero.hp.clamp(0, ceiling)` prints the ceiling; `fraction` stays unclamped so `_condition` still reads `Steady`; the bar clamps to 1.0. Identical to today. |
| Dead hero | `fraction <= 0` → `Dead`, bar at 0, both rows still build; `_DeathOverlay` renders above the whole `Column` (`game_screen.dart:131`) and is untouched. |
| `maxMana == 0` with a spell known | Same zero guard: bar 0.0, numbers `Mana m / 0`. Unreachable under current rules but guarded, not asserted away. |
| Mana not refilled on a revisited floor | `state.mana` is printed raw and the bar shows `mana / maxMana`; a part-full pool on floor two is a true reading, not an error. `packages/core/lib/src/engine/step.dart` is not touched. |
| Warded hero who knows no spell | **`Ward n` renders only inside the Mana cell. With no Mana cell there is no ward display.** No fact is lost: `warded` is only ever set by casting `SpellKind.ward` (`step.dart:296-303`), which requires a known spell, so the state is unreachable. If an executor finds a rules path that wards a spell-less hero, that is an escalation, not a layout decision. |
| Road fight | `THE ROAD`, no depth pair, glyph and battle word present, resource row unchanged. |
| Null dungeon, not an encounter | Empty place, depth pair present. Test-harness-only; see section 2. |

## Test plan

### New and reworked focused tests

`test/widget/hud_depth_test.dart` is renamed to
`test/widget/crawl_status_test.dart` (`git mv`): the file's subject becomes both
HUD rows and the old name would lie. Its `_pinnedSeed`, `_pumpCrawlAt` harness
and arrange/act/assert style are kept; `_pumpCrawlAt` gains optional parameters
for the staged states below (executor discretion on their exact shape).

| # | Test | Asserts | Contract criterion |
| --- | --- | --- | --- |
| 1 | names the sea-cave and the six floors it rolled | `find.text('THE SEA-CAVE')`, `find.text('1 / 6')`, existing `rolled == 6` and `isNot(deepestDepth)` | 1 |
| 2 | names the keep and the seven floors it rolled | `find.text('THE RUINED KEEP')`, `find.text('1 / 7')`, existing `rolled == 7` | 1 |
| 3 | still reads one of five in the crypt | `find.text('THE CRYPT')`, `find.text('1 / 5')` | 1 |
| 4 | a road fight names the road and shows no depth | encounter state: `find.text('THE ROAD')` findsOne, `find.byKey(depthPairKey)` findsNothing | 1 |
| 5 | the hit points read as a labelled meter with the condition | full-health crawl: `find.text('HP 20 / 20')`, `find.text('Steady')`, the `hpMeterKey` indicator's `value == 1.0` | 2 |
| 6 | a hurt hero's meter and word follow the hit points | `hp: 4` of 20: `find.text('HP 4 / 20')`, `find.text('Critical')`, indicator `value == 0.2` | 2 |
| 7 | no mana meter until the hero knows a spell | empty `knownSpells`: `find.byKey(manaMeterKey)` findsNothing, `find.textContaining('Mana')` findsNothing, `find.byKey(hpMeterKey)` findsOneWidget | 2, gate |
| 8 | the mana meter reads its own pool | `knownSpells: {'firebolt'}`, mana staged so its fraction differs from HP's: `find.text('Mana 3 / …')`, `manaMeterKey` indicator value equals `mana / maxMana` **and differs from** the `hpMeterKey` value | 2, gate |
| 9 | the ward reads beside the pool while one stands | caster with `warded: 2`: `find.text('Ward 2')` findsOneWidget | 2, gate |
| 10 | no ward when none stands | same fixture, `warded: 0`: `find.textContaining('Ward')` findsNothing | 2, gate |
| 11 | the worst case fits a phone without squeezing anything | `onAPhone`, ruined keep, bottom floor (`depth == deepest`), two monsters visible and holding reach, caster, `warded: 2`, `hp: 4`: `tester.takeException()` isNull; `THE RUINED KEEP`, `✖`, `Engaged 2`, `HP 4 / 20`, `Critical`, `Ward 2` all present; no-squeeze assertion below | 4 (widget half) |

Criterion 3 (`Engaged n` / `Watched n` / nothing, with `✖` and `◉`) is owned by
the existing engaged/watched/nothing group in
`battle_characterization_test.dart` (assertions at `:115-148`), tightened in the
migration table rather than duplicated here.

**The no-squeeze assertion** in test 11 is the strongest widget-level denial of
clipping available:

```dart
final paragraphs = tester.renderObjectList<RenderParagraph>(
  find.descendant(of: find.byType(CrawlStatus), matching: find.byType(Text)),
);
for (final paragraph in paragraphs) {
  expect(
    paragraph.size.width + 0.5,
    greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
  );
}
```

Inside a `FittedBox` the paragraph is laid out unconstrained, so its width
equals its intrinsic width and only the transform shrinks it; inside the glyph's
fixed `SizedBox` the tight width exceeds the glyph's intrinsic width. A `Text`
that was squeezed, ellipsised or clipped fails the comparison. If
`getMaxIntrinsicWidth` proves unusable in the harness, the executor falls back
to exception-plus-presence assertions and **reports the weakened proof** rather
than silently dropping it.

### Migration of every existing assertion that observes the old string

Twenty-five sites across six files, each classified. The recon and ledger record
fourteen; the planner's sweep at `2b0e0a4` found eleven more — three road pins,
six `Depth` negatives that go vacuous, and two battle-word pins now worth
tightening. Six further sites are listed at the foot of the table because they
must be confirmed green **unchanged**.

| File:line | Today | Verdict | Becomes |
| --- | --- | --- | --- |
| `widget/hud_depth_test.dart:59, 73, 81` | `textContaining('The Sea-Cave — depth 1/6')` etc. | composition pin over a real fact | rewritten as tests 1–3 above, in the renamed file |
| `widget/world_screen_test.dart:1022, 1051, 1080` | `textContaining('The road')` findsOneWidget | fact (a road fight is on screen) | `find.text('THE ROAD')` findsOneWidget |
| `widget/world_screen_test.dart:1023, 1052, 1081` | `textContaining('Depth')` findsNothing | **vacuous after the change** — nothing renders `Depth` anywhere | `find.byKey(depthPairKey)` findsNothing — the fact meant: a road has no floor |
| `widget/world_screen_test.dart:1340` | `textContaining('The Sea-Cave — depth 1/')` | composition pin over "this is the sea-cave crawl" | `find.text('THE SEA-CAVE')` |
| `widget/world_screen_test.dart:1368` | `textContaining('The Ruined Keep — depth 1/')` | same | `find.text('THE RUINED KEEP')` |
| `widget/world_screen_test.dart:1626, 1649` | `textContaining('The Sea-Cave — depth 1/')` | same | `find.text('THE SEA-CAVE')` |
| `widget/world_screen_test.dart:1687` | `textContaining('The Ruined Keep — depth 1/')`, plus `takeException` isNull | same; the overflow guard is the real subject | `find.text('THE RUINED KEEP')`; `takeException` assertion kept verbatim |
| `widget/world_screen_test.dart:1725` | `textContaining('The Sea-Cave — depth 2/6')` | fact: the total is recomputed by `loadRun`, at floor two | `find.text('2 / 6')`; keep `expect(delveDepth(seaCave, worldSeed, camp.visit), 6)` |
| `widget/world_screen_test.dart:1746-1754` | extracts `widgetList<Text>(...).single.data!` and asserts it `contains` `20 / 20`, `Steady`, `The Sea-Cave — depth 1/4` | **pure string-composition pin** — its subject is that one `Text` holds all three | **rewritten**: no `.data` extraction; four independent finders `find.text('HP 20 / 20')`, `find.text('Steady')`, `find.text('THE SEA-CAVE')`, `find.text('1 / 4')` at phone width; keep `expect(delveDepth(seaCave, 909, 1), 4)`; retitle to `shows the hit points, the condition and the place at once` |
| `widget/suspend_door_test.dart:281` | `textContaining('The Crypt — depth 2/')` | fact: the camp resumed on floor two of the crypt | `find.text('THE CRYPT')` and `find.text('2 / 5')` |
| `widget/suspend_door_test.dart:355` | `textContaining('The Crypt — depth 1/')` | fact: the new delve starts at floor one | `find.text('THE CRYPT')` and `find.text('1 / 5')` |
| `widget/suspend_door_test.dart:189` | `textContaining('Depth')` findsNothing beside `Resume the crawl (depth 2 of 5)` | **vacuous after the change** | `find.byType(GameScreen)` findsNothing |
| `widget/roster_session_test.dart:71` | `textContaining('The Crypt — depth 1/')` | fact: this hero's session opened the crypt crawl | `find.text('THE CRYPT')` |
| `widget/boot_wiring_test.dart:76` | `textContaining('The Crypt — depth 1/')` | fact: booting inside lands in the crypt crawl | `find.text('THE CRYPT')`; keep `find.text('The crawl resumes.')` |
| `widget/boot_wiring_test.dart:145, 161` | `textContaining('Depth')` findsNothing | **vacuous after the change** | `find.byType(GameScreen)` findsNothing |
| `battle_characterization_test.dart:116, 132` | `textContaining('Engaged 1')`, `textContaining('Watched 1')` | fact, and it now has its own widget | tightened to `find.text('Engaged 1')` / `find.text('Watched 1')` |
| `battle_characterization_test.dart:117, 133, 147, 148` | `textContaining(...)` findsNothing negatives | fact, still meaningful | unchanged; must stay green |
| `battle_view_test.dart:290, 557` | `textContaining('Engaged')` findsOneWidget | fact | **unchanged**; confirm green (the word is still a `Text` containing `Engaged`) |

Whole files that must pass **unchanged**: `game_bloc_test.dart`,
`world_bloc_test.dart`, `town_bloc_test.dart`, `character_screen_test.dart`,
`pack_screen_test.dart`, `craft_surfaces_test.dart`, `back_guard_test.dart`,
`log_drawer_test.dart` (its peek/controls geometry is relative and self-consistent
within each pump), and every `dungeon_*`/`palette` suite.

No test may assert source text, count widgets as a proxy for layout, or re-pin a
new concatenated string. No golden images (`AGENTS.md`).

### What only the device can prove

Stated plainly rather than proxied:

- **Criterion 4** (nothing ellipsised or clipped at phone width, worst case) is
  *partly* widget-provable — `onAPhone` gives a real 411.4-px surface, a
  `RenderFlex` overflow surfaces through `tester.takeException()`, and the
  no-squeeze assertion denies paragraph clipping. It is **not fully** provable:
  `flutter_test` renders with its own bundled font, so glyph advances, fallback
  behaviour and the legibility of a scaled-down cell are device facts. The
  device gate owns the final answer.
- **Criterion 5** (no more than one text row of viewport lost versus `2b0e0a4`)
  is device-only. The map is `Expanded`, so the crawl never overflows and no
  widget test can fail on height; only a measured comparison of two builds
  answers it.
- **Criterion 9** (the colour and greyscale frame set, plus Unit 8's folded
  frames and its two open questions) is device-only by definition.
- **Criterion 6** (nothing hue-only) is argued structurally — both fills are
  `ink` on `rule`, every state is also a word, a number or a glyph — and
  confirmed by the greyscale twins in the device gate.

## Integrated proof ownership

The executor owns its own Red/Green, focused tests, touched-file formatting,
package analysis and — because it is the unit's only writer and the change
touches a widget observed by the whole widget suite — one full
`flutter test` from `packages/app` before handing off. Exact commands are in the
brief.

After the task receipt is accepted, Main re-runs the integrated gate from
`packages/app`:

```sh
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Main then audits the diff: changes confined to
`packages/app/lib/game/crawl_status.dart`,
`packages/app/lib/game/game_screen.dart`, the seven named test files (one of
them renamed), plus architect-owned Unit 9 records. Zero changes under
`packages/core`, `packages/content`, `packages/app/lib/save`,
`packages/app/lib/main.dart`, town/world screens, dependency/generated/asset
files. No new asset declaration, no new mark codepoint, no surviving
`_HitPoints`/`_line`/`_magic`/`_whereabouts`, no `TextOverflow.ellipsis` on the
new rows, no edit to `skills_screen.dart`.

Main then runs one integrated acceptance review against `CONTRACT.md`, checking
plan conformance, the fact-preservation list in invariant 3 item by item, the
deleted formatter, test-migration quality (no re-pinned composition, no vacuous
negatives left behind), the height budget, and greyscale accessibility. Findings
are corrected on the feature checkout with focused re-proof plus whichever full
command the correction's surface traverses.

Only a closed acceptance review proceeds to the device gate. That gate is
user-started (`Medium_Phone`; the AVD segfaults when launched from a tool
shell), carries Unit 8's criterion 9 frames, and backs up **both** device save
slots from `app_flutter/save.json` — never `files/save.json` — verifying them
byte-identical afterward. Multi-step capture is delegated to bounded
`flow-evidence-verifier` capsules. Frame list: `CONTRACT.md:168-178`.

## Global escalation boundary

Stop and report to Main/architect rather than improvising if:

- branch/worktree preconditions do not match, or a planned seam has changed
  since `2b0e0a4`;
- a fact on the current status line has nowhere to land on the two rows without
  a third row, a new codepoint, or reopening frozen prose;
- the header cannot obtain the node name from `residuumWorld.nodeAt(dungeon)`
  without a core/content edit, a bloc change, or a stored/derived name;
- a rules path is found that sets `warded` for a hero with no known spell;
- the two rows cannot stay within one extra text row of height without
  shrinking a font below the locked styles or moving a fact off the rows;
- a meter cannot read monochrome, or any state ends up carried by hue;
- `getMaxIntrinsicWidth`/`takeException` cannot express the no-squeeze proof, so
  criterion 4's widget half would be weaker than planned;
- an existing test fails for a preserved behaviour rather than an obsolete
  composition assumption;
- the work appears to require `packages/core`, `packages/content`, `main.dart`,
  `skills_screen.dart`, a save/dependency/asset change, a new control or
  relabelling, or implementation on `main`.

**Executor discretion** covers: private helper and test-helper names, the exact
staging of test fixtures (seeds, monster placement, `copyWith` shape), whether
`_placeName`/`_battleWord`/`_condition` are top-level privates or statics,
import ordering, and whether the device-history rationale from
`game_screen.dart:246-258` is carried onto the new widget as a comment (allowed,
never required — the repository limits Dartdoc to `core`/`content` public API).

It does **not** cover: the public `CrawlStatus` signature or the three key
constants, the file split, row structure, flex weights, gaps, padding, styles,
colours, upper-casing, the numeric grammar, cell presence rules, the ward rule,
which helpers die, the test verdicts in the migration table, or any frozen
wording.

## Plan quality gate

- **COR — PASS.** Ownership is unchanged: `GameBloc` keeps every value, the rows
  are a pure projection with no event, no gesture and no state of their own, and
  `dungeon` is passed in rather than fetched a second time from the bloc. Every
  fact in invariant 3 has a named home: hit points and ceiling in the HP meter's
  numbers, the condition in its note, the place and `The road` in the header's
  place cell, depth and deepest in the depth pair, the battle word and count
  beside the reused glyph, the pool under the same known-spells gate, the ward
  as the Mana cell's note. Edge cases are decided explicitly rather than
  inherited by accident — zero ceilings guarded twice, the clamp and the
  unclamped condition input both preserved verbatim, the null-dungeon harness
  path kept, the ward's unreachable case argued from `step.dart:296-303` and
  made an escalation rather than a silent drop. Overflow is prevented
  structurally, not by hoping.
- **TTC — PASS.** Expected Red: tests 1–4 fail on `THE SEA-CAVE`/`THE ROAD`
  because the header does not exist; tests 5–10 fail on missing `hpMeterKey`/
  `manaMeterKey` and on `HP 20 / 20` because there is no meter; test 11 fails to
  compile until `CrawlStatus` exists. Every migrated assertion in the table fails
  the moment `_line` changes, which is the migration's own Red. Both gates have a
  positive and a negative case (spell known / not known, warded / not warded),
  the two meters are proved to read *different* pools, and the boundary between
  `Wounded` and `Critical` is staged at `hp: 4` of 20 rather than 5 because
  `5/20 == 0.25` is not `< 0.25`. Three vacuous `Depth` negatives are rewritten
  to the fact they meant instead of being left as green noise. The limits of
  widget proof are stated rather than proxied.
- **CRF — PASS.** One new file with one public widget and three keys; four
  file-private widgets and three file-private functions; one formatter deleted
  and none introduced. `_SkillRow` is duplicated once, deliberately, under the
  repository's own duplicate-twice rule, and its own screen is untouched. No HUD
  framework, no style module, no shared-meter abstraction, no compatibility
  shim, no optional constructor default. `game_screen.dart` shrinks by 133 lines
  and gains one call. `_BattleGlyph` moves to the only file that uses it. The
  rows allocate nothing per frame beyond the widgets they already are.
- **SEC — SKIP (no new trust boundary).** Unit 9 is local Flutter presentation
  over existing in-process immutable state. It adds no network call, no external
  input, no deserialization, no persistence, no privilege, no secret, no asset
  and no executable data. Save bytes are touched only by the device gate's
  backup discipline, which is an operational gate over unchanged product code.

Residual risks deliberately left to implementation and device evidence:

1. In the two-meter worst case the label/numbers and note cells scale to ≈0.8,
   an effective ≈11-px glyph. Only the device says whether that reads. Bounded
   correction is allowed in the flex weights and the 6/12-px gaps; the structure,
   styles and wording are not correction surface.
2. The ≈18-px height delta is computed from default monospace line metrics. The
   device measurement for criterion 5 is authoritative; if it exceeds one text
   row, the correction is the 4-px inner gap, then the outer vertical padding —
   not a third row and not a smaller font.
3. `flutter_test`'s bundled font is not the device's monospace, so widget-level
   fit is indicative. This is why the contract keeps a device gate and why the
   plan refuses to claim criterion 4 from the suite alone.
4. `RenderParagraph.getMaxIntrinsicWidth` after layout is the one slightly
   unusual assertion in the suite; the brief names its fallback and requires the
   weakening to be reported.

None is an unresolved product or architecture decision.

## Planner receipt

- **STATUS:** READY — execution-grade; implementation remains separately
  unauthorized until explicit user approval of this plan.
- **Source/dirty assumption:** `2b0e0a4` on `main`, in sync with `origin/main`;
  `packages/` clean; architect-owned `LEDGER.md`, `RESUME.md` and
  `units/unit-9/` dirty/untracked and preserved. Implementation branches to
  `residuum-visual-reboot-9`, never writes on `main`.
- **Tasks:** `plan-tasks/01-two-row-crawl-status.md` — single capsule, no
  intra-unit dependencies — then Main's integrated gates, acceptance review and
  the user-started device gate.
- **Quality:** COR/TTC/CRF PASS; SEC SKIP for no trust-boundary change.
- **Next action:** Main validates this receipt, presents the plan for explicit
  user approval, and only after approval creates the non-`main` feature branch
  and dispatches task 01 to a fresh non-isolated `flow-plan-executor`.
