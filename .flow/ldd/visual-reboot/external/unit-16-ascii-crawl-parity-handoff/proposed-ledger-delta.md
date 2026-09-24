# Proposed Ledger Delta — Visual Reboot U16

> Proposal only. Reconcile into canonical append-only LDD history.

## 2026-09-23 — U15 integrated

- Git truth: PR #24 (`feat: establish row control chip grammar`) is merged.
- `main = 374ee775e6fd1c29519dab8fe9d597dd38650593`.
- U15 reported formatter/analyzer/full suite green, 1,127 tests, target-device worst legal chrome 591.238 dp (<600), armed/unarmed map rectangle equality, and save restore MATCH.
- Any forward pointer saying U15 is still active or awaiting integration is stale and should be superseded.

## 2026-09-23 — dungeon presentation pivot

The user approved a new dungeon visual thesis after reviewing pure-ASCII atmospheric mocks:

> Keep the dungeon map pure ASCII (`#`, dotted floor, `@`, enemy glyphs, `<`, `>` and current semantic marks). Make it premium through realistic/code-driven light, darkness, depth/backdrop and restrained parallax rather than generated wall/floor/prop/creature assets.

This supersedes the active-map art direction that required textured authored floor/wall material and the planned structural dungeon asset expansion.

The user also approved the next-unit goal:

> Make the primary crawl/main screen as close as practical to the new ASCII atmospheric mock, with **no asset generation first**. Use neutral placeholders with exact final dimensions for icons/symbols/art to be generated later.

## U16

- New title: **U16 — ASCII Atmospheric Crawl Parity**
- Design status: settled.
- Implementation strategy: partial; fresh local planning required.
- Asset generation: prohibited.
- Authorization: not carried.

## Roadmap supersession

The old U16 `Authored icon and art families` is deferred/re-numbered later.

The old U18–U21 dungeon sequence must not execute as written:

- lighting/value and combat-density responsibilities are pulled into the new U16;
- structural dungeon asset generation is canceled as the chosen main-map direction;
- creature sprites are canceled as a requirement; actor glyph identity remains.

After U16 acceptance, re-cut the remaining asset/town/portrait roadmap against the stable consumers that remain.

## Standing gameplay locks

Repository truth still beats mock copy.

Do not invent:

- Craft;
- Tavern mock-only verbs;
- Torch/Hungry/Clear states;
- Seed display if no authoritative product requirement exists;
- Auto-walk/Help;
- dotted range/path mechanics;
- fake current facts.

No core/content/save/balance change rides U16.

## Next local action

1. reconcile U15 merge and roadmap supersession;
2. validate/reconcile this handoff;
3. fresh source/test recon;
4. execution-grade U16 plan including exact placeholder dimensions;
5. stop for explicit user plan approval.
