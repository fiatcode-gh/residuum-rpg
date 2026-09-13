# Unit 2 — Proposed Implementation Plan

Status: planning proposal; implementation authorization is not carried.

## Strategy

The design and implementation strategy are sufficiently settled that local OMP should not repeat broad visual brainstorming. It should revalidate the current checkout and seams, reconcile the LDD proposal, obtain local execution authorization, then execute with tests/evidence.

Internal class names may change during source recon. The architectural invariants in the proposed contract must not.

## Phase A — Intake and recon

- Validate `FLOW-HANDOFF.json` with the current `flow-external-session` validator.
- Confirm repository/epic and compare local `HEAD` against observed ref `216cd469788486db6ba907490462cce0c87e8079`.
- Read current `AGENTS.md`, visual-reboot `LEDGER.md`/`RESUME.md`, Unit 1 contract, `dungeon_scene.dart`, `glyph_plan.dart`, `dungeon_palette.dart`, and relevant scene/widget tests.
- Inspect dirty state before any write.
- Re-run/spot-check the accepted Unit 1 baseline if intervening source changed the renderer boundary.
- Reconcile `ART-BIBLE.md`, the proposed Unit 2 contract, and the ledger delta into canonical LDD files.
- Obtain normal local implementation approval before production changes.

## Phase B — Red: characterize the material boundary

Add focused tests that fail for the current terminal-style terrain renderer and pin:
- deterministic coordinate-derived decoration;
- explicit visible vs remembered terrain presentation facts;
- unknown cells absent from material/light output;
- unknown-neighbor topology cannot disclose tile type;
- pan-only synchronization does not regenerate material decisions;
- existing entity exposure/order remains unchanged.

Avoid brittle golden screenshots as the primary proof.

## Phase C — Introduce explicit known-terrain presentation data

Refactor the immutable scene snapshot/presentation plan so the renderer receives tile kind + knowledge state directly for known terrain.

Keep gameplay authority out of Flame.

Recommended shape:
- a pure renderer-neutral terrain presentation record/list;
- current semantic entity/glyph projection retained for node/litter/monster/hero/marks where appropriate;
- no parsing of `#`, `.`, `<`, `>` inside renderer components.

Preserve the state-owned Flame game instance and current camera/input callback boundary.

## Phase D — Continuous deterministic material

Implement quiet floor and structural wall drawing using pure deterministic presentation hashing.

Requirements:
- no gameplay RNG;
- no frame/time dependence;
- sparse floor decoration;
- stronger but restrained wall structure;
- no visible cell-border grid;
- no drawing into unknown space.

Prefer a small number of material components/layers over one heavyweight object per decorative speck.

## Phase E — Knowledge treatment and lighting

Render:
- unknown as untouched near-black void;
- remembered known terrain as dark/flat/cool, reduced-detail and unlit;
- visible terrain with full material response.

Add a presentation-only smooth local light clipped to authoritative visible positions.

Do not add independent LOS/shadowcasting. Prove clipping/no-leak with tests.

## Phase F — Graphical glyph marks

Move hero/monster/stairs/semantic marks away from raw terminal-cell appearance while preserving their glyph identity.

Use crisp custom drawing/text treatment with restrained outline/shadow/halo. Keep target mark shape/value readability.

Do not add sprites or raster assets.

## Phase G — Verification and visual tuning

From `packages/app`:
- format touched Dart;
- run focused tests continuously;
- run full `flutter test`;
- run `flutter analyze`.

Then use the project M3 device-safety procedure and Pixel_10/target phone AVD acceptance.

Capture normal and greyscale evidence under `.flow/evidence/visual-reboot/`.

Tune palette/reference anchors only from visual evidence; do not reopen the art direction merely because exact hex values need device adjustment.

## Phase H — Review and close

Run COR/TTC/CRF; SEC remains skipped unless scope unexpectedly crosses a security boundary.

Fix findings with fresh evidence.

Only after final tests/analyzer/AVD acceptance:
- mark Unit 2 accepted in the visual-reboot ledger;
- update `RESUME.md` to point to Unit 3;
- record verification receipts and material-language decisions;
- integrate with the project's normal branch/CI/merge flow.
