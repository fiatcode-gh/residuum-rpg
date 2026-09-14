# Residuum Visual Reboot — Unit 2 handoff

## Goal and scope

Continue the existing Visual Reboot epic with Unit 2: establish the graphical dungeon material language on top of the accepted Flame renderer.

This handoff settles the **dungeon-material design** and proposes a concrete implementation strategy. It does not authorize production writes.

## Repository facts observed

Repository: `fiatcode-gh/residuum-rpg`  
Observed ref: `216cd469788486db6ba907490462cce0c87e8079` (`main`, Unit 1 integrated)

Observed source facts:
- Unit 1 is accepted in the visual-reboot ledger/resume.
- `packages/app/lib/game/dungeon_scene.dart` owns a stateful Flame game instance and receives immutable `DungeonSceneSnapshot` data.
- The current snapshot is projected through `glyphPlan(...)`.
- The current Flame scene still renders projected cells through `_GlyphComponent` / `TextComponent`, including terrain glyphs.
- `glyph_plan.dart` is the characterized semantic projection for terrain/nodes/litter/monsters/hero and knowledge exposure.
- `dungeon_palette.dart` contains existing Crypt/Sea-Cave/Ruined Keep palette selection.
- Core/app authority and camera/input rules from Unit 1 remain binding.

The source session did not inspect a local dirty working tree, local-only evidence, or changes newer than the observed ref. Local OMP must do so.

## User-approved / locked decisions

The user approved the Unit 2 dungeon-material direction on 2026-09-13.

Locked:
- etched dark-fantasy diagram identity;
- cold charcoal stone, restrained warm amber local illumination;
- near-black unknown void;
- remembered material dark/flat/reduced-detail/unlit;
- low-to-medium deterministic procedural texture;
- continuous material rather than independently illustrated logical tiles;
- structural walls and quieter floors;
- semantic graphical glyph actors, not conventional sprites;
- strict no-geometry-leak fog/light behavior;
- value/detail/shape accessibility, including greyscale acceptance;
- no bulk generated raster art for Unit 2.

See `ART-BIBLE.md`.

Deferred rather than decided:
- portrait framing;
- bulk/static generated-art composition;
- full non-dungeon icon family.

Those remain before Unit 7 and do not block Unit 2.

## Proposed implementation strategy

Separate material terrain rendering from semantic glyph/entity projection.

The accepted Flame boundary remains:
- app/core own rules and visibility;
- Flame renders;
- Flame emits existing input intents only.

For Unit 2:
- give the renderer explicit immutable known-terrain facts (tile kind + visible/remembered state);
- keep node/litter/monster/hero/target semantics characterized by existing projection rules where appropriate;
- implement pure deterministic coordinate/theme decoration;
- render continuous floor/wall material;
- render remembered and visible treatment distinctly;
- apply a smooth warm presentation light clipped to authoritative visible positions;
- upgrade actor/stair glyphs into crisp graphical marks;
- never parse terrain glyph strings back into rules;
- never run an independent FOV/shadowcasting system;
- leave Unit 3 interactions unchanged.

See `IMPLEMENTATION-PLAN.md` and `proposed-units/unit-2-CONTRACT.md`.

## Verification strategy

Primary proof:
- deterministic renderer-plan/unit tests;
- explicit no-geometry-leak cases;
- projection/synchronization characterization;
- existing scene interaction tests;
- full `packages/app` test suite;
- analyzer;
- target phone / Pixel_10 AVD acceptance;
- normal + greyscale screenshots.

Visual acceptance is directional, not pixel-perfect. Evaluate darkness, material continuity, restraint of warm light, glyph clarity, remembered-vs-visible reading, and absence of unknown leaks.

Suggested review lenses: COR, TTC, CRF; SEC skip unless scope changes.

## Important risks

- terrain semantics accidentally inferred from `#`/`.` text;
- wall topology leaking unknown neighbor type;
- radial light bleeding outside authoritative visibility;
- per-cell ornament producing a polished tilemap instead of continuous material;
- procedural decisions changing across sync/revisit;
- presentation randomness consuming game RNG;
- orange/sepia becoming the base palette;
- accidental Unit 3 interaction creep.

## Unresolved questions

No unresolved question blocks Unit 2 design.

The broader epic still has:
- M3Q sequencing;
- future portrait/static-art/icon-family decisions before Unit 7.

## Local revalidation checklist

- Validate this bundle with the current Flow planning-handoff validator.
- Confirm checkout repository and epic.
- Inspect local dirty state and current `HEAD`.
- Read current `AGENTS.md`, visual-reboot `LEDGER.md`/`RESUME.md`, Unit 1 contract.
- Re-check current `dungeon_scene.dart`, `glyph_plan.dart`, `dungeon_palette.dart`, and scene tests.
- Compare intervening commits against the observed ref.
- Reconcile the proposed art bible/contract/ledger delta into canonical LDD files.
- Preserve `authorization: not-carried`; obtain normal local implementation approval.
- Follow M3 device-save safety before any emulator/device installation.

## Recommended next local workflow action

Treat the design and implementation strategy as settled unless current source evidence conflicts.

After validation/reconciliation, skip redundant broad design/planning and proceed to the normal local execution-approval / `flow-execution` path for Unit 2.

Do not infer production authorization from this bundle.
