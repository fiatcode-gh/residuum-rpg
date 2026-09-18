# Residuum RPG — Visual Reboot Unit 12 LDD Handoff

## Handoff status

- Repository: `fiatcode-gh/residuum-rpg`
- Epic: `visual-reboot`
- Observed ref: `60909e60ec3150cf9b590e6641a8ae51efca775c`
- Observed ref meaning: Unit 11 merged by PR #21 (`feat: recompose dungeon scene`)
- Design status: **settled**
- Implementation strategy: **partial**
- Authorization: **not carried**

This is an external ChatGPT → local OMP LDD planning handoff. It carries settled project intent and a proposed implementation strategy, but it does **not** authorize production edits, commits, pushes, pull requests, reviews, merges, releases, or other writes.

## Goal

Continue the `visual-reboot` epic with **Unit 12 — Crawl Interface Visual Grammar**.

The approved WHAT is to recompose the phone crawl interface surrounding the Unit 11 dungeon viewport into the approved Residuum visual language, replacing generic/default Material presentation with a cohesive typography, surface, hierarchy, framing, status, timeline, log, control, and action-state grammar.

## Source facts to preserve

1. Unit 11 is merged on `main` at `60909e60ec3150cf9b590e6641a8ae51efca775c`.
2. Unit 11 owns dungeon viewport rendering. Unit 12 must not reopen dungeon renderer composition or authored dungeon assets as part of ordinary implementation.
3. Unit 12 is crawl-UI work, not core/content/gameplay redesign.
4. Existing gameplay and interaction semantics remain authoritative:
   - melee stays map-first;
   - targeted spells stay `arm → map target → tap`;
   - selection circle and targeting square keep their meanings;
   - activation order, repeated activations, timeline information hiding, log causality/follow/unread behavior, save compatibility, engine authority, and determinism remain unchanged.
5. A post-Unit-12 decision is required: after crawl chrome is visually coherent, reassess whether the dungeon viewport is the dominant remaining parity gap. If yes, insert Dungeon Structural Asset Expansion as the immediate next unit; otherwise continue the existing roadmap.

## Locked scope

### In scope

- crawl-local visual/style authority;
- crawl shell/background/surface hierarchy;
- status/header treatment;
- viewport framing and surrounding spacing/rhythm;
- activation timeline presentation;
- encounter/combat readout presentation;
- compact and expanded log presentation;
- exploration controls;
- combat action shelf;
- available / disabled / armed / active control states;
- crawl-local Spells bottom sheet and closely related crawl overlays when needed to avoid a conspicuous stock-Material break;
- focused tests and bounded `Medium_Phone` evidence.

### Out of scope

- Unit 11 dungeon rendering changes;
- new dungeon structural assets;
- engine authority, combat rules, content, balance, generation, RNG, or save-schema changes;
- standalone Character / Spells / Pack redesign;
- Town or world-map redesign;
- application-wide generic design-system work;
- global theme changes solely to make crawl correct.

## Architectural intent

Fresh source recon in ChatGPT found the crawl chrome concentrated around `game_screen.dart`, `crawl_status.dart`, `battle_view.dart`, and `log_drawer.dart`, with hand-rolled Material presentation and borrowed styling. The preferred direction is a **small crawl-owned presentation/style seam**, locally scoped to the crawl, rather than independently restyling each widget or modifying the global application theme.

Exact filenames and ownership must be revalidated against the local working tree before the execution-grade plan is frozen.

## Proposed sequencing

The current strategy is deliberately **not execution-grade yet**. Preserve the three-part dependency shape while local `flow-planning` refines consequential HOW, tests, interfaces, executor discretion, escalation conditions, and completion receipts:

1. Crawl visual foundation and shell.
2. Information hierarchy — timeline, combat/status readout, compact log, expanded log.
3. Action grammar and crawl overlays — exploration controls, combat shelf, armed/disabled/active states, targeting cooperation, crawl Spells sheet.

See `IMPLEMENTATION-PLAN.md` for the strategy-level proposal.

## Verification intent

Use focused pure/widget behavior tests to protect semantics; do not make screenshot goldens the primary contract. After implementation, run normal repository gates plus focused crawl regressions and collect bounded `Medium_Phone` evidence for:

- exploration;
- combat;
- armed targeting;
- expanded log;
- crawl Spells sheet;
- one greyscale hierarchy/control-state check.

The visual judgement is hierarchy, density, rhythm, typography, framing, contrast, surface/material feel, and action-state clarity—not literal pixel matching.

## Revalidation checklist for local OMP

Before adopting this proposal:

1. Verify current `main` and reconcile if it moved past `60909e60ec3150cf9b590e6641a8ae51efca775c`.
2. Read canonical `.flow/ldd/visual-reboot/LEDGER.md` and `RESUME.md` and reconcile any stale Unit 11 state.
3. Validate this external bundle with the local planning-handoff validator.
4. Reconcile `proposed-ledger-delta.md` and `proposed-units/unit-12.md` into canonical LDD only if still current.
5. Perform fresh source recon for the crawl UI seams and existing tests.
6. Use local `flow-planning` to refine the partial strategy into an execution-grade Unit 12 plan and fresh-executor task briefs.
7. **Stop for explicit user plan approval. Do not implement Unit 12 before that approval.**

## Forward pointer

The Unit 12 WHAT is settled. The next local action is LDD intake + freshness reconciliation + execution-grade planning. No production-write authorization is carried by this handoff.
