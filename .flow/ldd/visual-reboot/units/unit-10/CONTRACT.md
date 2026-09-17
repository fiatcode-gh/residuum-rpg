# Unit 10 — authored art integration

Status: **approved by the user on 2026-09-16**, with decisions D1, D2 and D3
resolved below. Approval authorizes execution-grade planning only; no
production-writing worker may be dispatched until the resulting plan is
separately approved. Reconciled by the architect from the external bundle
(`../../external/unit-10-chatgpt-handoff/`, unvalidated evidence) plus source
recon at `main` = `4bf865c` recorded in `recon.md`.

Dependency: Unit 9, merged at `4bf865c`. Unit 10 is the first unit after the
locked order 1 → … → 9 and owns the art pass the epic deferred past Unit 8.

## Outcome

Residuum gains its first authored-image layer, entirely inside `packages/app`,
without giving any image authority over the game.

After this unit:

- the app declares assets once and refers to them through one typed catalogue,
  never raw path strings at use sites;
- the Forge, the Tavern and Stonebridge carry an authored illustration as
  atmosphere while every existing word, price, refusal and control stays
  primary and reachable;
- Crypt, Sea-Cave and Ruined Keep floors and walls are painted from authored
  material sources inside the existing `MaterialPlan` projection, with
  topology, knowledge, visibility, local light and hit testing unchanged;
- authored cracks, fractures and rubble decorate known terrain deterministically
  and mean nothing;
- the battle shelf's actions carry an icon beside their existing word and count.

The governing rule, inherited unchanged:

**Authored art may change appearance, never topology, knowledge, interaction, or
game-state meaning.**

## Inherited locks (not reopened by this unit)

1. Flame is presentation and hit-testing; authoritative state stays outside it.
2. Map = space, timeline = time, log = causality, shelf = verbs.
3. The crawl stays map-first. New chrome must not steal play-surface height.
4. Presentation is deterministic and draws no gameplay RNG.
5. Unknown geometry stays unknown — unknown cells are absent from
   `MaterialPlan.cells` and must remain unpainted.
6. Remembered terrain stays flat, unlit and distinct from visible terrain.
7. No important state or action reads by hue alone; every screen reads in
   greyscale.
8. Words, counts and refusal sentences survive wherever an icon appears.
9. No core/content/save/RNG/rules/event/bloc-ownership change.
10. Phone-first; tablet and landscape stay deferred.

## Scope

### A. Asset pipeline

- `packages/app/pubspec.yaml` gains its first active `assets:` declaration.
- **The masters are tracked through Git LFS.** `art/visual-reboot/**/*.png`
  is registered in a new root `.gitattributes`; `git-lfs 3.7.1` is installed
  and `origin` is GitHub, so 48.1 MB sits well inside quota. The repository has
  no LFS configuration today, so this unit introduces it.
- Shipped assets are **derived** from those masters and committed as ordinary
  git objects, not LFS pointers, so a build or CI checkout without LFS still
  produces a correct app. Every master is 1254 x 1254 and 6.0 MB decoded, which
  is unshippable as-is and would risk the decode hitch criterion 16 forbids.
  Derivation is reproducible from a command recorded in the repository; exact
  target sizes and format are planning work.
- One app-side catalogue names every shipped asset; widgets and the renderer
  take catalogue entries, not strings.
- Decode and lifetime are owned by presentation code and happen off the per-cell
  and per-frame path. `packages/core` and `packages/content` gain no Flutter
  dependency.

### B. Environment illustrations

Three authored environments exist: `ENV-001_stonebridge`, `ENV-002_forge`,
`ENV-003_tavern`. All are square (1:1), so each placement crops or fits
deliberately; an uncropped square at phone width is ~411 dp, about 45% of the
923.4 dp phone height.

- `TownScreen` shows the Stonebridge illustration **only when
  `TownViewState.town == stonebridge`**; Northgate gets no town illustration and
  no substitute. The seam is between `Notice` and the `Spacer` that gravitates
  the seven doors.
- **Room illustrations are room-typed, not place-typed** (decision D3): the
  Forge and Tavern art depicts a forge and a tavern and therefore appears in
  both towns, ungated.
- `ForgeScreen` and `TavernScreen` insert into their `TownRoom` `children[]`
  after `Notice` and before the first `Heading`, inside a ~371 dp content width.
- Illustrations are decorative: wrapped in `ExcludeSemantics`, following the
  `world_route_diagram.dart` precedent, and carry no text meaning.
- Height is capped so the seven-door column stays reachable on a 600 dp-tall
  surface and the forge and tavern section order is unchanged.

### C. Authored dungeon materials

Region families with authored floor and wall sources: Crypt (`DNG-001/002`),
Sea-Cave (`DNG-SC-001/002`), Ruined Keep (`DNG-RK-001/002`). No road asset
exists, so `lowlandRoad` stays fully procedural.

- The authored layer is driven by the existing `MaterialCell` facts — `kind`,
  `knowledge` — and paints inside the existing cell rect. Tile kind never comes
  from image analysis, geometry never from texture edges.
- Sampling is keyed only by presentation-stable inputs, reusing the existing
  `_hash`/`themeSalt` grammar. No new randomness, no frame clock.
- The masters are **not guaranteed seamless** (bundle manifest), so one bitmap
  per cell repeated wholesale is prohibited; the plan chooses the sampling and
  cropping strategy.
- Remembered cells stay flat and unlit; authored art carries no baked lighting
  that would double against the mask-clipped radial gradient.

### D. Decorative overlays

Crack, fracture and rubble overlays exist for all three regions
(`*_crack_overlay_a/b`, `*_fracture_overlay_a/b`, `*_rubble_small/medium`).

They are deterministic, clipped to their own cell rect and to authoritative
known geometry, sparse, non-colliding, non-interactive, never loot, and never
confusable with a resource node, item, stairs, actor or target mark.

### E. Icon language on existing actions

Icons accompany, never replace, an existing label. Two surfaces are in scope.

**The battle shelf** (`game_screen.dart:604-656`) is a `Wrap` and reflows, so it
takes icons as-is:

- `Drink (n)` → `UI-P0-001_potion`; `Wait` → `UI-P0-003_wait`; `+N` overflow →
  `UI-P0-009_more`; readied spells matching an asset exactly →
  `UI-P0-007_firebolt`, `UI-P0-008_mend`.
- Every label, count, mana cost, school marking and the `— armed` word stays.
  Armed still reads by border plus word, never by hue.
- A spell with no exact matching asset keeps text alone; no generic stand-in.

**The crawl control row** (`_Control`, `game_screen.dart:498-520`, inside the
`Row` at `:237-350`) is re-laid-out by this unit (decision D2). Today five
`Expanded` cells of ~82 dp with `TextOverflow.ellipsis` already truncate
`Drink (…)` on hardware — a defect proved on device at both `2b0e0a4` and
`4bf865c`. Adding an icon to that geometry is strictly worse, so the geometry
changes:

- The row must display, at its worst real density, every control's action word
  and live count **without ellipsis** at 411.4 dp. The mechanism — reflow,
  overflow affordance, or another layout — is planning work; equal-width
  `Expanded` cells with silent ellipsis is not acceptable.
- Icons land on the controls that have an exact asset: `Drink (n)` →
  `UI-P0-001_potion`, `Pack (n)` → `UI-P0-002_pack`, `Wait` → `UI-P0-003_wait`,
  `Ascend <` → `UI-P0-004_ascend`, `Descend >` → `UI-P0-005_descend`. Every
  other control stays text-only.
- The control set itself is frozen: no control is added, removed, renamed or
  reordered, and no control changes what it dispatches.
- Disabled still reads as it does today (`onPressed: null`), and any control
  that gains an icon gains a matching `Semantics` label, since `_Control` has
  none today.

Shipped icons are multitone masters, so each must read in greyscale against its
button background.

## Non-goals

- No custom Back icon: back is Flutter's automatic `AppBar` leading widget
  across fourteen files, and the crawl refuses pop outright. `UI-P0-010_back`
  stays unused.
- No Melee button: melee is a map tap (`TileTapped`), so `UI-P0-006_melee` has
  no legal home in this unit.
- No change to which controls exist, what they say, or what they dispatch —
  only the row's geometry and its icons change.
- No road material art; no portraits; no tablet or landscape work.
- No removal or weakening of the accepted Sea-Cave strata, Ruined Keep ashlar
  fracture, structural wall edges or runtime light. Reducing an accepted
  regional cue is a material design change and is escalated, never cleaned up.
- No change under `packages/core` or `packages/content`.

## Decisions resolved at approval, 2026-09-16

**D1 — masters live in Git LFS.** `art/visual-reboot/**/*.png` is tracked
through LFS from a new root `.gitattributes`. Derived shipped assets stay
ordinary git objects so a non-LFS checkout still builds. This introduces the
repository's first LFS configuration.

**D2 — Unit 10 widens to the crawl control row.** The row is re-laid-out so
that icon-plus-label fits without ellipsis at phone width, which also retires
the inherited `Drink (…)` truncation. The control set stays frozen; only
geometry and icons change.

**D3 — room illustrations appear in both towns.** Forge and Tavern art is
room-typed. Only the Stonebridge environment is gated on town identity.

## Acceptance criteria

1. `packages/app` declares its assets once and resolves every one through a
   single typed catalogue; no widget or renderer holds a raw asset path. No file
   under `packages/core` or `packages/content` references Flutter images or
   asset paths.
2. Shipped assets are derived, size-appropriate artefacts, reproducible from the
   masters by a command recorded in the repository; the 1254 x 1254 masters are
   not shipped. `art/visual-reboot/**/*.png` is tracked by Git LFS, the shipped
   assets are not, and a checkout without LFS still builds a correct app.
3. The Stonebridge illustration appears only when the town is `stonebridge`, and
   nothing substitutes for it in Northgate. The Forge and Tavern illustrations
   appear in both towns.
4. No illustration replaces, obscures or makes unreachable any title, status
   line, price, refusal sentence, control or door. The seventh town door stays
   reachable on a 600 dp-tall surface; forge and tavern section order and the
   notice-above-heading rule are unchanged.
5. Illustrations are excluded from semantics and carry no textual meaning.
6. Crypt, Sea-Cave and Ruined Keep authored material appearance is driven by the
   existing authoritative projection: unknown cells stay unpainted, remembered
   cells stay flat and unlit, visible light stays clipped to the visible mask.
7. For identical game and presentation state, material sampling and overlay
   selection are identical across rebuilds, revisits and pans, and consume no
   gameplay RNG.
8. Authored art changes no collision, topology, hit testing, camera geometry,
   item or resource-node presentation, target mark, actor identity or stairs.
9. Lowland roads are visually unchanged.
10. Every icon-bearing shelf action keeps its word, count, cost and marking;
    armed still reads by border and the word `— armed`; every icon reads in
    greyscale; a spell without an exact asset stays text-only.
11. **The crawl control row shows every control's action word and live count
    without ellipsis at 411.4 dp, at the worst real control density**, proved on
    device as well as in the widget harness. Icons appear only on controls with
    an exact asset; each icon-bearing control carries a `Semantics` label;
    disabled state reads as it does today.
12. No control is added, removed, renamed or reordered, and none changes what it
    dispatches. No new control or action exists because an asset exists. Melee
    remains a map tap; back remains the platform affordance.
13. Sea-Cave strata, Ruined Keep ashlar fracture, wall edges and runtime light
    are still present and still read at phone density.
14. Focused tests cover: catalogue resolution; the Stonebridge town gate in both
    directions; illustration presence without displacing controls; deterministic
    authored sampling and overlay selection; unknown-unpainted and
    remembered-unlit invariants under authored material; icon-plus-label
    preservation on shelf and controls; and a phone-width control row proved
    un-ellipsised at maximum density, since the default harness surface is wider
    than a phone and hides exactly this defect.
15. From `packages/app`: `dart format --set-exit-if-changed`, `flutter analyze`
    and the full `flutter test` suite pass on the final tree, with no regression
    against the 834 tests at Unit 9's close. `packages/core` and
    `packages/content` are unchanged.
16. `Medium_Phone` acceptance covers, at minimum: Stonebridge town with its
    illustration; Northgate town without one; Forge and Tavern in both towns;
    one Crypt delve; one Sea-Cave delve; one Ruined Keep delve; a lowland-road
    fight proving the procedural fallback; the crawl control row at its worst
    real density including the five-control bottom-floor scene; and a battle
    shelf showing every icon-bearing action reachable, including the `+N`
    overflow sheet. Greyscale twins cover every frame where hue could otherwise
    carry meaning.
17. Device evidence shows no image-induced clipping or overflow, no lost label
    or count, no hidden-geometry leak, and no scene-entry or crawl-render hitch
    attributable to asset decoding.
18. Both device save slots are backed up before any install and proved
    byte-identical afterward by SHA-256, per the standing epic device rule.

## Verification disposition

- Contract approval precedes planning. This unit needs execution-grade planning:
  derivation pipeline, decode ownership and lifetime, sampling strategy against
  non-seamless sources, catalogue shape, test seams and device sequencing are
  all consequential HOW.
- One integrated `flow-acceptance-reviewer` pass after the coherent
  implementation, as a dependency barrier before device evidence.
- Security review skipped unless a new external, network or file trust boundary
  appears.
- Device evidence runs as bounded `flow-evidence-verifier` capsules with the
  standing backup and restore obligation.
