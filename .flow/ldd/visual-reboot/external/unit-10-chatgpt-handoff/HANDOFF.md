# Residuum Visual Reboot — Unit 10 External LDD Handoff

## Goal

Open the post-Unit-9 authored-art integration as **Unit 10**, assuming Unit 9 has
already been merged and its accepted tree is the base.

This bundle is an external LDD proposal. It does **not** carry local production
write, commit, push, review-publication, merge, release, or integration
authorization.

## Observed repository state

- Repository: `fiatcode-gh/residuum-rpg`
- Exact source revision observed by ChatGPT:
  `92fd4aa41558d3c76fc5f6fae69d4e9e96f65e96` (`residuum-visual-reboot-9`, commit message
  `feat: rebuild crawl status`)
- At observation time, public `main` was still `2b0e0a49acbf76c7394335cc07a624ca6ead5937`
  (merged Unit 8).
- The user explicitly asked this handoff to **assume Unit 9 is merged**.
- Therefore the receiving session must revalidate the actual merged `main` and
  confirm that the Unit 9 tree represented by the observed ref is present before
  adopting this proposal.

The observed Unit 9 tree contains the accepted two-row crawl status and keeps
icon controls deferred. Its LDD ledger explicitly leaves the post-Unit-8 art
pass without an owning unit.

## What ChatGPT could observe

Verified from the Unit 9 branch:

- `packages/app/pubspec.yaml` has no active `assets:` declaration.
- `packages/app/lib/game/dungeon_material.dart` already separates material facts
  from rendering and derives deterministic decorative marks without gameplay RNG.
- `packages/app/lib/game/dungeon_scene_material.dart` already renders material,
  visibility-clipped local light, and regional procedural patterns.
- `packages/app/lib/game/dungeon_palette.dart` maps Crypt, Sea-Cave, Ruined Keep,
  and road regions to presentation palettes/material identities.
- `TownScreen`, `ForgeScreen`, and `TavernScreen` are currently text/UI-driven
  and have clean insertion seams for non-authoritative environment art.
- Crawl controls and the combat shelf remain text-labelled and therefore provide
  a safe seam for icon-plus-text treatment without making icons authoritative.

## What ChatGPT could not observe

- The actual authored asset bytes, exact filenames, dimensions, alpha behavior,
  compression, or final repository destination.
- Any licensing/provenance metadata for those assets.
- A merged Unit 9 commit on `main` (the handoff intentionally assumes this future
  state at the user's request).
- Final device behavior/performance of authored images on `Medium_Phone`.

`asset-inventory.md` therefore records **logical roles discussed in this
session**, not verified file paths.

## Approval state

### Settled inherited project truth

The following are inherited from the existing visual-reboot epic and should not
be reopened without contrary evidence:

- phone-first; tablet/landscape later;
- Flame is presentation/hit-testing, never authoritative game state;
- runtime/app state owns geometry, visibility, interaction, and rules;
- map remains the primary crawl surface;
- graphical-glyph dungeon language;
- deterministic presentation; no gameplay-RNG consumption for decoration;
- unknown geometry must never be disclosed;
- no important state may be communicated by hue alone;
- non-dungeon UI remains visually subordinate to the crawl/map;
- no balance, content-generation, save-shape, or rules piggyback.

### Unit 10 approval is NOT yet recorded

The proposed Unit 10 contract in `proposed-units/unit-10.md` has **not** received
the explicit WHAT/boundary/acceptance approval required by current Flow doctrine.
The user's request to create this handoff is not treated as that missing contract
approval.

Accordingly:

- `design_status`: `partial`
- `implementation_strategy`: `partial`
- no execution-grade `IMPLEMENTATION-PLAN.md` is included.

## Proposed Unit 10 direction

Unit 10 should own authored visual assets as an app-side presentation layer:

1. establish the Flutter asset pipeline and one app-side asset catalogue;
2. add non-authoritative environment illustrations where matching approved art
   exists;
3. feed authored dungeon material sources into the existing deterministic
   material renderer without changing topology/FOV/knowledge authority;
4. add deterministic decorative cracks/rubble without gameplay meaning;
5. add icons only as reinforcement beside existing words/counts, never as the
   sole carrier of action/state.

The governing invariant is:

> Authored art may change appearance, never topology, knowledge, interaction,
> or game-state meaning.

## Candidate sequencing (strategy only)

This sequencing is useful but is not execution-grade planning:

1. asset plumbing + environment art;
2. authored dungeon materials;
3. decorative overlays;
4. icon language on already-existing actions;
5. integrated widget/repository/device acceptance.

Keep Unit 8/9 procedural identity and accessibility mechanisms until device
evidence proves an authored replacement is safe. Do not delete regional
procedural patterns merely because textures exist.

## Important risks

- non-seamless texture sources can visibly tile if treated as literal repeating
  tiles;
- image sampling must remain deterministic and must not consume gameplay RNG;
- material art must stay inside authoritative known/visible geometry;
- remembered terrain must remain visually distinct and must not acquire live
  lighting;
- icons can accidentally become hue- or shape-only state if labels are removed;
- static environment art can crowd phone layouts or visually overpower game UI;
- asset decode/loading inside per-frame/per-cell render paths could introduce
  hitching;
- broad Back-icon replacement touches many routes and should not be smuggled
  into the first icon slice;
- a Melee icon must not create a fake button because melee is currently direct
  map interaction.

## Local revalidation checklist

1. Run the receiving stack's shipped read-only planning-handoff validator on this
   bundle.
2. Read local project instructions plus current
   `.flow/ldd/visual-reboot/LEDGER.md` and `RESUME.md`.
3. Confirm local `main` contains the accepted Unit 9 tree; compare against
   `92fd4aa41558d3c76fc5f6fae69d4e9e96f65e96` rather than assuming the merge shape.
4. Revalidate the source seams named above against the merged tree.
5. Inventory the actual asset files locally: exact names, dimensions, format,
   alpha/transparency, and intended role. Reconcile any mismatch with
   `asset-inventory.md`.
6. Reconcile `proposed-ledger-delta.md` and `proposed-units/unit-10.md` into
   canonical LDD authority only after review.
7. Present the completed Unit 10 WHAT/boundary/acceptance summary to the user and
   obtain explicit contract approval.
8. Only after that approval, use local `flow-planning` to make consequential HOW
   execution-grade. Preserve the strategy here, but refine the exact asset
   interfaces, preload/lifetime ownership, renderer sampling/cropping, tests,
   device proof, and escalation conditions.
9. Obtain the local plan/implementation approval required by the current Flow
   before dispatching any production-writing worker.

## Recommended next workflow action

After validation/freshness checks, reconcile this proposal into the visual-reboot
ledger as a **draft Unit 10**, inspect the real asset bundle, close any factual
inventory gaps, then obtain explicit user approval of the Unit 10 contract.
Do not begin production implementation from this handoff alone.
