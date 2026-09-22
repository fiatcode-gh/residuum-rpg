# Unit 14 — Type, Palette and Surface Authority: Execution Plan

Status: **execution-grade; approved by the architect 2026-09-18 with five
amendments A1–A5, plus A6 ruled during Task 01 execution (all recorded
below). Planning only.** The Unit 14 contract is
approved (2026-09-18, monospace retired outright). The user must separately
approve this plan before any production execution.

Source base: `residuum-visual-reboot-13` at **`5ac1a49`**, which the contract
now records. `03e8c0c` is `HEAD~1`; `5ac1a49` ("docs: approve unit fourteen and
retire monospace") sits on top of it and is docs-only — `LEDGER.md`,
`RESUME.md`, `unit-13/PARITY-MATRIX.md`, `unit-13/ROADMAP.md`,
`unit-13/VISUAL-SYSTEM.md`, `unit-14/CONTRACT.md`. No production seam moved
between the two, so every `file:line` below was re-read at `5ac1a49` and is
equally valid at `03e8c0c`.

Planning dirty-state assumption, recorded 2026-09-18: the working tree is
**clean** (`git status --porcelain` empty). `main` is at `907a4a8`; `U13.1`
(`e8bcf29`, "fix: clip the dungeon scene to its own viewport") touched
`dungeon_scene.dart` only. This planner performed no git mutation and no
production or test edit; every seam named here was verified by reading the
current file. A revision change requires targeted revalidation of the seams
named below, not replanning.

Derived from the approved `CONTRACT.md`, `unit-13/VISUAL-SYSTEM.md` §1–4 and §9,
`unit-13/recon.md`, `unit-13/PARITY-AUDIT.md` gaps 1.2 / 2.8 / 5.4 / 6.4 / 7.5 /
9.5 / 10.7, `unit-13/PARITY-MATRIX.md`, the approved mock, and first-hand reads
of every file named in the tables below, plus **direct metadata inspection of
the candidate font binaries** and **direct inspection of the Flutter 3.47.4 SDK's
test host**.

---

## Findings the architect must read before approving

Nine facts from recon refine or contradict the contract. None is worked around
silently; each is either settled below as a locked decision or named as an
escalation. **The architect ruled on five of them on 2026-09-18** — see
§"Architect amendments A1–A6" immediately after F9.

### F1 — There are sixty `fontFamily: 'monospace'` literals, not "roughly fifty", plus four prose mentions

Verified census at `5ac1a49`:

| file | literals |
|---|---:|
| `lib/game/crawl_style.dart` | 16 |
| `lib/world/world_screen.dart` | 10 |
| `lib/town/roster_screen.dart` | 8 |
| `lib/town/town_style.dart` | 7 |
| `lib/world/world_route_diagram.dart` | 6 |
| `lib/town/character_screen.dart` | 4 |
| `lib/main.dart` | 3 |
| `lib/game/pack_screen.dart` | 2 |
| `lib/game/dungeon_scene.dart` | 2 |
| `lib/town/gear_screen.dart` | 1 |
| `lib/town/forge_screen.dart` | 1 |
| **total** | **60** |

Four further occurrences are dartdoc prose, not styles, and AC2's grep for the
quoted literal would miss them: `lib/game/battle_view.dart:229`,
`lib/town/town_style.dart:29`, `lib/town/town_style.dart:203`,
`lib/main.dart:144`. **All four are rewritten too** — the two `town_style.dart`
ones are the device-metric dartdocs the contract's Traps section protects, and
their warning is preserved verbatim minus the word.

### F2 — Spectral carries `tnum`, and its default figures are already tabular and lining

Measured from `ofl/spectral/Spectral-Regular.ttf`, `-Medium.ttf`,
`-SemiBold.ttf` (GSUB `FeatureList`, `cmap`, `hmtx`, `glyf`, `OS/2`, `hhea`):

- GSUB features include `tnum`, `lnum`, `onum`, `pnum`, `zero`, `smcp`, `c2sc`,
  `case`, `frac`, `sups`, `sinf`, `ss01`–`ss06`.
- **Default digits are already uniform-width**: every digit `0`–`9` has advance
  exactly `0.500 em` (Regular), `0.514 em` (Medium), `0.536 em` (SemiBold).
- Digit `yMin`/`yMax` sit in `-10..0` / `660..670` — **lining**, not oldstyle.

So `FontFeature.tabularFigures()` is available *and* is a no-op against the
default, which makes applying it universally free. **No fallback to a
fixed-width slot is needed for the font's sake** — the fixed-width slots this
unit adds exist for a different reason (F7).

**EB Garamond** also carries `tnum` and `lnum`, but its **default figures are
oldstyle** (`yMin` from `-38` to `-3`, `yMax` from `626` to `643`). Locked
consequence: the display roles carry `FontFeature.liningFigures()` **and**
`FontFeature.tabularFigures()` so an oldstyle digit can never appear in a
title, even though no display string contains a digit today.

### F3 — The faces are missing exactly twelve of the app's marks, and seven of those are defined in `packages/core`

Parsed `cmap` coverage of the app's complete non-ASCII inventory (derived by
scanning every `.dart` file in all three packages, not from the contract's hand
list). **Twelve marks are absent from both Spectral and EB Garamond:**

| mark | codepoint | defined at | drawn on |
|---|---|---|---|
| `◎` | U+25CE | `lib/game/log_line.dart:7` | expanded log, log peek |
| `⇅` | U+21C5 | `lib/game/log_line.dart:9` | expanded log |
| `✕` | U+2715 | `lib/game/log_line.dart:10` | expanded log |
| `✖` | U+2716 | `lib/game/crawl_status.dart:186` | crawl status, engaged |
| `◉` | U+25C9 | `lib/game/crawl_status.dart:188` | crawl status, watched |
| `※` | U+203B | `core/lib/src/loot/rarity.dart:15` | every item row, Epic |
| `★` | U+2605 | `core/lib/src/loot/rarity.dart:16` | every item row, Legendary |
| `▮` | U+25AE | `core/lib/src/craft/material.dart:29` | material rows, ingot |
| `✿` | U+273F | `core/lib/src/craft/material.dart:32`, `gather_node.dart:37` | material rows, herb patch |
| `✳` | U+2733 | `core/lib/src/magic/spell.dart:95` | **spell chip labels**, spell rows |
| `✚` | U+271A | `core/lib/src/magic/spell.dart:96` | **spell chip labels**, spell rows |
| `⛒` | U+26D2 | `core/lib/src/magic/spell.dart:97` | **spell chip labels**, spell rows |

Everything else the contract lists is covered: `← → † ■ ▲ ▼ ◆ § ‡ · ⁰`–`⁹`
`− ? < > › ↓ × — – △ ◇` and the full ASCII set.

**This does not regress anything.** Today `'monospace'` is *unregistered* in the
widget-test host and resolves to the test font, and on Android it resolves to
Roboto Mono, which also lacks all twelve (verified: the Flutter artifact cache's
`Roboto-Regular.ttf` covers none of them). Those twelve marks already render
from the platform's symbol fallback today and will continue to. **No
`fontFamilyFallback` is declared**, precisely so the platform chain that renders
them is left exactly as it is.

**The contradiction the architect must resolve is narrower than "glyph
coverage":** the contract mandates a pre-cutover glyph check, and seven of the
twelve gaps are `const` markings in `packages/core`, which the contract's
Boundaries forbid this unit from touching. This plan therefore:

1. changes **no** mark, in either package;
2. records the twelve as a known, pre-existing platform-fallback set, proved by
   an automated coverage test (Task 01) so a future font swap that *loses* a
   covered mark fails loudly;
3. names the one place where a fallback glyph has a **measurement**
   consequence rather than a cosmetic one — `✳ ✚ ⛒` appear inside crawl action
   chip labels, which `_fitFor` measures (`crawl_action_row.dart:154-163`), so
   their host-dependent advance is a bounded risk to the dp agreement claim
   (see the dp gate, R2);
4. escalates to the architect **only** if the device pass shows tofu, or if
   worst legal combat breaches 600 dp on device.

**Settled by the architect 2026-09-18 (A2):** exactly as proposed above. No
mark changes in either package; the twelve are a recorded pre-existing
platform-fallback set with the Task 01 coverage test as their proof; U16
retires them. This is no longer an open contradiction.

The permanent fix is already scheduled: U16 owns the ten log pictograms and the
spell medallions, which retire the marks entirely.

### F4 — `flutter test` forces the Ahem test font, and bundling alone will *not* close U13.1's divergence

`packages/flutter_tools/lib/src/test/flutter_tester_device.dart:119-120` passes
**both** `--use-test-fonts` **and `--disable-asset-fonts`** to `flutter_tester`
on every `flutter test` run, and
`packages/flutter_tools/lib/src/test/font_config_manager.dart` restricts
fontconfig fallback to the Flutter artifact cache. The engine's own help text
for the first flag: "make font resolution **default** to the Ahem test font".

The second flag is the decisive one, and the architect verified it at source on
2026-09-18: `--disable-asset-fonts` means pubspec-declared fonts **cannot**
reach the test host at all, however they are declared. It is not that they
merely fail to register — the asset font path is switched off.

Ahem's advance is exactly `1.000 em` and its line box exactly `1.000 em`. That
is the whole of U13.1's 208.43 dp vs 285.33 dp divergence: today every style
names the unregistered family `'monospace'`, so the test host measures at
1.0 em/char while the device measures Roboto Mono at ~0.6 em/char.

`--use-test-fonts` changes the **default**, not the resolution of a family
registered at runtime through `FontLoader`, which loads bytes the test itself
supplies and is unaffected by `--disable-asset-fonts`. So:

> **Bundling the faces closes the divergence only if the test suite registers
> them with a `FontLoader`.** Without that step the test host falls straight
> back to Ahem, the widget-test dp figures stay divorced from device, and AC7
> cannot be honestly claimed. `--disable-asset-fonts` makes this certain rather
> than likely.

Task 01 therefore ships `test/flutter_test_config.dart` (Flutter's per-directory
`testExecutable` hook, which runs once per test isolate and so covers the whole
suite) plus `test/support/fonts.dart`, which reads the font bytes through
`rootBundle.load` and hands them to `FontLoader`. This is a locked decision,
not an option, and Task 01's group 1 assertion is what proves it worked.

One consequence to hand the executor rather than let it stall them:
`--disable-asset-fonts` switches off the engine's *consumption* of the font
manifest, not the tool's *production* of the asset bundle, so
`rootBundle.load('assets/fonts/Spectral-Regular.ttf')` still resolves — a font
file declared under `fonts:` is a bundle member, which is exactly how the
long-standing `loadAppFonts` idiom works under `flutter test`. **If it throws
anyway**, the fix is to list the three `.ttf` paths under `assets:` as well, so
they are unambiguously bundle members; that is additive, changes nothing at
runtime, and is pre-authorised for Task 01 rather than an escalation.

### F5 — Spectral's own line box is 1.522 em, which alone would breach the dp ceiling

Measured `hhea`/`OS/2`: Spectral `ascender 1059`, `descender -463`,
`lineGap 0`, `unitsPerEm 1000` → **default line height 1.5220 em** for all three
weights. EB Garamond: `1.3050 em`. Roboto (for comparison): `1.1719 em`. The
device's current `'monospace'` measures ~`1.32 em` (recorded in Unit 12's
correction C1 as "1.32 em device metrics").

Left alone, that is **+15% on every text row in the application**. Worst legal
combat measured 580.95 dp of chrome against a 600 dp ceiling; +15% puts it at
roughly 668 dp — over, with the map below 7 rows of sight.

> **Locked: every type role in the token module carries an explicit `height`.**
> Chrome height becomes a plan decision rather than a font accident. This single
> decision is what keeps the dp budget; it is not tuning and it is not optional.

Spectral's real ink extent is `0.990 em` (`inkTop 0.750`, `inkBottom -0.240`
over the full Latin set), so a `height` of 1.00 is ink-safe for single-line
glyph cells and 1.20–1.35 is comfortable for labels and prose.

### F6 — Spectral is 15–30% narrower than monospace in mixed case and 12% wider in caps

Mean advance over real app strings, Spectral Regular vs the 0.600 em monospace
cell:

| string | Spectral | monospace | delta |
|---|---:|---:|---:|
| `Gear, spells, skills, and pack` | 12.44 em | 18.00 em | −31% |
| `Health   14 / 20` | 6.51 em | 9.60 em | −32% |
| `Drink (2)` | 3.88 em | 5.40 em | −28% |
| `Firebolt` | 3.56 em | 4.80 em | −26% |
| `You have gone down twice.` | 12.07 em | 15.00 em | −20% |
| `Descend >` | 4.54 em | 5.40 em | −16% |
| `STONEBRIDGE` | 7.37 em | 6.60 em | **+12%** |

Caps mean advance is `0.707 em` (Spectral) and `0.659 em` (EB Garamond) against
monospace's `0.600 em`. Every all-caps site therefore *grows*, and the app's
all-caps sites are exactly the display register plus `Heading`, plus the world
route diagram's state labels — which is the one place a fixed-width clip box
meets a wider face (F8).

Spectral's x-height is `0.450 em` against Roboto Mono's `~0.528 em`, so Spectral
at nominal size *S* reads as monospace at roughly `0.85·S`. The type scale below
raises the small rungs by 1 px to compensate and pays for it out of the
`height` saving from F5.

### F7 — Space-padded label columns are a monospace-only device and break in a proportional face

Six sites align a value column by padding the label string with spaces:

| site | strings |
|---|---|
| `lib/town/town_screen.dart:76-80` | `Health   n / n`, `Carried  n gold`, `Banked   n gold` |
| `lib/town/town_style.dart:186-187` (`Purse`) | `Carried  n gold`, `Banked   n gold` |
| `lib/town/character_screen.dart:147-152` | `Attack   n-n`, `Armour   n`, `Dodge    n%`, `Speed    n`, `Health   n/n`, `Mana     n` |
| `lib/town/character_screen.dart:40-44` | `Spells known    n`, `Skills trained  n/n` |
| `lib/world/world_screen.dart:196-198` | `Health   n / n`, `Carried  n gold`, `Banked   n gold` |
| `lib/town/inn_screen.dart:45-46` | `Health   n / n`, `Price    n gold` |

`town_style.dart:202-205`'s own dartdoc already records that a padded string
"aligns on the desktop and steps sideways on the phone. A device pass caught
exactly that." In a proportional face they never align at all. The contract is
explicit that this is U14's business: *"Where digits must not jitter — the
meters, the stat columns, the depth pair, prices — use the text face's tabular
figures, and a fixed-width slot where a whole column must hold still."*

Five of the six were inside Boundaries; `inn_screen.dart:45-46` was not,
because the file declares no font family and the contract's "may change" list
did not reach it.

**Settled by the architect 2026-09-18 (A3): `inn_screen.dart:45-46` is
authorised and the contract's boundary is widened by those two lines.** All
six sites convert in Task 05. The mechanism is identical and leaving one town
screen with drifting columns while five are fixed was the worse of the two
extremes. Residual R6 is closed, not carried.

### F8 — The world route diagram is the only fixed-width clip box the new face threatens

`world_route_diagram.dart:25-26` fixes `_nodeWidth = 120.0`, `_nodeHeight = 72.0`
and every label inside renders with `overflow: TextOverflow.clip`, `maxLines: 1`
(`:198-221`). The widest string is `NO ROAD FROM HERE` / `TRAVEL IN PROGRESS`
in all caps at 9 px. At Spectral's 0.707 em caps advance:
`TRAVEL IN PROGRESS` ≈ 108 dp at 9 px against a 120 dp box — it fits, with
margin, but only at 9 px. Raising that rung to 10 px puts it at ~118 dp, inside
2 dp of clipping. **Locked: the micro rung stays at 9 px** and Task 06 proves
no diagram paragraph exceeds its box.

### F9 — There are ten unthemed stock-control families, not four, and one theme covers all of them

`main.dart:81-85` and `main.dart:169-173` build the only two `MaterialApp`
themes as `ThemeData(brightness: dark, scaffoldBackgroundColor: Color(0xFF0E1014),
useMaterial3: true)`. Nothing else is set, so Material 3's default `primary`
reaches every control that does not colour itself. Complete census:

| # | site | control | contract's four |
|---|---|---|---|
| 1 | `town/character_screen.dart:50,64,78,92` | 4 × `FilledButton` (Gear/Spells/Skills/Pack) | **named** |
| 2 | `game/pack_screen.dart:103` | `ChoiceChip` × 6 filters | **named** |
| 3 | `town/town_style.dart:375` (`Commit`) | `FilledButton` — Forge `Smelt`, and inn/bank/merchant/alchemist/roster commits | **named (Smelt)** |
| 4 | `town/town_style.dart:157` (`ItemRow`) | `FilledButton` — Tavern `Ask`, and every merchant/bank/alchemist/tavern row | **named (Ask)** |
| 5 | `world/world_screen.dart:551` (`WorldDoor`) | `FilledButton` | not named |
| 6 | `town/gear_screen.dart:73` | `FilledButton` `Take off` | not named |
| 7 | `game/pack_screen.dart:286` | `TextButton` — Drink/Read/Wear/Drop | not named |
| 8 | `town/roster_screen.dart:133,238` and `world/world_screen.dart:133,478` | 4 × `AlertDialog` + 8 × `TextButton` | not named |
| 9 | `town/roster_screen.dart:243` | `TextField` (cursor, selection, focused border) | not named |
| 10 | `main.dart:127` | `FilledButton` `Begin fresh` | not named |

Already safe and unchanged: `forge_screen.dart:163`, `roster_screen.dart:313`,
`town_screen.dart:205` (all `foregroundColor: ink`), `skills_screen.dart:49-53`
and `crawl_status.dart:148-153` (both pass `backgroundColor`/`valueColor`), the
three `AppBar`s (all pass `backgroundColor: panel, foregroundColor: ink`), and
everything inside the crawl's existing `crawlTheme`.

---

## Architect amendments A1–A15

A1–A5 were ruled on 2026-09-18 when the plan was accepted. **A6 was ruled
during Task 01**, after that task's evidence exposed a defect in this plan's
own AC4 specification. Each is folded into the section it governs; this is the
index.

| # | ruling | where it lands |
|---|---|---|
| A1 | **One `residuumTheme` at six roots is accepted** — settled by the architect, no longer an interpretation awaiting a ruling. The two-line reversal note is kept for the record | §"The theme decision, settled" |
| A2 | **Change no mark, in either package.** The twelve uncovered marks are a recorded pre-existing platform-fallback set with the Task 01 coverage test as their proof; U16 retires them; escalate only on device tofu or a 600 dp breach | F3 |
| A3 | **`inn_screen.dart:45-46` is authorised** and the contract's boundary is widened by those two lines. All six padded-column sites convert in Task 05; residual R6 is closed | F7, Task 05, Residual risks |
| A4 | **The alias strategy is transitional, not the end state.** Aliases stay through Tasks 01–07 because they are what makes seven compiling steps possible, but a maintainer six months out must not have to work out whether `ink`, `crawlInk` and the shared token are one value. **New Task 08**: a mechanical rename leaf that deletes every alias which only re-names a shared token, keeps every declaration that names a seam concept the shared module does not have, and repoints all consumers through the language server | new §"Task 08", the execution graph, the ownership matrix, the slice table, AC3's closure, R4 |
| A5 | **Base revision is `5ac1a49`** throughout; the contract already records it | the header |
| A6 | **AC4's fill-versus-surface luminance-ratio assertion is struck, not retuned.** This plan asked each control family to prove its rendered fill differed from its surface by ≥ 1.5 : 1. It is unsatisfiable against this deliberately low-contrast ladder under either reading, and the obvious executor response — lowering the threshold until it passes — would turn the assertion into decoration. AC4's spec is now the two assertions that carry its content. A control's boundary comes from its 1 dp `rule` border, not from fill-against-surface contrast | §"Why there is no third…" with the arithmetic, the Task 01 and Task 04 proof specs, the AC4 and AC8 coverage rows, the TTC gate, R5, briefs 01 and 04 |
| A7 | **`crawlChevron` becomes a `const` alias of a new eighteenth role, `textGlyphDim`.** This plan made it `final crawlChevron = textGlyph.copyWith(color: dim)`. `copyWith` is not const-evaluable, and **all four of its consumers sit in `const` contexts** — `battle_view.dart:55` (inside a `const Opacity`), `:70`, `:84`, and `log_drawer.dart:80`, which this plan's Task 02 brief never named and which sits in that brief's do-not-edit list. **The app package does not compile with a `final` there**, so this was not a style question. `tokens.dart` already pairs every dim sibling as a separate `const` literal; the `copyWith` was the odd one out. Ruled during Task 02's execution | the type-role table, the `copyWith` rule, Task 01's spec and brief, briefs 02 and 08, the AC coverage rows, every role count |
| A8 | **The colour-only-`copyWith` rule is struck outright, and its last three mandates are retired.** A7 fixed one instance; the rule itself was the defect. `textDetail` and `textMicro` flip to ink primaries and gain `textDetailDim` and `textMicroDim` — **twenty roles** — so brief 06's three `copyWith` mandates become straight aliases. Ruled by the architect and **landed as a standalone `sonic` leaf between Tasks 02 and 03**, rather than deferred into Task 06, because carrying a known-unsound rule through three more tasks is how a third instance gets found at Gate B. Behaviour-neutral: `crawlTokenWord` and `crawlDetail` repoint to the dim sibling and nothing changes on screen | the type-role table, the `copyWith` rule, briefs 03, 04, 06 and 07, §"A8, ruled" |
| A9 | **Every role carries an explicit `textBaseline`.** An `inherit: false` style with a null `textBaseline` crashes any `TextField` mounted under the theme: `TextStyle.merge` short-circuits on a non-inheriting style (`text_style.dart:1079`, `if (!other.inherit) return other;`), discarding `titleMedium`'s baseline, and `InputDecorator` then reads `labelStyle.textBaseline!` unconditionally (`input_decorator.dart:2327`). Found by Task 04 when the roster's name dialog became the first `TextField` ever mounted under `residuumTheme`, breaking four pre-existing `roster_screen_test.dart` cases. **The fix is the hole, not the one field:** patching `inputDecorationTheme` alone would leave the trap armed for the next role meeting a widget that reads `textBaseline!`, invisibly. The module already sets `inherit`, family, height, colour and features explicitly so nothing leaks from an ambient theme, then left the baseline to be inherited from a style `inherit: false` guarantees is never consulted. Twenty roles gain `TextBaseline.alphabetic`; the invariant sweep gains a sixth check | `tokens.dart`, the role invariants, Task 01's spec and brief, brief 04 |
| A10 | **Four test files pin the world screen's three padded rows, not two.** Brief 06 names `suspend_door_test.dart:119` and `world_screen_test.dart` and lists `roster_session_test.dart` as must-stay-green-unedited — which is false the moment Task 06's conversion lands. Verified at dispatch on `72fbc54`: `suspend_door_test.dart:93` and `:119`, `world_screen_test.dart:625`, `roster_session_test.dart:50,142,162,192,208`, `roster_refusal_test.dart:93,112`. **`roster_refusal_test.dart` and `roster_session_test.dart` join Task 06's owned files**, with the edit boundary limited strictly to those `Carried  N gold` assertions; each is rewritten to the behaviour it defends — the world screen states the hero's carried gold as a label and a value — using Task 05's idiom (`67513bb`), never re-pinned to a new padded literal. Ruled by the architect at Task 06's dispatch; it is a consequence of Task 05's conversion boundary, not a new decision | brief 06's "Owned files", "Must stay green" and "Two expected rewrites" |
| A11 | **Brief 07's prose-sweep list is stale; the surviving hits moved.** `battle_view.dart:229`, `town_style.dart:29` and `:203` and `main.dart:144` were all cleared by their owning tasks. The grep on `fb55622` returns five hits in `packages/app/lib`: `dungeon_scene.dart:432` and `:441` (the two glyph paints, Task 07's main change) plus **`tokens.dart:40-41` and `surfaces.dart:80`** — dartdoc Tasks 01 and 05 wrote while retiring the face. Those three lines are the sweep and Task 07 owns them, **dartdoc prose only**; the padded-column warning they carry survives, the word goes. This is not optional: Task 07's own CI gate greps `monospace` across `lib --include='*.dart'`, which matches comments, so the gate cannot be green on its own tree until they are rewritten. Brief 07's "the sweep must not disturb `tokens.dart`" is rescoped to behaviour — no declaration, value or role changes, and `type_authority_test.dart` stays green unedited as proof | brief 07's "The sweep", "Owned files" and "Must stay green" |
| A12 | **Brief 06's group 1 does not pass before the change; the claim was an artefact of the test host.** The brief said the no-clipping proof "is expected to pass before and after". Task 06 measured it **Red on both scenarios** — `TRAVEL IN PROGRESS` at 110 dp against a 110 dp box, `DANGER n/100` at 128 against 128. Root cause: `'monospace'` is never registered with the widget-test host (`test/support/fonts.dart` loads only `textFace` and `displayFace`), so `--use-test-fonts` substitutes Ahem for it and its advance clips at any rung. Green on the migrated tree at 98.79 dp / 100.17 dp against the 120 dp box. **The proof stands and no assertion changed** — it is a real regression guard after the change — but the "both sides" reading was wrong, and the general trap is the one U13.1 already recorded: an unregistered family in a widget test is measured as Ahem, not as the face the device will use | brief 06's "Red proof" group 1; the test's own doc comment |
| A13 | **Brief 08's starting condition is pre-A7 and one mapping note is pre-A8.** The brief says `crawl_style.dart` holds "26 alias declarations plus 5 kept type declarations"; after A7 moved `crawlChevron` to the delete list the true figures are **27 deleted and 4 kept**, matching the brief's own tables and its grep expectation 2. The 35-declaration total is unchanged. The brief's note that `crawlTokenWord` and `crawlDetail` both alias `textDetail` is pre-A8: both now alias **`textDetailDim`**, which is what A8 ruled, and two names collapsing onto one rung is expected. The architect counted both seams at `2763663` before dispatch and membership otherwise matches the tables exactly, so the brief's stop-and-report on membership does not fire. One addition the brief predates: `town_style.dart` also imports `surfaces.dart show LabelledValue` (Task 05), which stays; only the `tokens.dart` prefix is dropped | brief 08's "Starting condition" and its `textDetail` note |
| A14 | **A deleted name inside a test description follows the rename.** Brief 08 says a `test/` hunk may only be an identifier substitution or an `import` line, and on a literal reading a `testWidgets` description string is neither — so `'the spells overflow sheet renders on crawlPanel'` becoming `'… on panel'` looks like an escalation. **It is not; the edit stays.** A description naming a symbol that no longer exists is a stale name, and this is the same rename reaching the same word in prose. The rule exists to catch a rename laundering a behavioural change, and a description carries no behaviour. Every other test hunk must still be a substitution, an import, or the one required comment correction | brief 08's "Escalate, do not decide", first bullet |
| A15 | **Device chrome is measured against the post-`SafeArea` usable surface, not the raw display.** Capsule H reported 380.95 dp against Gate A's 331.0 and Unit 12.5's 331.1 — a ~50 dp gap — and correctly diagnosed it: the widget-test host never sets `tester.view.padding`, so `SafeArea` removes nothing there, while this device removes a 63 px status bar and a 63 px navigation bar, 126 px = **48.0 dp**, before the `Expanded` map ever sees the surface. The convention is now fixed, and it is the one Unit 12.5 used without writing down: **usable surface = 866.29 dp** on this device (2400 − 126 px at 2.625 px/dp), chrome = usable − map box. Under it capsule H is **332.95 dp**, Δ1.95 dp against Gate A, inside the 2 dp agreement the plan expects. Corroborated independently: Unit 12.5's log-drawer capsule measured the drawer's full extent at exactly 866.29 dp. Capsules I and J report both figures and compare on the corrected one. **AC7's under-600 dp claim is a post-`SafeArea` claim**; read against the raw display it would manufacture a false breach at the ceiling | Gate C's per-capsule record, AC7, capsules H, I and J |

### Two planner objections, both ordering consequences rather than disagreements

**On A4:** it moves AC3's closure from Task 07 to Task 08, because Task 07's
closing audit greps `Color(0x` and `TextStyle(` in exactly the two files Task 08
then rewrites. Task 07's audit stands for AC2; Task 08 re-runs the two greps
that its own diff invalidates. A4 also makes residual R4's dartdoc correction
**required in Task 08** rather than recommended at Gate B, because the rename
erases the prefix (`town.panel`) through which that test currently expresses the
premise its dartdoc claims.

**On A6 — the ratio audit the architect asked for.** Every luminance claim in
the plan was re-checked against the ladder by the same arithmetic. Result: one
strike, one correction, one label.

| claim | reading | verdict |
|---|---|---|
| AC4's fill vs surface ≥ 1.5 : 1 (briefs 01 and 04) | either | **STRUCK.** 1.076 : 1 WCAG / 1.491 : 1 plain for a `raised` control on `panel`. Unsatisfiable |
| the meter's each-fill vs `rule` track ≥ 4.5 : 1 (brief 03) | WCAG | **SOUND, kept, now labelled.** Measured 5.587 : 1 and 5.500 : 1 — 24% of headroom. The ladder's problem does not reach it, because this is a bright accent (`L` 0.382 / 0.375) against a dark track (`L` 0.027), not one dark ladder step against another |
| the meter's `\|ΔL\| < 0.02` between the two fills (brief 03) | difference, not contrast | **SOUND, untouched.** Measured 0.0067. It is a *sameness* claim — neither meter may read as fuller than the other at equal fraction — and the architect explicitly excluded it from A6 |
| the chip-state fill ladder (`crawl_action_row_test.dart:442-471`, existing) | strict ordering | **SOUND.** `lessThan` comparisons, no ratio, no threshold to negotiate |
| the newest-vs-older log sentence (`log_drawer_test.dart:256-260`, existing) | strict ordering | **SOUND.** `greaterThan`, no ratio |
| a disabled control reads dimmer than an enabled one (brief 04) | strict ordering | **SOUND.** No ratio; it is the assertion that catches the stock-control label rule being broken |
| R5's descriptive "`armedFill` against `raised` is 1.6 : 1" | unlabelled, and wrong | **CORRECTED** to 1.163 : 1 WCAG / 1.763 : 1 plain. It was descriptive prose in a residual, never an assertion, but after A6 every ratio in this plan carries its reading |

**The standing rule A6 leaves behind:** every luminance claim against this
ladder must be a strict ordering or an accent-against-ladder contrast, and must
state which reading it uses. A fill-versus-surface ratio between two adjacent
ladder values is not provable and must not be reintroduced in U15 through U21.

### Suite size after Task 01 — parameterisation, not coverage

The `packages/app` suite reports **1068 tests against 907 before Task 01**.
That delta is **parameterisation, not new behaviours**: twenty type roles ×
five invariants (`inherit`, `fontFamily`, `height`, `color`, `fontFeatures`)
is 100, and the per-mark glyph-coverage sweep supplies most of the rest. Task
01 added **four** behavioural groups — face resolution, glyph coverage, role
invariants, boot-screen palette — and shipped 1053 with seventeen roles; A7
took it to 1058 and A8 to 1068, five cases per role added. Recorded here so a
later session reading the ledger does not mistake the count for coverage
growth, and so nobody tries to "keep the number up" in a later unit.

### A8, ruled — the unsound rule is gone, not patched

**Ruled by the architect and landed between Tasks 02 and 03.** A7's root
cause was never `crawlChevron`; it was this plan's "colour may be varied at a
call site through `copyWith`" rule, which is unsound wherever the consumer is
`const` — and in this application every one of them is. The rule had three
surviving mandates, all in brief 06:

| site | was mandated | const context | would have |
|---|---|---|---|
| `world_route_diagram.dart:108-112` `'ON THIS ROAD'` | `textMicro.copyWith(color: ink)` | **`const Text(...)`** | **failed to compile** |
| `world_route_diagram.dart:96-106` `'n DAY(S)'` | `textMicro.copyWith(color: ink)` | `Text` non-const | allocated per build, in a diagram that rebuilds on every world state change |
| `world_route_diagram.dart:204-213` node name | `textDetail.copyWith(color: ink)` | `Text` non-const | same |

The ruling, applied in full:

1. `textDetail` and `textMicro` flip to **ink primaries** and gain
   `textDetailDim` and `textMicroDim` — twenty roles. Every pairable role now
   reads the same way, bare name ink and `Dim` sibling dim, which removes the
   irregularity that made the plan reach for `copyWith` in the first place.
2. `crawlDetail` and `crawlTokenWord` alias `textDetailDim`, so nothing
   changes on screen. Brief 06's three dim labels alias `textMicroDim`; its
   two ink labels and the node name take the primaries. **No `copyWith` of a
   token survives anywhere in the application.**
3. The colour-only-`copyWith` rule is **struck from this plan entirely**. It
   produced two compile-breaking defects, and leaving it written down is what
   would have produced a third.

**It did not wait for Task 06.** Deferring a known-unsound rule through three
more tasks is how the third instance gets found at Gate B. It landed as a
standalone `sonic` leaf off `7ade1c9` — behaviour-neutral, three files, the
full suite green at 1068 — so Task 06 arrives to a module that already has
what it needs. Brief 06's blocking note is lifted.

---

## The theme decision, settled

The contract says: *"The crawl already has a local `crawlTheme` singleton. Town
and world get their own, in the same shape, applied at each screen root."*

Once the value ladder, the type roles and the scrim are one shared source,
`crawlTheme`, a `townTheme` and a `worldTheme` would differ in **no field
whatsoever** — every sub-theme value in `crawl_style.dart:146-183` becomes a
shared token, and the world screen already renders entirely from
`town_style.dart`. Three identical `ThemeData` values is the duplication this
unit exists to delete, and `AGENTS.md`'s "duplicate twice before extracting"
cuts the other way here: there is one thing, named three times.

**Settled by the architect 2026-09-18 (A1): one `ThemeData`, `residuumTheme`,
in `lib/style/tokens.dart`, applied explicitly at six screen roots.** The
lock's intent survives verbatim and AC5 is met literally: `MaterialApp.theme`
restyles nothing, and every screen root opts in. What is deliberately not
honoured is the letter "town and world get their own [value]".

Kept for the record: the reversal cost, if a later unit ever needs the three
names back, is two `final ThemeData` lines and two imports. Nothing in this
plan depends on the choice.

The six opt-in sites:

| root | file:line | task |
|---|---|---|
| `BootFailureScreen` | `main.dart:112` | 01 |
| `GameScreen` | `game_screen.dart:58` | 02 |
| `showCrawlSheet`, `showCrawlConfirm` | `crawl_surfaces.dart` (2 sites) | 02 |
| `TownRoom` — 12 screens | `town_style.dart:396` | 04 |
| `TownScreen` | `town_screen.dart:59` | 04 |
| `CrawlPackScreen` | `game/pack_screen.dart:15` | 04 |
| `WorldScreen` | `world_screen.dart:56` | 06 |

`main.dart`'s two `MaterialApp.theme` arguments stay the bare
`ThemeData(brightness: dark, scaffoldBackgroundColor: ground, useMaterial3: true)`
they are today, with the literal replaced by the token. `BootFailureScreen`
opts in at its `Scaffold` rather than through its own `MaterialApp.theme`, so
AC5 holds without an argument about whether a one-screen app counts.

**Dialogs are pushed on the root navigator** (`showDialog` defaults to
`useRootNavigator: true`), so the four `AlertDialog` sites at
`roster_screen.dart:131,175` and `world_screen.dart:131,476` are mounted as
siblings of the screen that opened them, **outside** its `Theme`. Each therefore
wraps its own builder in `Theme(data: residuumTheme, child: …)` — the same
construction `showCrawlConfirm` already uses (`crawl_surfaces.dart:145-146`),
and for the same reason: appearance correct by construction, with no dependence
on `InheritedTheme` capture behaviour.

---

## Scope and ownership

Allowed production surface, and nothing else:

- new `packages/app/assets/fonts/` — 3 font files, 2 `OFL.txt`;
- `packages/app/pubspec.yaml` — the `fonts:` block only;
- new `packages/app/lib/style/tokens.dart`, `packages/app/lib/style/surfaces.dart`;
- `packages/app/lib/main.dart`;
- `packages/app/lib/game/` — `crawl_style.dart`, `crawl_surfaces.dart`,
  `game_screen.dart`, `crawl_status.dart`, `log_drawer.dart`, `battle_view.dart`
  (dartdoc only), `pack_screen.dart`, `dungeon_scene.dart` (two family literals
  only);
- `packages/app/lib/town/` — `town_style.dart`, `town_screen.dart`,
  `character_screen.dart`, `forge_screen.dart`, `gear_screen.dart`,
  `roster_screen.dart`;
- `packages/app/lib/world/` — `world_screen.dart`, `world_route_diagram.dart`;
- `.github/workflows/ci.yml` — two grep gates in the `app` leg;
- tests under `packages/app/test/` named per task.

Forbidden:

- `packages/core/**`, `packages/content/**` — **including every marking
  constant** (`rarity.dart`, `material.dart`, `spell.dart`, `gather_node.dart`);
- the save schema, balance, generation, RNG, any bloc, any event, any
  player-facing string except the six padded-label rows named in F7;
- `MaterialApp.theme` as a restyling mechanism;
- `cameraCellSize`, `glyphBaseFontScale`, the `* 0.30` badge derivation, and
  everything in `dungeon_scene.dart` except the two `fontFamily` literals at
  `:432` and `:441`;
- `dungeon_scene_material.dart`, `dungeon_render_style.dart`, `glyph_marks.dart`,
  `dungeon_material*.dart`, `glyph_plan.dart`, `dungeon_palette.dart`,
  `grid_geometry.dart`, `art/**`;
- `crawl_action_row.dart`'s fit algorithm — `_fitFor`, `_RowFit`, `_ActionChip`
  and every chip metric constant are **U15's**; this unit changes only the
  `TextStyle` values those functions read;
- row anatomy, chip geometry, control geometry, medallions, chevrons, framing,
  illustration placement, the locked spells section, the Forge door split, the
  town status-block relocation — U15 and U17;
- any new icon, art asset, portrait or pictogram — U16;
- `lib/town/inn_screen.dart`, `lib/town/bank_screen.dart`,
  `lib/town/merchant_screen.dart`, `lib/town/alchemist_screen.dart`,
  `lib/town/spells_screen.dart`, `lib/town/skills_screen.dart`,
  `lib/town/pack_screen.dart`, `lib/town/illustration.dart`,
  `lib/notice/notice.dart`, `lib/game/spell_row.dart`,
  `lib/game/item_presentation.dart`, `lib/game/action_icon.dart`,
  `lib/game/crawl_action_row.dart`, `lib/game/log_line.dart`,
  `lib/game/actor_presentation.dart`, `lib/game/log_drawer.dart` — **none of
  these needs an edit**, because each consumes `mono` / `monoDim` /
  `crawlLine` / `crawlChipLabel` / a style parameter, and the alias strategy
  below carries all of them. Verified at `5ac1a49`: after Unit 12 the only
  inline `TextStyle(` left anywhere under `lib/game/` outside
  `crawl_style.dart` and the renderer is `pack_screen.dart:17` and `:294`,
  which are town-owned and belong to Task 04;
- golden-image tests, a `ThemeExtension`, an `InheritedWidget`, `google_fonts`
  or any new package dependency.

### The alias strategy — the migration mechanism, and why it is transitional

Through Tasks 01–07, `crawl_style.dart` and `town_style.dart` **keep every name
they export today**, re-declared as aliases of the shared tokens:

```dart
// town_style.dart, after Task 04
const Color ink = tokens.ink;
const TextStyle mono = textBody;
```

AC3 forbids a duplicate colour *literal*, not a named alias. Aliasing is what
makes the cutover possible in seven compiling steps instead of one 40-file
commit:

1. every one of the ~35 files that reads `ink`/`dim`/`panel`/`rule`/`mono`/
   `monoDim`/`crawlInk`/`crawlBody`/… keeps compiling untouched;
2. every existing test that compares a rendered colour against a **named
   constant** stays valid — `crawl_surfaces_test.dart:237,252,267` (`crawlPanel`)
   and `:298-299` (`town.panel`, `town.ink`) survive verbatim;
3. the nine town/game files listed as "needs no edit" above genuinely need none;
4. each task's diff is the styles it owns, not the transitive closure of a
   rename.

**Settled by the architect 2026-09-18 (A4): the aliases are transitional, not
the end state.** They stay through Tasks 01–07 exactly as designed, because
that is what buys the seven compiling steps. But three names per colour is not
an end state to hand the seven units that follow: a maintainer six months out
must not have to work out whether `ink`, `crawlInk` and the shared token are
one value. **Task 08 deletes every alias that only re-names a shared token and
repoints its consumers**, and keeps every declaration that names a seam concept
the shared module does not have. See §"Task 08 — the rename leaf".

The end state is therefore: one shared name per shared value, and a seam
declaration only where the seam has something of its own to say.

### File ownership matrix

| file | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 |
|---|---|---|---|---|---|---|---|---|
| `assets/fonts/*` | create | | | | | | | |
| `pubspec.yaml` | `fonts:` | | | | | | | |
| `lib/style/tokens.dart` | create: families, ladder, rhythm, roles, `residuumTheme` | | append: meter hues | | append: `labelColumn` | | | |
| `lib/style/surfaces.dart` | | | create: `ResourceMeter` | | append: `LabelledValue` | | | |
| `lib/main.dart` | literals, 3 styles, boot theme, dartdoc | | | | | | | rename |
| `lib/game/crawl_style.dart` | | aliases; drop 10 colours + 16 styles + `crawlTheme` | | | | | | **delete 27 aliases; keep 14 metrics + 5 type + the chip table** |
| `lib/game/game_screen.dart` | | `:57` theme site | | | | | | rename |
| `lib/game/crawl_surfaces.dart` | | `:116`, `:146` theme sites + `:105` dartdoc | | | | | | rename |
| `lib/game/battle_view.dart` | | dartdoc | | | | | | rename |
| `lib/game/crawl_status.dart` | | | `ResourceMeter`, type | | | | | rename |
| `lib/game/crawl_action_row.dart` | | | | | | | | rename |
| `lib/game/log_drawer.dart` | | | | | | | | rename |
| `lib/town/town_style.dart` | | | | aliases, theme site, 7 styles | `Purse` | | dartdoc ×2 | **delete 8 aliases; keep `markColumn`** |
| `lib/town/town_screen.dart` | | | | theme site, type | `LabelledValue`, meter | | | rename |
| `lib/town/character_screen.dart` | | | | 4 buttons, type | `LabelledValue`, 2 meters | | | rename |
| `lib/town/forge_screen.dart` | | | | `Temper` | | | | rename |
| `lib/town/gear_screen.dart` | | | | `Take off` | | | | rename |
| `lib/town/roster_screen.dart` | | | | dialogs, `TextField`, `Delete` | | | | rename |
| `lib/town/inn_screen.dart` | | | | | **A3: 2 padded rows** | | | rename |
| `lib/town/{bank,merchant,alchemist,spells,skills,pack}_screen.dart`, `illustration.dart`, `notice/notice.dart`, `game/spell_row.dart`, `game/item_presentation.dart` | | | | | | | | rename only |
| `lib/game/pack_screen.dart` | | | | theme site, `AppBar`, chips, actions | | | | rename |
| `lib/world/world_screen.dart` | | | | | | theme site, dialogs, type, meter | | rename |
| `lib/world/world_route_diagram.dart` | | | | | | type | | rename |
| `lib/game/dungeon_scene.dart` | | | | | | | 2 literals | rename |
| `.github/workflows/ci.yml` | | | | | | | 2 gates | |
| `test/**` | 3 new files | 1 rewritten | 1 new, 1 rewritten | 1 new | 2 rewritten | 1 new, ≤1 rewritten | | **rename only — no substantive test edit** |

"rename" means Task 08's language-server rename and its import repoint, nothing
else. A file marked "rename only" is otherwise untouched by this entire unit.

---

## Strict execution graph

```text
01 the faces, the token module, and proof the faces resolve in both hosts
  -> accepted Task 01 repository state + receipt
02 the crawl seam onto the tokens; the crawl's dp re-measurement
  -> accepted Task 02 repository state + receipt (carries the dp figures)
03 the one resource meter, and the crawl status adopting it
  -> accepted Task 03 repository state + receipt
04 the town seam onto the tokens, the theme at its roots, the lavender gone
  -> accepted Task 04 repository state + receipt
05 numeric alignment slots, and the character and town meters
  -> accepted Task 05 repository state + receipt
06 the world seam and the route diagram
  -> accepted Task 06 repository state + receipt
07 the map glyph, the monospace sweep, and the standing guard
  -> accepted Task 07 repository state + receipt (closes AC2)
08 the rename leaf: delete every alias that only re-names a shared token
  -> accepted Task 08 repository state + receipt (closes AC3)
GATE A  dp re-measurement re-confirmed on the final tree, three densities
GATE B  integrated format/analyze/full suite + COR/TTC/CRF acceptance review
        -> corrections -> rerun any evidence the correction staled
GATE C  Medium_Phone: back up both save slots -> install -> capture every
        capsule in colour and greyscale -> at most one constants-only tuning
        pass -> affected proof + scoped acceptance rerun -> recapture
        -> restore both slots byte-identically from the backups
  -> user acceptance / integration decision
```

**Strictly sequential. Eight fresh executor sessions on the same non-isolated
Unit 14 feature checkout** — `flow-plan-executor` for 01–07, and see §"Task 08"
for that task's agent recommendation. They may not be parallelised, and the
reason is stronger here than in any earlier unit:

1. Tasks 02–08 all consume Task 01's `tokens.dart`, which does not exist before
   it;
2. Task 01 changes **the measured metrics of every widget test in the suite at
   once** — the moment the `FontLoader` lands, every `RenderParagraph` in the
   app is measured in Spectral instead of Ahem. Two concurrent writers would each
   be measuring against the other's half-migrated metrics, and neither could
   trust a `takeException` or a chrome figure;
3. 02 and 03 both edit `crawl_status.dart` and `crawl_style.dart`;
4. 03 and 05 share `lib/style/surfaces.dart`, and 05 consumes 03's component;
5. 04 and 05 both edit `town_style.dart`, `town_screen.dart` and
   `character_screen.dart`;
6. 06's `world_screen.dart` imports `town_style.dart` and cannot be migrated
   before 04 settles the aliases;
7. 07's precondition **is** "every task before it landed" — it is the AC2
   closer;
8. 08 touches **every file in the unit and most files outside it**, so it must
   be the last writer. It is also the only task whose correctness argument is
   "the full suite is green and no test needed a substantive edit", which is
   meaningless unless every behavioural change already landed.

Repository state and accepted receipts carry forward; executor conversation does
not. Each task brief is a fresh-executor capsule.

### Task slices, valid handoffs, and the fresh-executor capsules

| # | slice | valid handoff | capsule |
|---:|---|---|---|
| 01 | the three font files, the `fonts:` block, `tokens.dart`, the test-host `FontLoader`, and the boot failure screen as first consumer | both faces provably resolve in the test host; the twelve absent marks recorded; every role satisfies its invariants; `Begin fresh` off the M3 palette; `main.dart` free of literals; any unmigrated-screen metric shift named and handed forward | `plan-tasks/01-faces-and-token-module.md` |
| 02 | `crawl_style.dart` to aliases, `crawlTheme` deleted, the three theme sites, and the crawl's dp re-measurement | no literal or `TextStyle` in `crawl_style.dart`; the three chrome caps re-derived from measurement with both the Ahem-era and Spectral-era figures recorded; fifteen crawl test files green | `plan-tasks/02-crawl-seam-and-dp-gate.md` |
| 03 | `surfaces.dart` with `ResourceMeter`, the two hues, and the crawl status adopting it | the greyscale arithmetic asserted; the crawl's chrome unchanged from Task 02's, proving the geometry moved verbatim; `crawl_status_test.dart` green with key-re-pointing edits only | `plan-tasks/03-resource-meter.md` |
| 04 | `town_style.dart` to aliases, `residuumTheme` at three roots, both roster dialogs, and all ten control families off the M3 palette | `material_palette_test.dart` green with the four named cases in their own groups; no stock control replaced; fifteen town and pack test files green | `plan-tasks/04-town-theme-and-the-lavender.md` |
| 05 | `labelColumn`, `LabelledValue`, and the town and character meters | every value column's rendered `left` identical; both padded-string test sites rewritten to the facts they defended; `Purse`'s four consumers green | `plan-tasks/05-numeric-alignment-and-town-meters.md` |
| 06 | the world screen, its two dialogs, its health row, and the route diagram | no diagram paragraph exceeds its 120 dp box at `onAPhone` with a journey in progress; `WorldDoor` and both dialogs off the M3 palette; `world_screen_test.dart` green | `plan-tasks/06-world-seam-and-route-diagram.md` |
| 07 | the two map glyph paints, the prose sweep, the CI gate and the `AGENTS.md` rule | closing greps 1 and 2 clean — **AC2 closed**; `dungeon_scene.dart` differs by two lines and one import; twelve renderer and glyph test files green | `plan-tasks/07-map-glyph-sweep-and-guard.md` |
| 08 | delete every alias that only re-names a shared token; keep every seam-vocabulary declaration; repoint all consumers through the language server | `crawl_style.dart` and `town_style.dart` declare **no `Color` at all** and no bare-renaming `TextStyle` — **AC3 closed**; `flutter analyze` clean; **full suite green with no test edited except by the rename itself**; R4's dartdoc corrected | `plan-tasks/08-rename-leaf.md` |

---

## Cross-task interfaces

### `lib/style/tokens.dart` — the one token module

A plain file of `const` values plus one `ThemeData`. Same shape as
`crawl_style.dart`: no widgets (they live in `surfaces.dart`), not a
`ThemeExtension`, not an `InheritedWidget`, no change to `MaterialApp.theme`.

**Families.** Task 01.

```dart
const String textFace = 'Spectral';
const String displayFace = 'EB Garamond';
```

These are the **only** two string literals naming a family anywhere in
`packages/app/lib` when the unit closes. The CI gate in Task 07 enforces it.

**The value ladder.** Task 01. Names are prefixed `token` only where an
unprefixed name would collide with the seams' existing exports.

| name | value | meaning | replaces |
|---|---|---|---|
| `ground` | `0xFF0E1014` | the app's ground | `crawlVoid`, `main.dart:83`, `main.dart:171` |
| `recessed` | `0xFF11141A` | a dead control's fill, a mark well | `crawlRecessed` |
| `panel` | `0xFF15181F` | panel, sheet and dialog surface | `crawlPanel`, `town.panel` |
| `raised` | `0xFF1B1F27` | an available control's fill | `crawlRaised` |
| `disabledRule` | `0xFF1E222A` | a dead control's border | `crawlDisabledRule` |
| `armedFill` | `0xFF262B35` | an armed or selected control's fill | `crawlArmedFill` |
| `rule` | `0xFF2A2E38` | hairline, meter track | `crawlRule`, `town.rule` |
| `dim` | `0xFF8A919E` | subordinate ink | `crawlDim`, `town.dim` |
| `ink` | `0xFFE6EAF0` | the brightest ink | `crawlInk`, `town.ink` |
| `scrim` | `0xCC0E1014` | modal barrier | `crawlScrim` |
| `meterHealthFill` | `0xFFD99A3D` | warm amber, health reinforcement | new (Task 03) |
| `meterManaFill` | `0xFF7FA8D9` | cold blue, mana reinforcement | new (Task 03) |

`panel` and `rule` collide with `town_style.dart`'s current exports of the same
name and value; the alias strategy resolves that by making `town_style.dart`'s
`panel` **be** the token. `dim` and `ink` likewise.

**The spacing rhythm and the hairline.** Task 01.

| name | value | replaces |
|---|---:|---|
| `gutter` | 12 | `crawlGutter` |
| `rhythm` | 4 | `crawlRhythm` |
| `radius` | 6 | `crawlRadius` |
| `hairline` | 1 | `crawlHairline` |
| `tapTarget` | 44 | `crawlTapTarget` |
| `labelColumn` | 96 | new (Task 05) — the fixed-width label slot of F7 |

`labelColumn = 96`: the widest label in the F7 set is `Skills trained` at 14
characters, ≈ 14 × 0.47 em × 13 px ≈ 86 dp, plus a 10 dp gap. The town's
existing `markColumn = 28` stays town-owned and unchanged.

**The type roles.** Task 01. Eighteen roles replace the sixty-four inline and
seam-declared styles.

Invariants every role satisfies, and a property test asserts (Task 01):

- `inherit: false` — so no role can silently pick up an ambient
  `DefaultTextStyle`, and the object a `TextPainter` measures is the object a
  `Text` paints. This generalises `crawl_style.dart:96-100`'s existing
  measurement-determinism rule to the whole application;
- `fontFamily` set explicitly — the contract's trap, now an invariant rather
  than a per-style discipline;
- `height` set explicitly — F5;
- `color` set explicitly — required, because `inherit: false` means no colour
  arrives from anywhere else;
- text roles carry `fontFeatures: [FontFeature.tabularFigures()]`;
- display roles carry
  `fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()]`
  (F2).

**Display roles — `displayFace`, `FontWeight.w500` with
`fontVariations: [FontVariation('wght', 500)]`:**

| role | size | tracking | colour | height | replaces |
|---|---:|---:|---|---:|---|
| `displayTitle` | 22 | 6 | ink | 1.15 | `world_screen.dart:183-191` `RESIDUUM` (22/6) |
| `displayPlace` | 20 | 4 | ink | 1.15 | `town_style.dart:34-39` `placeName` (20/5) |
| `displayRoom` | 15 | 3 | ink | 1.20 | `town_style.dart:42-47` `roomName` (15/4); `crawl_style.dart:39-45` `crawlPlace` (15/3/w500) |
| `displayPanel` | 13 | 2 | ink | 1.20 | `crawl_style.dart:63-69` `crawlPanelTitle` (13/2/w600); `pack_screen.dart:17` `AppBar` title |
| `displayCaption` | 11 | 2 | dim | 1.25 | `town_style.dart:67-72` `Heading` (11/2/dim); `crawl_style.dart:56-62` `crawlRegionLabel` (11/2/w600/dim) |

Tracking drops by 1 at every rung because caps in EB Garamond are 0.659 em
against monospace's 0.600 em (F6): `STONEBRIDGE` lands at
11 × (0.659 × 20 + 4) ≈ 189 dp against today's 11 × (12 + 5) = 187 dp, so the
title region's width is held.

`NOW` / `NEXT` moving to `displayCaption` matches the mock, which sets them in
small grey letterspaced caps.

**Text roles — `textFace`:**

| role | size | weight | colour | height | replaces |
|---|---:|---|---|---:|---|
| `textHeadline` | 26 | 400 | ink | 1.15 | `crawl_style.dart:134-138` `crawlHeadline` (28); `main.dart:122` boot sentence (20) |
| `textAction` | 15 | 400 | ink | 1.25 | `town_style.dart:381-383` `Commit` (15); `world_screen.dart:557-559` `WorldDoor` (15); `main.dart:134` `Begin fresh` (15); `character_screen.dart:55,69,83,97` route labels (default 14) |
| `textBody` | 14 | 400 | ink | 1.30 | `town_style.dart:14-18` `mono`; `crawl_style.dart:46-50` `crawlBody`; dialog titles |
| `textLine` | 13 | 400 | ink | 1.35 | `crawl_style.dart:70-74` `crawlLine`; `main.dart:145` `monoLike` (13); dialog bodies (13) |
| `textLineDim` | 13 | 400 | dim | 1.35 | `town_style.dart:20-24` `monoDim` (12); `crawl_style.dart:51-55` `crawlBodyDim` (12); `crawl_style.dart:75-79` `crawlLineOlder` (13) |
| `textLabel` | 13 | 400 | ink | 1.20 | `crawl_style.dart:101-107` `crawlChipLabel` (12/w500); `town_style.dart:166` `ItemRow` action (12); `forge_screen.dart:166` `Temper` (12); `gear_screen.dart:85` `Take off` (12); `roster_screen.dart:317` `Delete` (12); `pack_screen.dart:294` row actions (12) |
| `textLabelDim` | 13 | 400 | dim | 1.20 | `crawl_style.dart:108-114` `crawlChipLabelDisabled` (12/w400) |
| `textLabelStrong` | 13 | 600 | ink | 1.20 | `crawl_style.dart:115-121` `crawlChipLabelArmed` (12/w600) |
| `textCaption` | 11 | 600 | ink | 1.20 | `crawl_style.dart:122-128` `crawlCaption` (11/w600) |
| `textDetail` | 11 | 400 | **ink** | 1.30 | `world_route_diagram.dart:206-210` node name (11, ink) |
| `textDetailDim` | 11 | 400 | dim | 1.30 | `crawl_style.dart:129-133` `crawlDetail` (11); `crawl_style.dart:85-89` `crawlTokenWord` (11) |
| `textGlyph` | 18 | 400 | ink | 1.00 | `crawl_style.dart:80-84` `crawlGlyph` (18) |
| `textGlyphDim` | 18 | 400 | dim | 1.00 | `crawl_style.dart:90-94` `crawlChevron` (18, dim) — the timeline separator at `battle_view.dart:55,70,84` and the log peek's expand mark at `log_drawer.dart:80` |
| `textMicro` | 9 | 400 | **ink** | 1.15 | `world_route_diagram.dart:99-103` `n DAY(S)` (10, ink); `:109-111` `ON THIS ROAD` (9, ink) |
| `textMicroDim` | 9 | 400 | dim | 1.15 | `world_route_diagram.dart:115-119` danger (10, dim); `:198-202` node kind (9, dim); `:216-220` node state (9, dim) |

`textGlyphDim` is the **eighteenth** role, added by architect amendment A7
during Task 02's execution. `textDetailDim` and `textMicroDim` are the
nineteenth and twentieth, added by **A8** as a standalone leaf between Tasks
02 and 03. All three are `const` literals identical to their primary but for
colour, exactly as `textLine`/`textLineDim` and `textLabel`/`textLabelDim`
already pair. **Twenty roles.**

A8 also flipped `textDetail` and `textMicro` from dim primaries to ink
primaries, so every pairable role in the module now reads the same way:
the bare name is ink and the `Dim` sibling is dim. They were the two odd ones
out, and that irregularity is exactly what made an earlier version of this
plan reach for `copyWith(color: ink)` to get an ink variant.

**Colour may be varied at a call site only through a `const` sibling role.
`copyWith` of a token is prohibited outright.** Size, weight, family, height,
tracking and features are never varied at all. An earlier version of this
plan permitted `copyWith(color: …)` at a call site; **A7 struck it and A8
retired its last three mandates**, because `copyWith` is not const-evaluable
and every consumer of a colour variant in this application sits in a `const`
context. The rule produced two compile-breaking defects before it was
removed. Where a role needs a second colour, the token module gains a `const`
sibling and the consumer aliases it.

**The size ladder becomes 9, 11, 13, 14, 15, 18, 20, 22, 26** — nine rungs
replacing the current eleven (9, 10, 11, 12, 13, 14, 15, 18, 20, 22, 28). 10 and
12 are retired upward to 11 and 13 to recover the 0.45 em x-height Spectral
loses against monospace's 0.528 em (F6); 28 comes down to 26 because
`You died.` at 26 px Spectral is already wider than at 28 px monospace.

The +1 px on the 12 px rungs is paid for by F5's explicit heights: at 13 px
with `height: 1.20` a label line is 15.6 dp against today's device
12 px × 1.32 em = 15.84 dp. **The rungs go up and the rows get shorter.** That
is the whole budget argument, and it is why an executor must never "simplify" a
role by dropping its `height`.

**`residuumTheme`.** Task 01. A top-level `final`, so Dart initialises it once
and no `build` allocates a `ThemeData`. Built from scratch, never from
`Theme.of(context).copyWith(…)`, so it cannot inherit a future ambient change.

```dart
const ColorScheme _scheme = ColorScheme(
  brightness: Brightness.dark,
  primary: ink,      onPrimary: ground,
  secondary: ink,    onSecondary: ground,
  error: ink,        onError: ground,
  surface: panel,    onSurface: ink,
);
```

**The `colorScheme` is the load-bearing field for AC4.** Every sub-theme below
names a control somebody enumerated; the scheme is what catches the control
nobody did. `error: ink` is deliberate: nothing in the application renders an
M3 error surface today, and this design may not carry a state by hue, so if
something ever needs to it will carry it with a word.

| sub-theme | value | covers |
|---|---|---|
| `scaffoldBackgroundColor`, `canvasColor` | `ground` | every `Scaffold` |
| `splashColor` / `highlightColor` | `raised` at alpha 0.24 / 0.12 | every ink response |
| `iconTheme` | `color: ink, size: 18` | the recenter affordance, the log close |
| `dividerTheme` | `color: rule, thickness: hairline` | any `Divider` that stops passing a colour |
| `progressIndicatorTheme` | `color: ink, linearTrackColor: rule` | the skills bar, the meter's floor |
| `appBarTheme` | `elevation: 0`, `scrolledUnderElevation: 0`, `surfaceTintColor: transparent`, `titleTextStyle: displayPanel`, `iconTheme: (ink, 20)` | the three `AppBar`s — **`backgroundColor`/`foregroundColor` stay at the call sites** (see below) |
| `textButtonTheme` | `foregroundColor: ink`, `disabledForegroundColor: dim`, `overlayColor: raised`, `textStyle: textLabel` | F9 rows 7, 8; the crawl's dialog actions; the town doors |
| `filledButtonTheme` | `backgroundColor: raised`, `foregroundColor: ink`, `disabledBackgroundColor: recessed`, `disabledForegroundColor: dim`, `elevation: 0`, `textStyle: textAction`, `shape: RoundedRectangleBorder(radius, side: (rule, hairline))` | F9 rows 1, 3, 4, 5, 6, 10 |
| `chipTheme` | `backgroundColor: raised`, `selectedColor: armedFill`, `disabledColor: recessed`, `side: (rule, hairline)`, `labelStyle: textLabel`, `secondaryLabelStyle: textLabelStrong`, `checkmarkColor: ink`, `showCheckmark: true`, `shape: RoundedRectangleBorder(radius)`, `surfaceTintColor: transparent`, `elevation: 0`, `pressElevation: 0` | F9 row 2 |
| `bottomSheetTheme` | `backgroundColor: panel`, `surfaceTintColor: transparent`, `elevation: 0`, `showDragHandle: false`, `modalBarrierColor: scrim`, top-rounded `radius` | the two crawl sheets |
| `dialogTheme` | `backgroundColor: panel`, `surfaceTintColor: transparent`, `elevation: 0`, `barrierColor: scrim`, `titleTextStyle: textBody`, `contentTextStyle: textLine`, `shape: RoundedRectangleBorder(radius, side: (rule, hairline))` | F9 row 8; the crawl confirm |
| `inputDecorationTheme` | `border`/`enabledBorder`/`focusedBorder` = `OutlineInputBorder(borderSide: (rule, hairline))` focused `(ink, hairline * 2)`, `labelStyle: textLineDim`, `hintStyle: textLineDim` | F9 row 9 |
| `textSelectionTheme` | `cursorColor: ink`, `selectionColor: armedFill`, `selectionHandleColor: ink` | F9 row 9 |

**The three `AppBar` call sites keep their explicit `backgroundColor: panel,
foregroundColor: ink`** (`town_style.dart:397`, `town_screen.dart:60`,
`game/pack_screen.dart:18-19`). Those are token-sourced, not literals, so AC3 is
unaffected — and `crawl_surfaces_test.dart:297-300` asserts
`appBar.backgroundColor == town.panel` on the constructor argument. Moving the
colour into `appBarTheme` would null that argument and force a test rewrite
whose *reason* changes (see R4). Keeping it is both the smaller change and the
one that does not disturb evidence.

**The stock-control label rule.** For a stock `FilledButton`, `TextButton` or
`ChoiceChip`, the label's metrics come from the control's theme
(`ButtonStyle.textStyle`, `ChipThemeData.labelStyle`) and **the call site passes
`Text(label)` with no `style:`**. `ButtonStyleButton` resolves `foregroundColor`
/ `disabledForegroundColor` over the theme's `textStyle`, so enabled and
disabled read differently; a call-site `style:` carrying `inherit: false` and a
colour would win outright and freeze a disabled label at full ink. Two control
sites legitimately override the *metrics* because they are narrow trailing
controls rather than full-width commits, and each does so with a token:

- `town_style.dart:157-169` `ItemRow` — `FilledButton.styleFrom(textStyle: textLabel, padding: …)`;
- `gear_screen.dart:73-87` `Take off` — the same.

### `lib/style/surfaces.dart` — the shared widgets

Two widgets, no values. Task 03 creates the file with `ResourceMeter`; Task 05
appends `LabelledValue`.

```dart
enum MeterTint { health, mana }

class ResourceMeter extends StatelessWidget {
  const ResourceMeter({
    required this.label,
    required this.value,
    required this.ceiling,
    required this.tint,
    this.note = '',
    super.key,
  });

  final String label;
  final int value;
  final int ceiling;
  final MeterTint tint;
  final String note;
}

class LabelledValue extends StatelessWidget {
  const LabelledValue({required this.label, required this.value, super.key});

  final String label;
  final String value;
}
```

**`ResourceMeter` geometry is `crawl_status.dart:118-170`'s `_Meter`, moved
verbatim** — a `Row` of `Expanded(flex: 8)` label-and-number in a
`FittedBox(scaleDown, centerLeft)`, `SizedBox(width: 6)`,
`Expanded(flex: 6)` track as `ClipRRect(radius 2)` over
`LinearProgressIndicator(value:, minHeight: 8, backgroundColor: rule,
valueColor: AlwaysStoppedAnimation(fill))`, `SizedBox(width: 6)`,
`Expanded(flex: 6)` note in a `FittedBox(scaleDown, centerRight)`. Nothing about
it is redesigned: the crawl's geometry is already measured, already tested by
`crawl_status_test.dart`, and control geometry is U15's. The label-and-number
reads `'$label $value / $ceiling'` in `textBody`; the note reads in `textBody`.
`fill = switch (tint) { health => meterHealthFill, mana => meterManaFill }`.

**The hues, and why greyscale loses nothing.** Relative luminance:

| colour | value | L | ratio vs `rule` track |
|---|---|---:|---:|
| `meterHealthFill` | `#D99A3D` | 0.3820 | 5.5 : 1 |
| `meterManaFill` | `#7FA8D9` | 0.3753 | 5.5 : 1 |
| `rule` (track) | `#2A2E38` | 0.0273 | — |

`|ΔL| = 0.0067`. In greyscale the two fills are **indistinguishable from each
other**, so a greyscale render loses the hue and keeps exactly what carried the
meaning — the word (`HP` / `Mana` / `Health`), the number, the ceiling and the
fill fraction. Neither meter reads as fuller than the other at equal fraction,
which a red-and-blue pair at different luminance would have caused. Warm amber
rather than the mock's red is deliberate: `VISUAL-SYSTEM.md` §2 reserves hot red
for mortal danger and the armed reticle, so health takes the warm amber the same
section permits for "light, fire and gold". No red-versus-green pair exists
anywhere in the result.

**`skills_screen.dart:49-53`'s `LinearProgressIndicator` is not a resource
meter** and keeps `ink` on `rule`. Hue is reserved for the two resources; a
tinted XP bar would spend the epic's first permitted hue on a third meaning.

**`LabelledValue`** is `Row([SizedBox(width: labelColumn, child: Text(label,
style: textLineDim)), Expanded(child: Text(value, style: textBody))])`. It is
the fixed-width slot the contract mandates, replacing a padded string that only
ever aligned in monospace — the same mechanism `markColumn` already uses in the
town (`town_style.dart:26-31`), for the same recorded reason. It adds no
medallion, no chevron, no border and no control, so it is not the row anatomy
U15 owns.

### Test-host font registration

Task 01. `test/support/fonts.dart`:

```dart
Future<void> loadResiduumFonts() async {
  for (final (family, assets) in const [
    (textFace, ['assets/fonts/Spectral-Regular.ttf', 'assets/fonts/Spectral-SemiBold.ttf']),
    (displayFace, ['assets/fonts/EBGaramond-Variable.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
```

`test/flutter_test_config.dart`:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadResiduumFonts();
  await testMain();
}
```

`flutter_test_config.dart` is Flutter's per-directory hook: the tool wraps every
test file under `test/` with it, once per isolate. One file, whole suite, no
per-test opt-in. The family strings **must** equal the `pubspec.yaml` families
or the host silently falls back to Ahem and every dp figure in this unit becomes
fiction.

---

## Font assets: exact files, weights and licence

Source: the `google/fonts` repository, `main`, which is the canonical OFL
distribution. Verified file listings and byte sizes, downloaded and inspected
during planning.

| upstream path | committed as | size | md5 |
|---|---|---:|---|
| `ofl/spectral/Spectral-Regular.ttf` | `assets/fonts/Spectral-Regular.ttf` | 261 088 | `a183bbc39261b7279df4f8942e95e95c` |
| `ofl/spectral/Spectral-SemiBold.ttf` | `assets/fonts/Spectral-SemiBold.ttf` | 273 068 | `7dd411a9cac1ebbd55618d0f0d2c5f4f` |
| `ofl/ebgaramond/EBGaramond[wght].ttf` | `assets/fonts/EBGaramond-Variable.ttf` | 851 176 | `90a58d69f647565a751b7400d2493344` |
| `ofl/spectral/OFL.txt` | `assets/fonts/OFL-Spectral.txt` | 4 392 | — |
| `ofl/ebgaramond/OFL.txt` | `assets/fonts/OFL-EBGaramond.txt` | 4 398 | — |

The EB Garamond file is renamed on commit: `google/fonts` ships only a variable
font and its filename contains `[` and `]`, which are awkward in a Flutter asset
path and in a shell. The bytes are unchanged; the md5 above is the check.

Total added weight: **1.39 MB**, against the 21 PNGs and 3 JPEGs the app already
ships.

**The weight budget: two Spectral faces, one EB Garamond instance.**

- **Spectral Regular (400)** is the reading weight. Every density failure in the
  audit lives at 11–13 px, and 400 is what Spectral was drawn for at that size.
- **Spectral SemiBold (600)** is the single emphasis weight the design needs:
  `textLabelStrong` (the armed chip) and `textCaption` (`— armed`).
- **No Spectral Medium (500).** Two faces is the contract's budget, and with 400
  and 600 declared, a `w500` request resolves to 400 under the CSS weight-match
  rule the engine follows — so a Medium's only effect would be to make the
  chip-state ladder's middle rung *look* different from its neighbours without
  the design depending on it. The ladder is restated instead as
  **disabled 400 / available 400 / armed 600**, which keeps four non-hue cues
  (fill value, border colour, border width, label colour) plus the `— armed`
  word, and keeps `crawl_action_row_test.dart:467-470`'s
  `armed.label.fontWeight > available.label.fontWeight` true at 600 > 400.
- **EB Garamond at `wght` 500, one file.** The display register is letterspaced
  roman capitals and needs exactly one weight; 500 holds letterspaced caps on a
  dark ground better than 400. It is requested three ways so that whichever
  mechanism the host honours lands on 500: `weight: 500` in `pubspec.yaml`,
  `fontWeight: FontWeight.w500` and
  `fontVariations: [FontVariation('wght', 500)]` on every display role. If none
  is honoured the face renders at its 400 default — legible, and a recorded
  observation rather than a defect. A *synthesised* bold or a visibly wrong
  weight on device is an escalation, not a cue to add a second display file.

`pubspec.yaml`, replacing the commented template block at `:77-80`:

```yaml
  fonts:
    - family: Spectral
      fonts:
        - asset: assets/fonts/Spectral-Regular.ttf
          weight: 400
        - asset: assets/fonts/Spectral-SemiBold.ttf
          weight: 600
    - family: EB Garamond
      fonts:
        - asset: assets/fonts/EBGaramond-Variable.ttf
          weight: 500
```

The `OFL.txt` files live beside the fonts and are **not** listed under `assets:`
— they are committed licence text, not a runtime asset. The existing
`assets/visual/…` entries are untouched. `pubspec.lock` does not change, so the
CI lockfile-drift gate is unaffected.

**No `fontFamilyFallback` is declared**, on either family. The twelve marks of
F3 resolve through the platform's own chain today and must keep doing exactly
that; naming a fallback family that is not bundled would be a lie on some
devices and a no-op in the test host.

---

## Task 08 — the rename leaf

Architect amendment A4. Behaviour-neutral by construction; its whole value is
that the seven units after this one inherit **one name per value**.

### The decidable rule

> If deleting the name and using the shared token in its place loses no
> meaning, delete it. If the name says something the token does not, keep it —
> and give it a dartdoc saying what.

### What goes

Thirty-five declarations, every one of which is a bare re-naming introduced by
Task 02 or Task 04:

| file | deleted | count |
|---|---|---:|
| `crawl_style.dart` | `crawlInk`, `crawlDim`, `crawlPanel`, `crawlRule`, `crawlVoid`, `crawlRaised`, `crawlRecessed`, `crawlArmedFill`, `crawlDisabledRule`, `crawlScrim` | 10 |
| `crawl_style.dart` | `crawlGutter`, `crawlRhythm`, `crawlRadius`, `crawlHairline`, `crawlTapTarget` | 5 |
| `crawl_style.dart` | `crawlPlace`, `crawlBody`, `crawlBodyDim`, `crawlRegionLabel`, `crawlPanelTitle`, `crawlLine`, `crawlLineOlder`, `crawlGlyph`, `crawlTokenWord`, `crawlDetail`, `crawlHeadline` | 11 |
| `town_style.dart` | `ink`, `dim`, `panel`, `rule` | 4 |
| `town_style.dart` | `mono`, `monoDim`, `placeName`, `roomName` | 4 |
| | | **34** |

Plus `main.dart`'s `monoLike`, already deleted in Task 01 — so 34 remain at the
start of Task 08. The count is stated so the receipt can be checked against it.

### What stays, and why

| kept | why the seam needs its own name |
|---|---|
| `crawlChipLabel`, `crawlChipLabelDisabled`, `crawlChipLabelArmed`, `crawlCaption` | the chip-state ladder. `_fitFor` measures **these exact objects** and names the heaviest one explicitly (`crawl_action_row.dart:154-163`); the seam owning the names is what lets U15 retune the ladder without touching a shared role |
| ~~`crawlChevron`~~ | **deleted by Task 08 after A7.** An earlier version of this plan kept it as a seam-local colour variant hoisted out of three call sites so no build allocated a `copyWith`. A7 made it a `const` alias of `textGlyphDim`, so it is a pure re-naming like any other and the rule deletes it |
| `crawlPanelPadding`, `crawlTokenCell`, `crawlTokenWidth`, `crawlLogPeekHeight`, `crawlMarkColumn`, `crawlMarkWell`, `crawlLogRowRhythm`, `crawlChipSpacing`, `crawlChipRunSpacing`, `crawlChipPadding`, `crawlChipVerticalPadding`, `crawlChipMaxColumns`, `crawlChipMaxLabelLines`, `crawlDisabledIconOpacity` | fourteen real crawl metrics with no shared equivalent. They were never aliases |
| `CrawlChipState`, `CrawlChipSkin`, `crawlChipSkin` | U15's chip vocabulary |
| `markColumn` | the town's leading glyph cell, 28 dp, with its own device-metric dartdoc. `labelColumn` is a different job at a different width |

Every kept declaration that points at a shared role gains a one-line dartdoc
saying why the seam needs its own name. That dartdoc is the answer to the next
maintainer who asks the same question A4 asked.

### The procedure, and why it is mechanical rather than a rewrite

This is **not** a rename in the LSP sense: the target name already exists. The
operation per alias is rename-then-delete, and it splits into two shapes:

**Shape 1 — the 30 non-colliding names** (`crawlInk`, `mono`, `crawlBody`, …):

1. language-server **rename symbol** on the alias, to the shared token's name.
   Every consumer's identifier is repointed by the server;
2. the declaration is now self-referential (`const Color ink = ink;`) and the
   analyzer says so. Delete the line.

**Shape 2 — the 4 colliding names** (`ink`, `dim`, `panel`, `rule`, whose
`town_style.dart` export already *is* the token's name, which is why Task 04
imported the token module under a prefix): no rename is needed. Delete the four
declarations and drop the prefix from `town_style.dart`'s import.

**Then, for both shapes:** `flutter analyze` becomes the worklist. Every file
with an unresolved identifier needs `import '…/style/tokens.dart';` added, and
— where it no longer uses anything from the seam file — that import removed.
**Analyze-clean is the completion signal**, which is what makes this decidable
rather than a judgement call per file.

Use the language server, not `sed` and not hand edits. Across 34 names and
roughly 50 files, a hand edit is exactly where a wrong-value substitution hides,
and a wrong-value substitution is invisible to the type checker because every
one of these names is a `Color` or a `TextStyle`.

### The proof

Behaviour is unchanged, so there is no Red and no new test. The proof is:

1. `flutter analyze` clean;
2. `grep -n "Color(0x\|const Color" lib/game/crawl_style.dart lib/town/town_style.dart`
   returns **nothing** — neither seam declares a colour at all. That closes
   **AC3** more strongly than Task 07 did;
3. `grep -n "TextStyle" lib/game/crawl_style.dart lib/town/town_style.dart`
   returns only the four kept crawl declarations — four, not five, since A7
   moved `crawlChevron` to the delete list;
4. Task 07's closing greps 3 and 4 re-run, because Task 08 rewrote exactly the
   files they cover;
5. **the full suite green with no test edited except by the rename and its
   imports.** If a test needs a *substantive* edit — a changed expectation, a
   changed finder, a changed value — the rename was not mechanical and the
   executor **escalates instead of improvising**. That rule is the whole
   safety property of this task.

### One required correction, not optional

`crawl_surfaces_test.dart:297-300` asserts
`appBar.backgroundColor == town.panel` and `foregroundColor == town.ink`, and
its comment says "the town's own panel and ink, hardcoded regardless of the
ambient theme the crawl scoped over its own subtree". After Task 08 the
prefix is gone and the assertion reads `expect(appBar.backgroundColor, panel)`
— there is no longer any way for the code to express "the town's, not the
crawl's", because there is one theme. **Correct that comment in Task 08** to
say what the test now defends: that the pack route pushed from the crawl is
inside a theme at all and renders on the shared panel surface. This upgrades
residual R4 from "recommended at Gate B" to "required here"; the assertion
itself does not change.

### Agent recommendation

**`flow-plan-executor`, not `sonic`.** The task is mechanical in each step but
not a single mechanical leaf:

- it carries a real keep/delete judgement per name — the rule is decidable, but
  applying it still requires reading what a name says;
- the 34 names split into two procedures, and a leaf agent would likely flatten
  the four colliding names into the thirty-name shape and produce
  `const Color ink = ink;`;
- its correctness argument is "no test needed a *substantive* edit", which
  requires recognising when an edit is substantive. That is precisely the
  judgement `sonic` is not for, and getting it wrong looks like success.

The brief is written to the same standard as 01–07 so it can go to either.

---

## The dp gate

Not a task. Measured inside Task 02, where the crawl's chrome changes, and
**re-confirmed on the final tree at Gate A**.

### The three densities

Named by the contract, and each already has a scene builder in
`test/widget/crawl_action_row_test.dart`:

| density | builder | what it is |
|---|---|---|
| exploration | `_explorationWorstScene()` (`:211`) | stairs landing, gather node and items underfoot, three note rows |
| typical combat | `_combatTypicalScene()` (`:138`) | open battle, four known spells, a potion carried |
| worst legal combat | `_combatWorstLegalScene()` (`:171`) | the eleven-chip ceiling: `readiedSpellCount` 3 readied spells plus the `+n` overflow, Drink, Wait, and every exploration verb that survives the merge |

### The method

`_chromeHeight` (`crawl_action_row_test.dart:376-381`):
`surfaceHeight − mapHeight`, where `mapHeight` is
`tester.getRect(find.byKey(dungeonSceneSlotKey)).height` at `onAPhone`
(`test/support/phone.dart`: 1080 × 2424 physical at DPR 2.625 = 411.4 × 923.4 dp
with no system insets). **Chrome, never map** — chrome is inset-independent and
therefore the same number in the widget-test host and on `Medium_Phone`, which is
what makes the two comparable at all (Unit 12's plan established this).

On device, the same three densities are constructed by play and read from the
`Medium_Phone` capsules, as U13.1 did for its 580.95 dp figure.

### The agreement claim, and what it proves

U13.1's divergence was 208.43 dp of test-host map against 285.33 dp on device —
the Ahem 1.0 em advance against Roboto Mono's ~0.6 em (F4). With both faces
bundled **and registered in the test host**, the same `TextPainter` measures the
same face on both, so:

> **Gate A records, per density, the widget-test chrome and the device chrome,
> and states the difference.** Expected agreement is within 2 dp. A divergence
> above that is the first thing the receipt must explain, and the most likely
> explanation is F3: `✳ ✚ ⛒` are absent from Spectral, so the three spell chip
> labels measure through a platform fallback whose advance differs between hosts.
> That affects `_combatTypicalScene` and `_combatWorstLegalScene` only.

### The existing caps, and what they become

`crawl_action_row_test.dart:501-540` asserts widget-test chrome
`≤ 360 / ≤ 560 / ≤ 720` dp for the three densities. Those ceilings were sized
for Ahem's 1.0 em metrics and become meaningless once the real face resolves —
they would pass trivially and prove nothing.

**Task 02 re-derives all three from its own measurements**, each set to the
measured value rounded up to the next 10 dp plus 20 dp of headroom, and records
the measured figures in its receipt. The device figures go in the ledger at
Gate C.

### The plan's expectation, and the arithmetic behind it

Not locked. The executor records measured values; this is what the plan expects
and why, so a surprise is recognisable as one.

The action row at worst legal density, from `_fitFor`'s own formula
(`crawl_action_row.dart:205-210`, with the word guard at `:193`):
`chipHeight = 2·6 + 18 + 4 + labelBlock + captionHeight`.

- the word guard (`:191`) tests `content + 0.5 ≥ widestWord`.
  `Firebolt` in `textLabelStrong` measures 3.66 em × 13 px ≈ 47.6 dp, against
  8 × 7.2 = 57.6 dp in today's device monospace — so **five columns becomes
  reachable** where four was the best legal count;
- at five columns on 411.4 dp: chip width `(411.4 − 6·4)/5 = 77.5`, content
  `77.5 − 16 = 61.5 dp`. `✳ Firebolt 2` ≈ 73.6 dp (with `✳` measured at a
  fallback ~1.0 em) so it takes two lines: `labelBlock = 2 × 15.6 = 31.2`;
- `captionHeight` = 11 px × 1.20 = 13.2 dp, against today's 11 × 1.32 = 14.52;
- `chipHeight = 12 + 18 + 4 + 31.2 + 13.2 = 78.4`; eleven chips over five
  columns is three runs: `3 × 78.4 + 2 × 4 = 243.2 dp`.

Elsewhere: `CrawlStatus` falls from ~51.3 to ~49.2 dp (a 15 px display header
line at `height: 1.20` is 18.0 dp against monospace's 19.8); the timeline panel
is flat to −1 dp per caption and word row; `LogPeek` is a fixed 104 dp slot and
does not move; the three note rows rise ~1.7 dp each, because `crawlBodyDim`
goes from 12 px to `textLineDim` at 13 px.

**Net expectation: flat to roughly −10 dp of chrome at every density, with worst
legal combat landing near 570 dp against the 600 dp ceiling.** The whole of that
result comes from F5's explicit heights. Without them Spectral's own 1.522 em
line box would add ~15% to every text row and put worst legal combat near
668 dp — over the ceiling, with the map under 7 rows of sight.

### What the executor may tune, and what escalates

Constants only, no structural change, inside these envelopes:

| constant | envelope |
|---|---|
| `textLabel` / `textLabelDim` / `textLabelStrong` `height` | 1.15 – 1.25 |
| `textCaption` `height` | 1.15 – 1.25 |
| `textLineDim` size | 12 – 13 |
| `textDetail` size | 10 – 11 |
| `displayCaption` `height` | 1.20 – 1.30 |
| `displayRoom` / `displayPanel` `height` | 1.15 – 1.25 |
| the three re-derived chrome caps | upward only, with the measured figure recorded |

**Escalate to the architect, do not decide:**

- **worst legal combat above 600 dp on device.** This is a stop-and-escalate,
  not an executor's judgement call and not a tuning target. The remedies —
  shrinking `crawlLogPeekHeight`, scrolling the action row, hiding a verb,
  shortening a label, ellipsising anything, dropping the armed reserve, changing
  `crawlChipMaxColumns` or `crawlChipMaxLabelLines` — are all scope or contract
  changes and all belong to U15 or to a contract amendment;
- widget-test and device chrome disagreeing by more than 2 dp at a density with
  no spell chip in it (the F3 explanation does not cover that case);
- any need to change `_fitFor`, `_RowFit`, `_ActionChip` or a chip metric
  constant — U15 owns the fit rule;
- any need to raise a type role's **size** outside the envelopes above to make
  something fit.

---

## Red/Green proof map

Every task writes its behavioural Red before production change and records the
observed failure. No golden images. No source-text assertions. No assertion of a
widget type, a literal colour, or a field being forwarded. Where a test must
name a presentation value it compares against **the token's named constant or
another rendered value**, never a hex or a size literal.

### Task 01 — new `test/style/type_authority_test.dart`

1. **The text face resolves in the test host.** A `TextPainter` over
   `'iiiiiiiiii'` in `textLabel` is strictly narrower than one over
   `'MMMMMMMMMM'` in `textLabel`. Under Ahem every glyph is the same em square,
   so the two are *exactly equal*; under Spectral they are 0.313 em and
   0.959 em per glyph. **Expected Red: equal.** The same assertion for
   `displayTitle` proves the display face.
   This is the whole of F4's claim reduced to one host-agnostic inequality, and
   it is the assertion that stops the suite from silently reverting to Ahem
   metrics if `flutter_test_config.dart` is ever lost.
2. **Glyph coverage, per mark.** Under `--use-test-fonts` the only fallback is
   the test font, whose advance is exactly `fontSize`. So for each mark the app
   draws, lay it out alone in `textFace` at `fontSize: 100` and assert
   `painter.width != 100.0` for every covered mark, and `== 100.0` for exactly
   the twelve of F3. The expected-absent set is written out in the test, so a
   font swap that *loses* `†` or `◆` fails, and one that *gains* `✳` fails too
   and is a welcome failure. Caveat recorded in the test: a covered glyph whose
   advance were exactly 1.000 em would read as absent; the widest glyph in
   Spectral is `W` at 0.981 em, so none is.
   **Expected Red: the file does not exist.** Written against the committed
   assets, it is green on first run — it is a coverage *record*, and its value is
   the day someone changes a font file.
3. **Every exported role satisfies the invariants.** Over the exported role
   list: `inherit == false`, `fontFamily` is one of the two families,
   `height != null`, `color != null`, and the feature list matches the role's
   register (text → `tnum`; display → `lnum` + `tnum`). A role added later
   without a family would silently fall back to Ahem in tests and to the
   platform default on device; this is the only thing that catches it.
4. **The boot failure screen renders no M3 default.** `Begin fresh`'s rendered
   fill equals `raised` and is not
   `ThemeData(brightness: Brightness.dark, useMaterial3: true).colorScheme.primary`
   — computed live from a bare `ThemeData` inside the test, so the assertion
   never hardcodes lavender and survives a framework palette change.
   **Two assertions, not three: A6 struck the fill-versus-surface luminance
   ratio here, where it originated.** Task 01's executor found it unsatisfiable
   under the WCAG reading (1.153 : 1 for `raised` on `ground`), adopted a plain
   `Lmax/Lmin` reading that cleared 1.5 for this one screen, and reported it —
   which is what exposed the defect before Task 04 inherited it. See
   §"Why there is no third, fill-versus-surface contrast assertion (A6)".
   **Expected Red: the fill equals the M3 default.**

Must stay green: `test/widget/boot_failure_screen_test.dart` (string-only, so it
passes throughout and is the regression proving the three style folds changed no
reading), and the full suite — which is the real Red risk of this task, because
registering the faces changes every measured paragraph in it at once.

### Task 02 — `test/widget/crawl_action_row_test.dart`, `crawl_status_test.dart`

Rewritten:

- the three chrome caps at `:501-540` become the re-derived figures, with the
  measured chrome recorded in the receipt. The test still defends "chrome stays
  within its budget at three named densities" — the number changes, the
  behaviour does not;
- `_expectLegalRow` (`:314-333`) and `_expectRunCapacity` (`:339-374`) are
  untouched and are the regression that proves the new metrics broke no word,
  clipped no paragraph and left the runs even.

Added, in `crawl_action_row_test.dart`:

- **the widget-test/device agreement handle**: the measured chrome for all three
  densities is `print`ed through the `reason:` of its own assertion, as the
  existing caps already do, so Gate C can compare without re-deriving.

Must stay green: `crawl_status_test.dart` (strings, meter keys, progress values,
the worst-case no-squeeze loop at `:350-366`), `crawl_layout_test.dart`,
`log_drawer_test.dart` (including the relative-luminance assertions at
`:256-260`, which are the regression proving the colour aliases changed no
reading), `battle_view_test.dart`, `crawl_controls_test.dart`,
`craft_surfaces_test.dart`, `crawl_surfaces_test.dart`,
`dungeon_scene_bleed_test.dart`, `disabled_controls_test.dart`.

**The real Red here is `takeException(), isNull`.** Sixteen sites across the
suite assert no overflow (`crawl_status_test:350`,
`crawl_action_row_test:332,595`, `crawl_controls_test:264,283`,
`craft_surfaces_test:206`, and ten in `log_drawer_test`). Any of them can fire
on a type-metric change, and each firing is a real defect, not a test problem.

### Task 03 — new `test/style/resource_meter_test.dart`, and `crawl_status_test.dart`

1. **The meter's greyscale reading loses nothing.**
   `|L(meterHealthFill) − L(meterManaFill)| < 0.02`, and each fill's **WCAG**
   contrast `(L+0.05)/(l+0.05)` against `rule` is ≥ 4.5 : 1 — measured 5.587 : 1
   and 5.500 : 1, so the threshold has real headroom rather than sitting on the
   edge. That is the accessibility contract stated as arithmetic: the two
   meters are indistinguishable from each other in greyscale, and both are
   clearly distinguishable from their track.
   **This threshold survives A6 and the ladder's problem does not reach it**,
   because a meter fill is a bright accent (`L` 0.382 and 0.375) against a dark
   track (`L` 0.027), not one dark ladder step against another. A6 struck a
   *contrast* claim between two adjacent ladder values; this is a contrast
   claim between an accent and the ladder, and it clears by 24%.
   **Expected Red: the constants do not exist.**
2. **Hue is reinforcement.** For a meter at a given value, the rendered text
   contains the label word, the value and the ceiling, and the rendered
   indicator's `value` equals `value / ceiling`. Removing the fill colour from
   the assertion changes nothing about what the test can still read — which is
   the property AC6 asks for.
3. **The health and mana meters differ by more than their hue.** In one crawl
   scene, the HP meter and the mana meter render different label words and
   different numbers, and their two fills are not equal — but the test asserts
   the *words and numbers*, so it would still pass with both fills identical.
4. **Boundary behaviour**: `ceiling == 0` renders a zero-fill bar and does not
   divide by zero; `value > ceiling` clamps the fill to 1.0 and still prints the
   true value. Both are live paths in `crawl_status.dart:134` and `:149`.

Rewritten in `crawl_status_test.dart`: any assertion reading the removed private
`_Meter` becomes the same assertion through `ResourceMeter`, by the unchanged
`hpMeterKey` / `manaMeterKey`. `depthPairKey`, `_placeName`, `_battleWord`,
`_condition`, every `FittedBox`, the 18 dp glyph cell, the 64 dp depth cell and
the 8/6/6 flexes are unchanged.

### Task 04 — new `test/style/material_palette_test.dart`

**This is AC4's test, and it is the unit's most important new one.**

For each of F9's ten control families, in a real pumped screen, **two
assertions — and deliberately only two**:

1. the rendered fill (or foreground, for a text control) equals the token the
   theme specifies — read from the `Material` the control builds, or from the
   rendered `DefaultTextStyle`, never from a constructor argument;
2. it is **not** the corresponding colour of
   `ThemeData(brightness: Brightness.dark, useMaterial3: true)` — `primary` for
   filled buttons and text buttons, `secondaryContainer` for the selected chip,
   `surface` for the dialog, `primary` for the input's focused border and
   cursor. The reference `ThemeData` is built inside the test, so no lavender
   hex is ever written down and a framework palette change cannot make the test
   lie.

#### Why there is no third, fill-versus-surface contrast assertion (A6)

An earlier draft of this plan asked each family to assert that its rendered
fill's luminance differed from its surface by a ratio ≥ 1.5 : 1. **That
assertion was struck by architect ruling on 2026-09-18, after Task 01 found it
unsatisfiable.** The arithmetic, verified independently three times — by the
Task 01 executor, by the architect, and by this planner:

| pair | WCAG `(L+0.05)/(l+0.05)` | plain `Lmax/Lmin` |
|---|---:|---:|
| `raised` `#1B1F27` vs `ground` `#0E1014` | 1.153 : 1 | 2.643 : 1 |
| `raised` `#1B1F27` vs `panel` `#15181F` | 1.076 : 1 | **1.491 : 1** |
| `recessed` `#11141A` vs `panel` `#15181F` | 1.038 : 1 | 1.313 : 1 |
| `armedFill` `#262B35` vs `raised` `#1B1F27` | 1.163 : 1 | 1.763 : 1 |

Under the WCAG reading the whole ladder caps near 1.15 : 1 whatever the fill
is, because the `+0.05` flare dominates at these luminances. Under the plain
reading the boot screen clears 1.5 (`raised` on `ground`, 2.643) but **every
control seated on `panel` does not** — 1.491 for `raised`, 1.313 for
`recessed`. Several of the ten families sit on `panel`, so Task 04 would have
hit it, and the obvious executor response is to lower the threshold until it
passes. That turns the assertion into decoration and teaches U15 through U21
that thresholds are negotiable.

**It is also wrong about the design.** This value ladder is deliberately
low-contrast. A control's boundary comes from its 1 dp `rule` border — the
ladder's one genuinely separated step, 1.308 : 1 WCAG and 2.997 : 1 plain
against `panel` — not from fill-against-surface contrast. Assertions 1 and 2
carry all of AC4's content: they are host-independent, cannot be satisfied by
accident, and cannot be satisfied by tuning a number. A third that can only be
satisfied by lowering itself adds nothing.

**Do not reintroduce a fill-versus-surface contrast threshold against this
ladder in any later unit.** If a control's boundary ever needs proving, prove
the border, not the fill.

The four named cases are covered explicitly and by name: character navigation
(`character-route-gear|spells|skills|pack`), the pack filter chips
(`pack-filter-all` selected and `pack-filter-potions` unselected), the Forge's
`Smelt` (`Commit`), the Tavern's `Ask` (`ItemRow`). The six unnamed ones —
`WorldDoor`, `Take off`, the pack row actions, the four dialogs, the roster
`TextField`, `Begin fresh` — are covered in the same table.

**Expected Red: assertion 2 fails for all ten, because every one of them renders
the M3 default today.** Assertion 1 fails because the tokens are not applied.
Those two are the whole of it — there is no third to fail.

Added: the selected `ChoiceChip` still renders its checkmark — the non-hue cue
that carries selection, because `selectedColor: armedFill` against
`backgroundColor: raised` is only a 1.163 : 1 WCAG (1.763 : 1 plain) value step
and the filter chip's own form belongs to U15 (gap 8.1).

Must stay green, and these are why the theme-not-replace decision matters:
`character_screen_test.dart:218` (`widget<FilledButton>`),
`pack_screen_test.dart:96-97,171,452,455,528,647,692` (`widget<ChoiceChip>`,
`widget<TextButton>`), `bank_screen_test.dart:145,153,181,185,206,220,236,250`
(`widget<FilledButton>`, `widgetWithText(FilledButton, …)`),
`craft_rooms_test.dart:136,290,505,549,679`, `crawl_surfaces_test.dart:298-299`
(`appBar.backgroundColor == town.panel`), `roster_screen_test.dart`,
`tavern_screen_test.dart`, `merchant_screen_test.dart`, `town_shell_test.dart`,
`town_illustration_test.dart`, `world_screen_test.dart`,
`count_stepper_test.dart`. **Every stock control stays the stock control it is
today and is themed, not replaced** — which is both what the non-goals require
("no chip restructuring", control geometry is U15's) and what keeps all
twenty-six of those finders valid.

### Task 05 — `character_screen_test.dart`, `town_shell_test.dart`

Rewritten, and these two are the unit's only genuine test rewrites:

- `character_screen_test.dart:111-118` pins
  `find.text('Health   ${hp}/${maxHp}')` and
  `find.text('Mana     ${heroMaxMana(loadout)}')` — exact padded strings. Both
  become meter assertions: under the health meter's key the rendered text
  carries the hero's hp and their ceiling, and the rendered indicator's `value`
  equals `hp / maxHp`; likewise mana. What the test defends is unchanged — *the
  character screen states the hero's health against its ceiling* — and the
  padding it used to pin was a monospace artefact;
- `character_screen_test.dart:96-110,119-123` pin `Attack   n-n`,
  `Armour   n`, `Dodge    n%`, `Speed    n`, `Spells known    n`,
  `Skills trained  n/n`. Each becomes a `LabelledValue` assertion: the label and
  its value both render, under the same row. Same defended behaviour, no
  padding;
- `town_shell_test.dart:190-193` pins `Health   ${hp} / ${maxHp}`,
  `Carried  12 gold`, `Banked   40 gold` with the comment "verbatim including
  their double spaces". Health becomes the meter assertion; carried and banked
  become `LabelledValue` assertions. The comment goes with the padding.

Added: the label column holds still — for the three town-screen rows and the
six character rows, every value's rendered `left` is identical, which is what a
fixed-width slot means and what a padded string never delivered in a
proportional face. **Expected Red: the values' lefts differ**, because today
they are one padded string each and `find.text` finds one paragraph.

### Task 06 — new `test/widget/world_diagram_fit_test.dart`

1. **No diagram label is clipped.** At `onAPhone`, with every node discovered
   and a journey in progress so that `TRAVEL IN PROGRESS` and
   `NO ROAD FROM HERE` both render, every `RenderParagraph` under a
   `world-node-*-shape` key and every route label has
   `didExceedMaxLines == false`, and `takeException()` is null. F8 is the whole
   reason this test exists: a 120 dp box, `TextOverflow.clip`, `maxLines: 1`,
   and a face whose caps are 12% wider than the one it replaces.
   **Expected Red: it passes before and after**, and is the regression that
   proves the 9 px micro rung was the right choice. If it fails Green, the
   escalation is to keep 9 px and shorten nothing — the strings are the game's
   own words.
2. **The world screen renders no M3 default.** `WorldDoor` and both dialogs,
   asserted the same way as Task 04's table.

Must stay green: `world_screen_test.dart` in full, including
`:324,1689`'s `takeException` checks and `:666,733`'s `scrollUntilVisible`.

### Task 07 — the closing audit, recorded in the receipt

```text
grep -rn "fontFamily: '"  packages/app/lib --include=*.dart
grep -rn "monospace"      packages/app/lib --include=*.dart
grep -rn "Color(0x"       packages/app/lib/game/crawl_style.dart packages/app/lib/town/town_style.dart packages/app/lib/main.dart
grep -rn "TextStyle("     packages/app/lib --include=*.dart
```

Expected: the first two return **nothing** — that is **AC2**. The third returns
nothing. The fourth returns only `lib/style/tokens.dart` and
`lib/game/dungeon_scene.dart` (the two cell-derived glyph paints, whose sizes
cannot be tokens).

`dungeon_palette.dart`, `dungeon_render_style.dart`, `dungeon_scene_material.dart`
and `glyph_plan.dart` carry Unit 11's renderer palette and are excluded from the
third and fourth greps by path.

### Task 08 — the rename audit, recorded in the receipt

Behaviour-neutral, so no Red. Task 08 rewrites exactly the two files greps 3
and 4 above cover, so **it re-runs them** and adds its own:

```text
grep -n  "Color(0x\|const Color"  packages/app/lib/game/crawl_style.dart packages/app/lib/town/town_style.dart
grep -n  "TextStyle"              packages/app/lib/game/crawl_style.dart packages/app/lib/town/town_style.dart
grep -rn "Color(0x"               packages/app/lib/game/crawl_style.dart packages/app/lib/town/town_style.dart packages/app/lib/main.dart
grep -rn "TextStyle("             packages/app/lib --include=*.dart
```

Expected: the first returns **nothing** — neither seam declares a colour at
all, which closes **AC3** more strongly than Task 07's grep did. The second
returns only the four kept crawl declarations (`crawlChipLabel`,
`crawlChipLabelDisabled`, `crawlChipLabelArmed`, `crawlCaption`). A7 moved
`crawlChevron` off this list and A13 recorded the corrected count. The third
and fourth match Task 07's expectations unchanged.

And the proof that carries the whole task: **`flutter analyze` clean, and the
full suite green with no test edited except by the rename and its imports.** A
test needing a substantive edit is an escalation, not a fix.

### The standing guard

Two steps appended to the `app` leg of `.github/workflows/ci.yml`, after
`analyze`:

```yaml
      - name: type authority gate
        if: matrix.package == 'app'
        working-directory: packages/app
        run: |
          if grep -rn "fontFamily: '" lib --include='*.dart'; then
            echo "a screen declares its own font family; every text style comes from lib/style/tokens.dart"
            exit 1
          fi
          if grep -rn "monospace" lib --include='*.dart'; then
            echo "monospace was retired in unit 14 and does not come back"
            exit 1
          fi
```

It forbids the family **literal**, not the token reference, so
`dungeon_scene.dart`'s `fontFamily: textFace` passes and
`fontFamily: 'Spectral'` does not. This is CI, not a test, so it asserts nothing
about behaviour and does not offend the repository's test doctrine — and it is
the only mechanism that makes U15 through U21 unable to reintroduce either. A
matching line goes into `AGENTS.md`'s app section so the rule is discoverable
before CI teaches it.

### Package gates

Every task runs its focused command, then from `packages/app`:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Task 01 additionally runs `flutter pub get` after editing `pubspec.yaml` and
confirms `pubspec.lock` is unchanged (`git diff --exit-code -- pubspec.lock`),
because CI gates on exactly that.

---

## Gate B — integrated acceptance and correction barrier

After Task 08, the controller reruns the three package gates on the integrated
tree, reruns Gate A's dp measurement on the final tree, and audits the complete
diff:

- no `packages/core` or `packages/content` change — **especially no marking
  constant**;
- no save, balance, generation, RNG, bloc or event change;
- no `MaterialApp.theme` carrying a restyle;
- no change to `_fitFor`, `_RowFit`, `_ActionChip` or a chip metric constant;
- no change to `cameraCellSize`, `glyphBaseFontScale`, the `* 0.30` badge
  derivation, or anything in `dungeon_scene.dart` beyond the two family
  literals and Task 08's rename;
- no change under `dungeon_*`, `glyph_*`, `grid_geometry.dart` or `art/` beyond
  Task 08's rename;
- no new package dependency, no `ThemeExtension`, no `InheritedWidget`, no
  golden-image test;
- no per-build `ThemeData` allocation and no `TextPainter` allocated outside
  `_fitFor`'s one measurement pass;
- every player-facing string unchanged except the **eighteen** padded-label
  rows of F7 that `LabelledValue` and `ResourceMeter` decompose — thirteen
  rendered as `LabelledValue` and five absorbed into a meter, across the six
  sites F7's own table lists, including the two in `inn_screen.dart` that A3
  authorised. The earlier figure of eleven did not match F7's own table and
  would have had a reviewer either raise seven false findings or wave a real
  string change through while counting to eleven;
- **Task 08's diff is behaviour-neutral**: read it as a rename, and confirm no
  test carries a substantive edit. A changed expectation, finder or value
  inside Task 08's commit is a must-fix finding, not a style preference.

Then one independent acceptance review:

- **COR** — every guard, dispatch, key, semantic label and string that must
  survive did; the twelve uncovered marks render from platform fallback exactly
  as before; the meter's hue carries nothing the label and number do not;
  `error: ink` in the scheme reaches no rendered surface; the four root-navigator
  dialogs wrap their own theme; the disabled state of every stock control still
  reads dimmer than its enabled state.
- **TTC** — each of the eleven acceptance criteria maps to a named behavioural
  proof or a named device capsule; the four rewritten test sites assert
  behaviour, not padding or literals; no padded or tautological test was added;
  the expected Red was observed and recorded per task.
- **CRF** — one token module, one shared widgets file, one theme, six opt-in
  sites; the two seams are aliases with no literal left; twenty roles with
  named consumers and no declared-but-unused member at any handoff; no
  `copyWith` of a token anywhere, the rule itself struck by A8 after it
  produced two compile-breaking defects.
- **SEC — SKIP.** Presentation-only, offline, no new input, file, network or
  trust boundary. The only new bytes are three OFL-licensed font files whose
  provenance and md5 are recorded above. Any security need contradicts scope and
  escalates.

Close every must-fix finding before device installation. Any later production-,
asset- or build-affecting correction reopens the affected package proof, Gate A,
and a scoped acceptance review before device evidence may be accepted.

---

## Gate C — the device pass

The closing gate, on `Medium_Phone`, only after Gate B. It carries three
inherited duties.

1. **Back up both save slots and record byte hashes, before any install.** The
   live save is `app_flutter/save.json` — **not** `files/app_flutter/save.json`;
   the device path trap is on record and misreading it backs up nothing. The
   app's own rotation drifts the previous slot during play, so both slots are
   captured before the first launch of the new build and **restored from the
   backups, never from the device**.
2. Install the accepted build.
3. Capture every capsule below in colour **and** greyscale.
4. If needed, at most **one** constants-only tuning pass inside the envelopes in
   the dp gate.
5. Rerun all focused and package evidence traversed by those constants, plus
   Gate A and a scoped acceptance review; recapture affected capsules.
6. Restore both slots and verify the restored bytes match the pre-install hashes
   under the same comparison scheme.

| capsule | screen / scene | settles |
|---|---|---|
| A | town (Stonebridge), with materials and a notice | AC2, AC3, AC8, gap 1.2; `LabelledValue` columns holding |
| B | character | AC4 (navigation), AC6 (meters), AC8, gap 6.4 |
| C | pack, `All` and one filtered view | AC4 (filter chips), AC8, gap 8.x type only |
| D | Forge | AC4 (`Smelt`), AC8, gap 9.5 |
| E | Tavern | AC4 (`Ask`), AC8, gap 10.7 |
| F | spells, skills, gear, inn, bank, merchant, alchemist, roster | AC2, AC4, AC8 — **the roster's first visual baseline in this epic** |
| G | **world map**, every node discovered, a journey in progress | AC2, AC4, AC8, F8's clip risk — **the world map's first visual baseline in this epic** |
| H | crawl, exploration at worst density | AC2, AC6, AC7 (exploration), AC8 |
| I | crawl, typical combat | AC6, AC7 (typical combat), AC8 |
| J | **crawl at ceiling density** — the eleven-chip worst legal combat | AC7's ceiling, and **U13.1's hardware confirmation: if the `BattleDock` is covered here, U13.1 reopens** |
| K | expanded log at half and full extent | AC2, AC8, gap 5.4; the twelve fallback marks of F3 rendering, not tofu |
| L | the two crawl sheets, the completion confirm, the death overlay, the roster delete dialog, the roster name dialog, the world travel dialog | AC4 (dialogs, `TextField`), AC5 |
| M | dungeon map with the hero, a monster, a stair and a litter glyph in view | the map glyph on the new face at `cameraCellSize * 0.73`, AC8, and that the superscript ordinal badge still reads at `* 0.30` |

Record, per capsule: the measured chrome for H, I and J against the widget-test
figures from Gate A; whether any label ellipsised or clipped; whether any of
F3's twelve marks rendered as tofu; and which weight the display face resolved
to. Compare A–M against the ten mock frames on type register, hierarchy,
contrast and control clarity — the mock is directional, not a pixel target.

**Any tofu, any clipped diagram label, or worst legal combat above 600 dp is a
stop-and-escalate.**

---

## Acceptance criteria coverage

Every criterion in `CONTRACT.md` maps to a task, a named proof and a gate. No
criterion is left to be noticed at the end.

| AC | closes at | proof | gate |
|---|---|---|---|
| 1 — both families bundled with `OFL.txt`, declared, weight budget stated with its reason | Task 01 | the md5 table in the receipt; the `fonts:` block; the weight-budget reason recorded in `../PLAN.md`'s "Font assets" section and repeated in `tokens.dart`'s display dartdoc | B |
| 2 — two roles in one module; no screen declares `fontFamily`; **`'monospace'` greps to nothing** | Task 07 | `type_authority_test.dart` group 3 (role invariants) + the four closing greps + the CI type authority gate | B |
| 3 — one module owns the value ladder; neither seam declares a duplicate literal | **Task 08** (Task 07 gets it partway) | Task 07's closing grep 3, then Task 08's stronger form: `crawl_style.dart` and `town_style.dart` declare **no `Color` at all** and no bare-renaming `TextStyle`, with `flutter analyze` clean and the full suite green on a behaviour-neutral diff | B |
| 4 — **no stock Material control renders in the M3 default palette; a test fails if one does**; the four named cases | Task 04, extended by 06 | `material_palette_test.dart`'s eight-row table with the four named cases in their own groups, each asserting against a live-computed bare `ThemeData`; `world_diagram_fit_test.dart` group 2 for the world's three; `type_authority_test.dart` group 4 for the boot screen | B |
| 5 — `MaterialApp.theme` restyles no stock control; each screen root opts in | Tasks 01, 02, 04, 06 | the six opt-in sites, enumerated and diffable; `main.dart`'s two `MaterialApp.theme` arguments provably still bare; the Gate B diff audit | B |
| 6 — one meter serves crawl, character and town; hue is reinforcement, proved by a greyscale render | Tasks 03 and 05 | `resource_meter_test.dart` groups 1–4; the three consumers' key-addressed assertions in `crawl_status_test.dart`, `character_screen_test.dart`, `town_shell_test.dart` | B, and capsules B, H, I |
| 7 — **dp budget re-measured at three densities; worst legal combat under 600 dp**; figures in the ledger; wrap change stated | Task 02, re-confirmed at Gate A | `crawl_action_row_test.dart`'s three re-derived caps with measured figures; the Ahem-era/Spectral-era pair per density; the device figures from capsules H, I, J | A, C |
| 8 — every screen reads in greyscale, including the new meter hues | every task | `resource_meter_test.dart` group 1 as arithmetic (`\|ΔL\| < 0.02` between the fills; each fill ≥ 4.5 : 1 WCAG against its track); `crawl_action_row_test.dart:442-471`'s chip-state luminance ladder, which is a strict ordering and carries no ratio; `log_drawer_test.dart:256-260`'s relative contrast. **No fill-versus-surface ratio anywhere — A6 struck it as unsatisfiable against this ladder.** The greyscale *reading* is a device judgement, not a suite one | C, capsules A–M in greyscale |
| 9 — broken tests rewritten to behaviour, not re-pinned; the unit lists which and what each now defends | Tasks 02, 05, 06 | three rewrite sites only: `crawl_action_row_test.dart`'s three caps (numbers, not behaviour), `town_shell_test.dart:179-196` and `character_screen_test.dart:83-140` (padded strings → the facts they defended), plus at most three padded rows in `world_screen_test.dart`. Each task receipt states before, after and what it now defends; the list is assembled at Gate B | B |
| 10 — `dart format`, `flutter analyze`, full `flutter test` pass from `packages/app` | every task, integrated at Gate B | the three package gates per task, rerun on the integrated tree | B |
| 11 — device evidence in colour and greyscale, with the three inherited duties | Gate C | the thirteen capsules A–M; capsule J carries U13.1's hardware confirmation, G and F carry the world map's and the roster's first baselines, and both save slots are hashed before install and restored from the backups | C |

Two criteria are deliberately **not** closed by the suite alone, and the plan
says so rather than implying otherwise: AC8's greyscale judgement needs a
capture at device brightness (the tests prove the value ordering exists, not
that a reader sees it), and AC7's ceiling needs a device figure (the suite caps
chrome; only the device says whether the remaining map reads as a dungeon).

## Completion and integration boundary

After final acceptance the controller may update the canonical LDD records: the
ledger entry, the dp figures at all three densities on both surfaces, the list
of rewritten tests and what each now defends (AC9), the weight budget and its
reason (AC1), the twelve platform-fallback marks A2 recorded, and the
boundary A3 widened. PR, push, review publication, merge and every other remote
action still require explicit user approval.

Suggested separable implementation commits:

1. `feat: bundle the two authored faces and one token module`;
2. `feat: move the crawl seam onto the shared tokens`;
3. `feat: give the app one resource meter`;
4. `feat: give the town a theme and take the lavender out`;
5. `feat: align the town's numbers by layout, not by padding`;
6. `feat: move the world seam onto the shared tokens`;
7. `feat: retire monospace and guard its absence`;
8. `refactor: one name per value across both style seams`.

Commit 8 is the only `refactor:` in the unit and carries no behaviour change;
keeping it separate is what lets a reviewer read it as a rename.

Commit wording is discretionary; task boundaries are not.

---

## Plan quality gate

- **COR — PASS.** The three facts that would have derailed execution were found
  and settled before it: `flutter test` forces Ahem so bundling alone does not
  close U13.1's divergence (F4, settled by a `FontLoader` in
  `flutter_test_config.dart`); Spectral's own line box is 1.522 em and would
  have breached the dp ceiling on its own (F5, settled by an explicit `height`
  on every role); and the faces are missing twelve marks, seven of them defined
  in `packages/core` which this unit may not touch (F3, settled by changing no
  mark, proving the coverage, and naming the one measurement consequence). The
  lavender census is complete at ten families, not four, and one `colorScheme`
  is the field that catches the eleventh nobody enumerated. The dialogs' root-
  navigator topology is handled by construction. Tabular figures were verified
  in the binaries rather than assumed, and turned out to be a no-op against
  Spectral's already-tabular defaults — which is why the fixed-width slots in
  this plan exist for F7's reason and not the font's.
- **TTC — PASS.** Every acceptance criterion maps to a named proof or a named
  device capsule. AC4 becomes a real failing-then-passing test that computes the
  M3 default live rather than pinning lavender, and covers all ten control
  families including the four named cases. AC6's greyscale claim becomes
  arithmetic — `|ΔL| < 0.02` between the two fills, ≥ 4.5 : 1 WCAG against the
  track, both with headroom. A6 then struck AC4's fill-versus-surface ratio as
  unsatisfiable against this ladder and recorded the arithmetic so no later
  unit reintroduces it; every surviving luminance claim in the plan is either a
  strict ordering or an accent-against-ladder contrast, and each is now labelled
  with its reading.
  AC7's two surfaces are measured by the same method and their agreement is
  itself the evidence that F4 closed. The four test rewrites are named with the
  behaviour each must assert, and the one whose *reason* would have changed
  (`crawl_surfaces_test.dart:297-300`) is avoided by keeping the `AppBar`
  colours at their call sites. Expected Red is stated per task, including the
  honest note that Task 01's face-resolution test is the only Red that matters
  there and that the suite-wide metric shift is that task's real risk.
- **CRF — PASS.** Eight sequential slices, each with its own Red→Green cluster
  (Task 08's is behaviour-neutral by design) and a compiling handoff whose
  focused tests pass. One token module, one shared widgets file, one theme, six
  explicit opt-in sites, twenty roles each with named consumers. The alias
  strategy is what keeps nine production files at zero edits and twenty-six
  existing widget-type finders valid through Tasks 01–07; **architect amendment
  A4 then retires it in Task 08**, so the end state is one name per value plus
  a seam declaration only where the seam has something of its own to say —
  which is a materially better six-month outcome than the aliases this planner
  proposed keeping. Three identical sibling `ThemeData` values were rejected as
  dead duplication and the architect settled the point (A1); the two-line
  reversal cost is kept on record. The theme-not-replace decision preserves
  every stock control, which is simultaneously what the non-goals demand and
  what keeps the evidence base intact.
- **SEC — SKIP.** Presentation-only, offline, no new trust boundary. The only
  new bytes are three OFL-1.1 font files with their licences committed beside
  them and their upstream paths, sizes and md5 sums recorded. Recorded rather
  than run.

### Residual risks

Proved by the suite, and therefore not a device risk: both faces resolving in
the test host; the twelve-mark coverage record; the role invariants; the ten
control families off the M3 palette; the meter's greyscale arithmetic and its
two boundary cases; the label column holding still; no clipped diagram label; no
broken word, clipped paragraph or uneven run in the action row; chrome within
its three re-derived caps; every existing crawl, town, world, pack, roster and
craft behaviour.

Settled only by the `Medium_Phone` pass:

- **R1 — whether Spectral at 11 and 13 px is legible on a real phone.** Its
  x-height is 0.450 em against monospace's 0.528, and the scale pays for that
  with +1 px at the small rungs. The suite cannot judge legibility. Capsules A,
  C, F, K; the one tuning pass is the remedy inside the size envelopes.
- **R2 — whether the widget-test and device chrome actually agree.** The
  mechanism is sound (F4) but `✳ ✚ ⛒` in the spell chip labels measure through a
  platform fallback whose advance differs between hosts, so the two combat
  densities may diverge by a few dp. Capsules I and J; a breach of 600 dp is an
  escalation, not tuning.
- **R3 — which weight the display face resolves to.** EB Garamond ships only as
  a variable font; the plan requests `wght` 500 three ways and degrades to 400.
  Capsules A, B, D, E, G.
- **R4 — `crawl_surfaces_test.dart:297-300`'s premise dissolves, and A4 makes
  fixing it mandatory.** It asserts the pack route keeps "the town's own panel
  and ink, hardcoded regardless of the ambient theme the crawl scoped over its
  own subtree". After this unit there is one theme, so it no longer defends
  isolation between two themes; it defends that a pushed route is inside a
  theme at all. Keeping the `AppBar` colours at the call sites means the
  *assertion* never changes — but Task 08's rename deletes the `town.` prefix
  through which the code expressed "the town's, not the crawl's", so the
  comment would be left claiming something the code can no longer say.
  **Upgraded from "recommended at Gate B" to "required in Task 08"**: correct
  the comment there, leave the assertion alone. This remains the one place in
  the unit where a test's stated purpose changes, and it is now closed by
  instruction rather than left to a reviewer.
- **R5 — the selected filter chip's value step is weak.** `armedFill` against
  `raised` is only 1.163 : 1 WCAG (1.763 : 1 plain), and selection is carried by
  the checkmark. That is the same cue as today, and the filter chip's own form
  is U15's gap 8.1. **Not a defect to fix with a threshold** — see A6.
  Capsule C.
- **R6 — CLOSED by architect amendment A3.** `inn_screen.dart:45-46` was
  outside the contract's Boundaries; the architect widened the boundary by
  those two lines on 2026-09-18, so all eleven padded-label rows convert in
  Task 05 and no town screen ships a drifting column. No residual remains.
- **R7 — the twelve fallback marks render in a different face from their
  sentence.** True today too, on both hosts. Cosmetic, not functional; shape
  still carries every category. U16's pictograms retire them. Capsules K and F
  are where it is most visible, and **tofu** rather than a face mismatch is an
  escalation.
- **R8 — closed during planning, recorded for the audit trail.** A concurrent
  `MapBleedDiagnosis` session was diagnosing a map-bleed defect in
  `dungeon_scene.dart`. Confirmed with that session on 2026-09-18: its fix
  **already landed and was accepted** as `e8bcf29` ("fix: clip the dungeon
  scene to its own viewport", U13.1), touching the top import and roughly
  `:184-222` — a private `_ClippedMaxViewport extends MaxViewport` wired into
  `_DungeonScene`'s constructor. It never touched `_textPaint`, `_badgePaint`,
  `cameraCellSize`, `glyphBaseFontScale` or the `* 0.30` derivation. The tree
  is clean, and this planner's read of `:432` and `:441` was taken **after**
  that commit, so Task 07's two line numbers are current and need no
  adaptation. No residual risk remains.
- **R9 — whether the map glyph reads at `cameraCellSize * 0.73` in a serif.**
  `glyphBaseFontScale` and the `* 0.30` badge derivation are frozen, so the
  only variable is the face. Gameplay-critical. Capsule M.

---

## Authorization

The contract is approved and **the architect accepted this plan on 2026-09-18
with amendments A1–A5**; **A6 was ruled during Task 01 execution** and is
folded in above. Architect acceptance of a plan is not implementation
authorization, and the user's plan approval — obtained before Task 01 — governs
the envelope A1–A6 keep materially unchanged: no acceptance criterion moved, no
scope widened beyond A3's two authorised lines, and A6 removed an assertion
rather than adding work.

A1–A3 and A5 are settled and need no further ruling: one `residuumTheme` at six
roots; no mark changes in either package; the `inn_screen.dart:45-46` boundary
widening; and the base revision `5ac1a49`. A4's Task 08 is specified above and
briefed at `plan-tasks/08-rename-leaf.md`. A6 is specified at
§"Why there is no third, fill-versus-surface contrast assertion (A6)" and
carries a standing rule for every later unit.

**Execution state, 2026-09-18: Task 01 accepted.** Tasks 02–08 are unstarted
and their briefs are current against this amended plan.
