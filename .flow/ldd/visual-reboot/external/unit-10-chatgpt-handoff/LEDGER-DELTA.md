# Proposed visual-reboot ledger delta — Unit 10

This is a proposal for reconciliation into the canonical
`.flow/ldd/visual-reboot/LEDGER.md`. It is not canonical authority by itself.

## Current-state update to apply only after local verification

- Assume Unit 9 has been integrated after local acceptance.
- Verify the actual merged `main` contains the Unit 9 tree observed at
  `92fd4aa41558d3c76fc5f6fae69d4e9e96f65e96` before recording its merge SHA.
- Replace the open statement that the post-Unit-8 art pass has no owning unit
  with: **Unit 10 — authored art integration** owns the first repository asset
  pipeline, authored environment art, authored dungeon material sources and
  decorative overlays, and the first explicit non-dungeon/crawl icon language,
  subject to the Unit 10 contract.
- Portraits remain outside this proposal unless matching approved portrait assets
  are actually present and the user explicitly adds them to Unit 10.
- The old-wave M3Q scheduling question remains independent and unresolved unless
  the local ledger already superseded it.

## Proposed decision-log entry

### Unit 10 opening — authored art integration

- 2026-09-16 — The user requested a Flow/LDD handoff for **Unit 10**, explicitly
  assuming Unit 9 is merged.
- ChatGPT observed `residuum-visual-reboot-9` at
  `92fd4aa41558d3c76fc5f6fae69d4e9e96f65e96` and used that tree as the source reference. Public `main` was
  still the Unit 8 merge at observation time, so the local receiving architect
  must bind this proposal to the actual Unit 9 merge SHA after freshness checks.
- Unit 10 is proposed as the owner of the art pass that the epic previously
  deferred beyond Unit 8/9. It is an **app-side presentation unit**: authored art
  may change appearance, never topology, visibility/knowledge, interaction,
  rules, save shape, content, balance, or game-state ownership.
- Proposed scope:
  1. Flutter asset declaration + app-side asset catalogue;
  2. environment illustrations on matching existing town/room surfaces;
  3. authored material sources for Crypt, Sea-Cave, and Ruined Keep, integrated
     under the existing deterministic material/visibility/light architecture;
  4. deterministic non-interactive crack/rubble decoration clipped to
     authoritative geometry;
  5. icon-plus-text treatment on existing controls/actions only.
- Proposed exclusions:
  - no new button/action merely because an icon exists;
  - no icon-only control where a word/count currently carries meaning;
  - no new road material art unless approved assets actually exist;
  - no portrait system in this initial Unit 10 proposal;
  - no core/content/save/RNG/rules changes;
  - no tablet/landscape work.
- Accessibility remains a hard lock: no important state/action is hue-only, and
  the text/number/word reading remains available when an icon is present.
- The authored dungeon layer must remain subordinate to authoritative runtime
  geometry, FOV/knowledge, and interaction. Unknown geometry remains unpainted.
  Authored art consumes no gameplay RNG.
- **Approval status:** the Unit 10 contract is proposed but not explicitly
  approved. Do not dispatch planning/implementation as though WHAT were settled.
  After local asset inventory/source revalidation, present the contract's
  meaningful behavior/boundary/acceptance summary and obtain explicit user
  approval.
