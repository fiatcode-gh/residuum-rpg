# Proposed Unit 12 Contract — Crawl Interface Visual Grammar

> External proposal for reconciliation into the canonical `visual-reboot` LDD ledger/unit set. This file is not itself canonical local project state.

## Status

- WHAT: **approved in the ChatGPT design session**
- HOW: **requires local execution-grade planning and separate approval**
- Authorization: **not carried**

## Objective

Recompose the phone crawl interface surrounding the existing dungeon viewport into the approved Residuum visual language, replacing generic/default Material presentation with a cohesive typography, surface, hierarchy, framing, status, timeline, log, control, and action-state grammar.

## Dependencies

- Units 1–11 are prior visual-reboot dependencies.
- Unit 11's dungeon renderer is treated as an accepted dependency, not an implementation surface for Unit 12.
- Unit 10's authored-art pipeline and decode ownership remain intact.

## Required behavior preservation

Unit 12 must preserve:

- engine authority and determinism;
- existing action vocabulary and counts;
- exploration/combat mode semantics;
- activation order, repeated activations, and timeline information hiding;
- log event causality, ordering, follow, unread, and compact/expanded semantics;
- melee map-first interaction;
- targeted spell `arm → map target → tap` flow;
- selection-circle and targeting-square semantics;
- save compatibility and restoration behavior;
- the Unit 11 dungeon viewport output and interaction contract except for surrounding frame/layout integration that does not change renderer semantics.

## Scope

### 1. Crawl visual foundation and shell

Establish a small crawl-owned presentation/style authority and use it to compose the crawl background, status/header presentation, viewport framing, spacing, surface hierarchy, typography roles, borders/dividers, and crawl-local control-state values.

The crawl may use a locally scoped Material theme or equivalent boundary where helpful. Do not modify the application's global theme solely to make this unit correct.

### 2. Information hierarchy

Recompose the activation timeline, encounter/combat readout, compact log, expanded log/history, unread/follow treatment, and secondary informational surfaces so that:

- map answers **where**;
- timeline answers **when**;
- log answers **what/why happened**;
- status/readout answers **current state**.

Presentation can change substantially; semantics cannot.

### 3. Action grammar and crawl overlays

Recompose exploration controls, battle action shelf, action icons/labels, available/disabled/armed/active states, target-selection feedback around the shelf, and the crawl-local Spells bottom sheet / closely related crawl overlays.

Critical action states must not rely on color alone. Available, armed, and disabled states must remain distinguishable in greyscale through shape/border/fill/type/icon/state treatment.

## Boundaries

### Expected ownership candidates

Fresh local recon must confirm exact files, but likely ownership includes:

- `packages/app/lib/game/game_screen.dart`
- `packages/app/lib/game/crawl_status.dart`
- `packages/app/lib/game/battle_view.dart`
- `packages/app/lib/game/log_drawer.dart`
- `packages/app/lib/game/action_icon.dart`
- a small new crawl-local style/presentation seam
- focused tests for the touched behavior/presentation contracts

### Protected by default

Do not modify these unless local recon proves a narrow unavoidable integration seam and the plan explicitly records it:

- `packages/app/lib/game/dungeon_scene.dart`
- `packages/app/lib/game/dungeon_scene_material.dart`
- `packages/app/lib/game/dungeon_render_style.dart`
- `packages/app/lib/game/glyph_marks.dart`
- `packages/core/**`
- `packages/content/**`
- save schema
- content/balance definitions
- town UI
- standalone Character / Spells / Pack UI
- world-map UI

## Traps / rejected directions

- Do not turn Unit 12 into an application-wide design-system refactor.
- Do not independently hard-code a new style vocabulary in every crawl widget.
- Do not reopen dungeon art/rendering to compensate for incomplete crawl chrome.
- Do not add a new melee attack button merely for visual consistency.
- Do not shortcut targeted spells into direct casting.
- Do not use screenshot golden tests as the primary behavioral contract.
- Do not silently expand scope into standalone management screens.

## Acceptance criteria

1. Crawl chrome has a clear local visual authority rather than unrelated hand-rolled styles.
2. The phone crawl shell, status area, map frame, timeline, logs, controls, and crawl overlays read as one visual system.
3. Global application screens are not unintentionally restyled.
4. Map/dungeon renderer semantics and Unit 11 output contract remain unchanged.
5. Timeline order, repetition, identity, current/selected meaning, and information hiding are preserved.
6. Compact/expanded log behavior, ordering, follow, and unread mechanics are preserved.
7. Exploration and combat actions dispatch the same authoritative actions as before.
8. Melee stays map-first; targeted spells stay `arm → map target → tap`.
9. Available / armed / disabled action states are distinct without relying solely on color.
10. Crawl-local Spells sheet and immediate crawl overlays no longer create an obvious stock-Material visual break.
11. Focused tests and normal repository gates pass.
12. Bounded `Medium_Phone` evidence covers exploration, combat, armed targeting, expanded log, crawl Spells sheet, and a greyscale state/hierarchy check.
13. After acceptance, the architect explicitly records whether the dungeon viewport is now the dominant remaining parity gap and whether Dungeon Structural Asset Expansion becomes the immediate next unit.

## Verification expectations

- Prefer pure/widget behavioral tests for semantics and state projection.
- Use device evidence as the subjective visual gate.
- Compare against approved mocks for hierarchy, density, rhythm, typography, framing, contrast, surface/material feel, and action-state clarity rather than literal pixel parity.
- Preserve the existing save/restoration verification procedure used by the visual-reboot epic where applicable.
