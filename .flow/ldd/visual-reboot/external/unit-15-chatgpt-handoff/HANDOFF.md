# Residuum RPG — Visual Reboot U15 LDD Handoff

## Protocol state

- Repository: `fiatcode-gh/residuum-rpg`
- Epic: `visual-reboot`
- Observed ref: `4033de53f96470bfc75dabba6b28bc0ae67816a6`
- Observed ref meaning: current `main`, merge of PR #23 (`Type, palette and surface authority`)
- Design status: **settled**
- Implementation strategy: **partial**
- Authorization: **not carried**

This is a ChatGPT → local OMP LDD planning handoff. It carries the approved U15 WHAT and repo-aligned strategy, but it does **not** authorize implementation, commits, pushes, pull requests, reviews, merges, releases, or other production writes.

## Current integrated state

At the observed ref:

- U13 Visual Parity Re-baseline is integrated.
- U13.1 map-bleed correction is integrated and hardware-confirmed.
- U14 Type, palette and surface authority is integrated.
- Spectral is the text face.
- EB Garamond is the display face.
- `packages/app/lib/style/tokens.dart` owns the shared value/type/theme authority.
- `ResourceMeter` and `LabelledValue` are shared production components.
- Monospace is retired under CI guard.
- `MaterialApp.theme` remains intentionally unused for global stock-control restyling; each screen root opts into the Residuum theme.
- The canonical U13 roadmap names U15 as the next unit.

## LDD reconciliation required first

`.flow/ldd/visual-reboot/RESUME.md` is stale at the observed ref: it still describes PR #23 as awaiting the user's merge choice.

Local OMP must first reconcile durable project state against Git truth:

> PR #23 is merged. `main = 4033de53f96470bfc75dabba6b28bc0ae67816a6`. U14 is integrated. U15 is now the next active visual-reboot unit.

Do not rewrite append-only ledger history; append/supersede stale forward pointers.

## Approved U15

**Unit 15 — Row, Control and Chip Grammar**

Approved WHAT:

> Replace the application's remaining bespoke list-row, navigation-control, filter-control, and crawl-action geometries with the approved shared Residuum grammar established by Unit 13 and implemented by Unit 14, while preserving all existing gameplay vocabulary, dispatch behavior, accessibility semantics, density limits, and information boundaries. Establish concrete empty-ready medallion/icon consumer slots for Unit 16 without generating new authored art in this unit.

## Why U15 is next

U14 established the shared type, colour, theme and surface authority. Current source still contains several bespoke presentation anatomies:

- town destinations;
- character route buttons;
- spell rows;
- pack filter chips;
- pack item rows;
- forge/tavern action presentation;
- crawl action chips.

U15 turns those into concrete production consumer geometry before any new icon/medallion families are generated.

This ordering is important because the new `flow-assets` skill follows:

> generate late, from the real consumer; conform deterministically; accept in context.

U15 therefore establishes the real slots. U16/U19/U20 later use `flow-assets` against those real consumers.

## Important corrections to the old roadmap

### Forge

The approved mock visually shows three Forge actions, including `Craft`, but the current repository has no Craft mechanic or `CraftPressed` equivalent.

U15 must **not invent Craft**.

The Forge may be reorganized around the real mechanics it owns (currently smelting and tempering/bench work), but exact row names and navigation depth must be grounded in current game behavior during local recon.

### Tavern

The current game owns `Ask about the roads`; it does not own the mock's Rest / Listen / Leave set.

U15 must preserve the real game structure and present the real action in the new grammar rather than manufacturing mock verbs.

### Character mana

U14 carried a known presentational defect: Character shows mana capacity through a permanently full resource meter because the screen does not know the current pool.

U15 should present capacity truthfully without adding a false current-mana getter to `TownViewState`.

## Forward pointer

Local OMP should:

1. reconcile stale U14/merge state;
2. validate/reconcile this handoff into canonical LDD state;
3. perform fresh source recon on the U15 consumers/tests;
4. use local `flow-planning` to produce an execution-grade plan and fresh-worker task briefs;
5. stop for explicit user plan approval before implementation.

`authorization = not-carried` is binding.
