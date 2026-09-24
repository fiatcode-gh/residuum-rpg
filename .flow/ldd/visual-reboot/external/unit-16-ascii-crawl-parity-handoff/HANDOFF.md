# Residuum RPG — Visual Reboot U16 LDD Handoff

## Protocol state

- Repository: `fiatcode-gh/residuum-rpg`
- Epic: `visual-reboot`
- Observed ref: `374ee775e6fd1c29519dab8fe9d597dd38650593`
- Observed ref meaning: current `main`, merge of PR #24 (`feat: establish row control chip grammar`)
- Design status: **settled**
- Implementation strategy: **partial**
- Authorization: **not carried**

This is a ChatGPT → local OMP LDD planning handoff. It carries the settled post-U15 dungeon/main-screen direction and a repo-grounded partial strategy. It does **not** authorize implementation, commits, pushes, pull requests, reviews, merges, releases, asset generation, or other production writes.

## Current integrated state

At the observed ref:

- U15 is merged through PR #24.
- Stable `CrawlAction.id` is now independent from display label/cost/count.
- Crawl actions carry separated `label` and `metadata`.
- The legal eleven-action ceiling is still proven on the target phone.
- Worst legal device chrome is **591.238 dp**, below the locked 600 dp ceiling.
- Armed/unarmed evidence kept the same map rectangle and the fixed 36 dp camera cell.
- U15's shared `FramedRow` exposes stable 44 dp leading envelopes / 36 dp untinted wells for later non-crawl art work.
- U15 generated no new authored production art.

## LDD reconciliation required first

`.flow/ldd/visual-reboot/RESUME.md` is stale at the observed ref. It still says U15 is active and awaiting integration.

Local OMP must supersede that forward pointer with Git truth:

> PR #24 is merged. `main = 374ee775e6fd1c29519dab8fe9d597dd38650593`. U15 is integrated. U16 — ASCII Atmospheric Crawl Parity — is the next active visual-reboot unit.

Do not rewrite append-only ledger history.

## Product-direction pivot

After U15, the user explicitly rejected continued dependency on generated structural dungeon art.

The new approved dungeon thesis is:

> The dungeon is **pure ASCII semantics plus atmospheric rendering**. Terrain and actors remain glyphs; richness comes from light, darkness, depth, restrained motion and composition — not from textured wall/floor tiles, creature sprites or decorative dungeon assets.

The goal of U16 is to make the **primary crawl/main screen as close as practical to the new ASCII atmospheric mocks**, using code, current game facts and exact-dimension neutral placeholders only.

No new authored asset generation happens in U16.

## Approved U16

**Unit 16 — ASCII Atmospheric Crawl Parity**

Approved WHAT:

> Recompose the primary crawl screen toward the approved pure-ASCII atmospheric direction using only code, existing authoritative game state, existing already-shipped UI art where it remains useful, and exact-dimension neutral placeholders for future icons/symbols. Replace active textured dungeon terrain rendering with pure ASCII terrain (`#`, floor dots, `<`, `>` and existing actor/item glyph semantics), add code-driven atmospheric lighting plus a non-semantic depth backdrop with restrained camera-relative parallax, and bring exploration, combat/targeting, recent-events and expanded-log states substantially closer to the new mocks while preserving gameplay, input, information secrecy, determinism, fixed grid geometry and action semantics.

## Reference authority

Included references:

- `reference/ascii-atmosphere-art-bible.png`
- `reference/ascii-exploration-mock.png`
- `reference/ascii-combat-targeting-mock.png`
- `reference/ascii-expanded-log-mock.png`

These are **appearance/composition references**, not gameplay specifications.

Repository truth wins for:

- available actions;
- state vocabulary;
- dungeon/location names;
- stats and resource facts;
- targeting rules;
- timeline semantics;
- pack/equipment facts;
- any mock-only copy such as `Torch`, `Hungry`, `Clear`, `Seed 42`, `Auto-walk`, `Help`, or a dotted range path.

Do not invent mechanics or fake interactive controls to copy the mock.

## Core visual rule

The active dungeon map must no longer rely on dungeon floor/wall texture images, rubble overlays or graphical structural tile art.

For dungeon presentation:

- wall = ASCII `#`
- walkable floor = ASCII dot field (`.` or typographically equivalent dot chosen by the implementation plan)
- player = existing `@`
- enemies = existing accessible glyph identity
- stairs = `<` / `>`
- existing semantic item/material marks remain glyphs where authoritative
- target/selection marks remain code-drawn geometry
- unknown/remembered/visible states remain value/opacity/light distinctions

No image may carry terrain topology or actor identity.

Existing environment illustrations outside the crawl are unaffected.

## Atmosphere without dungeon assets

Atmosphere is code-driven:

1. semantic ASCII layer;
2. visibility-respecting light/falloff;
3. non-semantic depth/backdrop field;
4. optional restrained parallax of the depth layer relative to camera movement.

The depth layer must never reveal unseen geometry, imply collision, add interactable-looking objects, or influence hit testing.

No autonomous random animation is required. Camera-relative parallax is preferred because it creates depth without frame-clock nondeterminism.

## Forward pointer

Local OMP should:

1. reconcile U15 merge state and this roadmap supersession;
2. validate/reconcile this handoff into canonical LDD;
3. perform fresh source/test recon;
4. use local `flow-planning` to settle exact main-screen geometry, placeholder dimensions, renderer seams and task briefs;
5. stop for explicit user plan approval before implementation.

`authorization = not-carried` is binding.
