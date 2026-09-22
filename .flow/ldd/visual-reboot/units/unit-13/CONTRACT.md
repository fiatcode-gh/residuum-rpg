# Unit 13 — Visual Parity Re-baseline

Status: **complete and accepted; all fourteen criteria met**
Type: architect/design audit. **No production code, no production assets.**
Base: `main` at `907a4a83e7c592d4f6dd0c55e6f30c3b1b8bc49b` (Unit 12's PR #22
merge), on branch `residuum-visual-reboot-13`
Intake: validated external LDD bundle, `authorization: not-carried`
Visual reference: `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`,
all ten frames
Source recon: `units/unit-13/recon.md`

## Outcome

The remaining visual reboot is no longer guided by subsystem sequence. The
epic now has an explicit ten-frame parity inventory, a settled production
visual-language contract, a settled authored-asset strategy, and a recut
roadmap whose units each close named gaps against named approved frames.

## Intake validation, 2026-09-18

The external ChatGPT bundle under `units/unit-13/` was validated before use:

- `sha256sum -c SHA256SUMS.txt` — all seven artifacts OK.
- `validate-planning-handoff.py` — `ok: planning handoff v1 kind=ldd
  repository=fiatcode-gh/residuum-rpg observed_ref=b5aeb2f3…f255d2`.
- The bundle's `reference/approved-visual-reboot-mock.png` is byte-identical
  to the local `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`
  (`0dd2a752…094ed`), so there is no divergence between the external and
  local source of truth.
- **`observed_ref` is stale, and in the bundle's favour.** It observed
  `b5aeb2f` with PR #22 open; `gh` confirms PR #22 **merged** at
  `2026-09-18T08:49:20Z` into `main` as `907a4a8`, which is the local `HEAD`.
  The intervening change is Unit 12's own crawl seam, which the bundle
  already assumed; nothing it relies on is invalidated.
- Working tree at intake: clean apart from the untracked, user-owned
  `units/unit-13/` bundle itself. Nothing was discarded or relocated.

The bundle carries no authorization. Unit 13's WHAT was approved by the user
in the sending session and that approval is honoured rather than re-asked,
because the contract below is materially unchanged from
`proposed-units/unit-13.md`. Unit 13 writes nothing but records, so no local
implementation approval was required to execute it.

## Scope

Audit all ten approved frames — Stonebridge, dungeon exploration, combat,
targeting, expanded combat log, character, spells, pack, forge, tavern — for
composition, typography, density, surfaces and framing, palette and value
hierarchy, iconography, illustration and art, interaction-state
presentation, dungeon structural rendering, and missing asset vocabulary.

Classify every significant discrepancy as `CODE`, `ASSET`, `CODE + ASSET`,
`INTENTIONAL DEVIATION` or `ALREADY ACCEPTABLE`.

Settle typography roles and font policy, colour and accessibility policy,
frame/surface/ornament vocabulary, spacing and density principles, control
state grammar, authored-asset authority, and the boundary between
presentation freedom and locked behaviour. Then recut the remaining roadmap.

## Non-goals

No production UI change, no renderer change, no new production asset, no
gameplay/content/balance change, no save or schema change, no map-bleed
patch, no post-death save debugging, and no execution-grade plan for any
future unit before its WHAT is approved.

## Deliverables

| Artifact | What it holds |
|---|---|
| `recon.md` | what the presentation layer actually is, at `907a4a8`, with file:line |
| `PARITY-AUDIT.md` | the ten-frame audit, frame by frame, with gap IDs |
| `PARITY-MATRIX.md` | the matrix, the cross-cutting decisions, the roadmap derivation |
| `VISUAL-SYSTEM.md` | the settled visual system, asset authority, locks, supersessions |
| `ROADMAP.md` | the recut roadmap, U14–U21, plus defect routing |
| `.flow/evidence/visual-reboot/unit-13-parity/` | 10 mock crops, 10 side-by-side pairs, 10 greyscale pairs |

## Acceptance verdicts
| # | Criterion | Verdict |
|---|---|---|
| 1 | All ten approved frames have a current-state comparison | **met** — `PARITY-AUDIT.md`; frames 9–10 use Unit 10's shots, justified there |
| 2 | Every significant discrepancy uses the shared gap vocabulary | **met** — 77 numbered gaps |
| 3 | Every discrepancy has one ownership classification | **met** — one per row; 4.3 is explicitly an open question, not a classified gap |
| 4 | Typography strategy settled | **met** — `VISUAL-SYSTEM.md` section 1; the font family itself is a user choice with a recommendation |
| 5 | Colour/accessibility strategy settled | **met** — section 2, evidenced by `pair-04-targeting-grey.png` |
| 6 | Surface/frame/ornament vocabulary settled | **met** — section 3 |
| 7 | Authored-asset authority and required families settled | **met** — section 5, eight families, nothing outside them authorized |
| 8 | Presentation freedoms separated from locked contracts | **met** — sections 6 and 7 |
| 9 | Unit 12.5 AC17 superseded on full evidence | **met** — section 8; two dominant families of comparable size, ordering by dependency and cost |
| 10 | Map bleed and save-read candidate each routed, neither solved | **met** — `ROADMAP.md`, U13.1 and the unscheduled save unit |
| 11 | Roadmap recut from the matrix, not from old numbering | **met** — `ROADMAP.md`, derived in `PARITY-MATRIX.md` |
| 12 | Every proposed unit names its target frames and gaps | **met** — every unit names frames, gap IDs, dependencies, protected semantics and its gate |
| 13 | No production file or asset changed | **met** — the diff touches `.flow/` only |
| 14 | Roadmap presented to the user before implementation planning | **met** — presented 2026-09-18 and approved as ordered |

## Settled by the user, 2026-09-18

1. **Font family** — Spectral for text, EB Garamond for display.
2. **The shared style seam** — approved. One shared token module plus sibling
   per-screen themes; a `MaterialApp`-wide restyle of stock Material controls
   stays prohibited. The carry-forward lock is superseded to exactly that
   extent.
3. **Frame 4's three range cells** — a mock flourish. No range or path
   feedback is implied and none will be built.
4. **The world map and the roster** — inherit the vocabulary, no frame
   commissioned, and U14 owes the first device shot of each in colour and
   greyscale; U15 and U17 re-shoot them when their changes land.
5. **Roadmap** — approved as ordered: U13.1, then U14 through U21.

## What this approval does and does not authorize

It authorizes the roadmap's shape and Unit 13's decisions. It is **not**
implementation authority for any unit: each still needs its own contract
approval, and where it carries consequential HOW, its own plan approval. It
is not publication authority — push, pull request and merge remain separate
gates.
