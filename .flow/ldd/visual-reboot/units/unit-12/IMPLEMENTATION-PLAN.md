# Unit 12 — Proposed Implementation Strategy

## Plan quality disposition

**Strategy-only / partial. Not execution-grade.**

The Unit 12 WHAT is settled, but this external plan has **not** passed the local Flow execution-grade planning contract and has **not** received separate user plan approval. Local OMP must preserve the valid strategy, perform freshness/source checks, and refine only the missing consequential HOW/tests/interfaces before implementation.

## Proposed dependency shape

Three sequential tasks:

1. crawl visual foundation and shell;
2. information hierarchy;
3. action grammar and crawl overlays.

Do not parallelize these by default because Task 02 and Task 03 should consume the crawl-local visual authority established by Task 01 rather than inventing competing style seams.

## Task 01 — Crawl visual foundation and shell

### Intent

Establish a crawl-owned presentation/style authority before individually restyling crawl widgets.

### Proposed work

- Revalidate the current crawl composition and tests locally.
- Introduce the minimum crawl-local style/presentation seam needed for this unit.
- Prefer a `GameScreen`-scoped Material theme or equivalent local boundary where Material widgets benefit from it.
- Recompose:
  - overall crawl background/surfaces;
  - status/header presentation;
  - viewport framing and surrounding layout rhythm.
- Remove duplicated crawl-specific presentation values that the new seam now owns.

### Behavioral proof to preserve

- authoritative status values remain the same;
- map host/controller relationships remain the same;
- exploration/combat composition switches under the same conditions;
- crawl-local theming does not alter global application screens;
- dungeon renderer output/semantics are unchanged.

## Task 02 — Information hierarchy

### Intent

Give timeline, combat/status readout, and logs distinct information roles without changing semantics.

### Proposed work

Recompose:

- activation timeline;
- encounter/combat readout;
- compact log peek;
- expanded log/history;
- unread/follow treatment;
- secondary status/information surfaces.

### Behavioral proof to preserve

- activation order;
- repeated activations;
- information hiding;
- current/selected identity meaning;
- compact-log contents;
- compact ↔ expanded transition;
- log order/causality;
- follow/unread mechanics.

## Task 03 — Action grammar and crawl overlays

### Intent

Give exploration controls, combat actions, targeting states, and crawl-local overlays one consistent interaction vocabulary.

### Proposed work

Recompose:

- exploration controls;
- battle action shelf;
- action icons/labels;
- available, disabled, armed, and active/current states;
- target-selection feedback around the action shelf;
- crawl-local Spells bottom sheet;
- only the immediate crawl-local dialogs/sheets needed to avoid a conspicuous stock-Material break.

### Behavioral proof to preserve

- control visibility and availability;
- disabled controls remain inert;
- authoritative action dispatch;
- arm/unarm transitions;
- target-selection semantics;
- targeted spell execution;
- melee map-first interaction;
- overflow/sheet state.

## Integrated verification intent

After the local execution-grade plan is approved and implementation completes:

- run formatting/static-analysis gates required by the repository;
- run focused Unit 12 tests;
- run broader app/crawl regressions appropriate to the touched surface;
- perform the established save/restoration check when required by the visual-reboot epic;
- collect bounded `Medium_Phone` device evidence for:
  - exploration;
  - combat;
  - armed targeting;
  - expanded log;
  - crawl Spells sheet;
  - greyscale hierarchy/control-state proof.

## Mandatory post-unit decision

After Unit 12 visual acceptance, explicitly answer:

> Does the dungeon viewport now constitute the dominant remaining visual-parity gap against the approved mock?

Record either:

- **YES** → insert Dungeon Structural Asset Expansion as the immediate next unit;
- **NO** → continue the existing visual-reboot roadmap.

Do not pull that work into Unit 12 itself.

## Required local refinement before execution

Local `flow-planning` should refine this strategy into fresh-executor-ready task briefs with:

- exact current file/test seams from fresh recon;
- task starting conditions and dependencies;
- locked decisions vs executor discretion;
- specific Red → Green → Refactor proof for each task;
- interfaces established/consumed across tasks;
- focused verification ownership;
- escalation conditions;
- compact completion receipts;
- integrated acceptance/device evidence procedure;
- plan-quality-gate disposition.

Then stop for **explicit user plan approval**. Plan receipt or bundle validation alone does not authorize implementation.
