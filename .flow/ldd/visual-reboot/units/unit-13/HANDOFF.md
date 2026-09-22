# Residuum RPG — Visual Reboot Unit 13 LDD Handoff

## Protocol state

- Repository: `fiatcode-gh/residuum-rpg`
- Epic: `visual-reboot`
- Observed ref: `b5aeb2f3f81298bbb338b3e22af10d730fb255d2`
- Observed ref meaning: pushed Unit 12 branch head; PR #22 was open and mergeable when this bundle was prepared
- Design status: **settled**
- Implementation strategy: **not needed**
- Authorization: **not carried**

This is a ChatGPT → local OMP LDD handoff. It carries an approved Unit 13 WHAT and architect evidence/proposals. It authorizes no production edits, commits, pushes, pull requests, reviews, merges, releases, or other writes.

## Approved Unit 13

**Unit 13 — Visual Parity Re-baseline**

> Compare the current application, after Units 10–12, against all ten approved visual-reboot mock frames; establish an explicit parity-gap inventory and visual-system contract; determine which gaps require code, which require new authored assets, and which require both; then replace the remaining visual-reboot roadmap with an evidence-driven sequence of implementation units.

This is an architect/design unit. **It makes no production UI, renderer, content, engine, or save changes.**

## Why the roadmap is interrupted

The approved mock remains the visual source of truth.

Units 10–12 produced useful infrastructure and local improvements, but direct comparison against the approved mock shows that the remaining visual gap is still substantial:

- Unit 10 proved authored-art integration and the asset pipeline, but inserting good art into existing utility compositions did not create parity.
- Unit 11 improved dungeon composition, but the dungeon still lacks the mock's structural vocabulary and depth.
- Unit 12 established a coherent crawl interaction grammar, but typography, density, surfaces, controls, timeline, log, and overall production language remain far from the approved mock.

The remaining roadmap must therefore be driven by explicit mock-vs-current parity evidence rather than subsystem-local polish.

## Immediate LDD reconciliation

Local OMP must freshness-check repository state first.

At bundle creation:

- PR #22 (`Give the crawl one visual grammar`) was open and mergeable.
- `residuum-visual-reboot-12` was at `b5aeb2f3f81298bbb338b3e22af10d730fb255d2`.
- `main` was still Unit 11's merge.

Then reconcile these stale records:

1. Unit 12's canonical contract/status must no longer say `drafted, awaiting explicit user approval`; it has been approved, implemented, accepted, and device-verified.
2. Unit 12.5's checkpoint contains stale mid-session forward-pointer text despite the unit being closed. Supersede/remove that stale tail.
3. **Supersede Unit 12.5 AC17's conclusion** that dungeon viewport output is not a dominant remaining parity gap. Direct side-by-side evidence shows major remaining gaps in both dungeon output and wider application chrome.

Do not rewrite append-only ledger history. Record a superseding decision.

## Unit 13 sources

Primary target:

- `reference/approved-visual-reboot-mock.png`
- local project copy if present: `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`

Current-state evidence should come from the completed Unit 12/12.5 evidence under `.flow/evidence/visual-reboot`, including exploration, combat, armed targeting, expanded log, overlays, pack, roster, spells, town, and worst legal density.

## Required output

Unit 13 should produce:

1. a ten-frame parity audit;
2. a parity matrix using one consistent gap vocabulary;
3. a settled visual-system contract;
4. a settled asset-authority / asset-family decision;
5. a list of gameplay/accessibility locks;
6. a recut remaining visual-reboot roadmap;
7. an explicit route for the map-bleed defect and the separate post-death save-read defect candidate.

## Required gap classification

Every significant discrepancy must be one of:

- `CODE`
- `ASSET`
- `CODE + ASSET`
- `INTENTIONAL DEVIATION`
- `ALREADY ACCEPTABLE`

## Decisions Unit 13 must settle

### Typography
Reopen the monospace-only assumption. Determine production font roles and whether authored font assets are required.

### Color
Preserve `no important state depends on hue alone`, but do not interpret that as avoiding useful color.

### UI material language
Define the visual vocabulary for frames, inset panels, hairlines, ornament, list rows, action controls, selection/armed/disabled states, overlays, spacing, and type roles.

### Authored assets
Lock that new authored assets are permitted where the mock requires vocabulary the repository does not possess. Audit likely families rather than pre-authorizing all of them blindly.

### Composition
Gameplay semantics remain locked, but current visual composition is not sacred. Layout proportions, placement, row density, illustration integration, frame treatment, and control geometry may be rebuilt where the mock requires it.

## Behavioral/accessibility locks

Preserve:

- engine authority and determinism;
- save compatibility unless a separate approved defect unit changes it;
- map = space/targets;
- timeline = time;
- log = causality;
- action shelf = verbs;
- melee map-first;
- targeted spell `arm → map target → tap`;
- circle selection / square targeting distinction;
- activation repetition and hidden-actor secrecy;
- no important state by hue alone;
- authoritative action vocabulary/counts.

## Defect routing

### Map bleed
Treat the Unit 12.5 map-over-timeline bleed as a real defect requiring root-cause diagnosis. Do not assume `ClipRect` is the fix. Unit 13 decides whether it is a tiny correction before parity implementation or absorbed into the first dungeon/crawl parity unit.

### Post-death save-read candidate
Keep separate from visual work. Unit 13 may route it, but must not diagnose or repair it.

## Forward pointer

After local intake and reconciliation:

1. run Unit 13 as an architect/design audit;
2. complete the ten-frame parity matrix;
3. settle visual-system and asset decisions;
4. propose the recut roadmap;
5. stop for user approval of the roadmap / next implementation-unit WHAT.

No production implementation is authorized by this handoff.
