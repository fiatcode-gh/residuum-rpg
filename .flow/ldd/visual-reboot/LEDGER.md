# Visual Reboot — Decision Ledger

Reboot the presentation and interaction layer of the existing M3 Flutter
game around a graphical-glyph, phone-first visual language — without
discarding the game. Existing core rules, content, deterministic
simulation, economy, saves, and progression remain product truth unless a
later decision here explicitly changes them. Canonical product spec:
`../product/2026-08-20-dungeon-game-design.md`; M3 contracts and traps:
`../m3/LEDGER.md`.

## Mode

- shared (tracked in git)

## Intake

The epic was opened from an approved external planning handoff:
`external/residuum-visual-reboot-handoff.md` (approved design direction,
795 lines, 18 sections). Intake status per the planning-handoff protocol:

- The handoff is **approved design direction, not an execution plan and not
  implementation authorization**. It proposes its own unit sequence
  (Units 0–8), which this ledger adopts as the working plan below.
- The approved mock (`residuum_visual_reboot_approved_mock.png`) is named as
  visual authority but is **not present in the repository** — the user must
  supply it (suggested home: `.flow/evidence/visual-reboot/`). Until then,
  the handoff's written descriptions are the only mock evidence.
- Where the mock conflicts with current game content, the repository is
  truth (handoff section 2). Do not invent gameplay objects from mock
  illustration.
- Section 12.4's seam inventory (`glyph_grid.dart`, `game_bloc.dart`,
  `battle_view.dart`, etc.) is evidence — fresh recon must verify it before
  any implementation.

## Current state

- **bootstrapped; no unit dispatched; no production code written.**
- Next: **Unit 0** (design baseline and recon — read-only). Its output is
  the behavior-preservation matrix and the seam list; it ends by proposing
  the Unit 1 contract for review.
- Gate inherited from the handoff's kickoff instruction: **no production
  code until the Unit 1 contract is reviewed.**

## Epic status

| Unit | Dependencies | State | Verification | Notes |
|---|---|---|---|---|
| Unit 0 — design baseline + recon | none | next | recon claims verified at source; no code | behavior-preservation/change matrix, seam inventory |
| Unit 1 — dungeon scene foundation | Unit 0 | pending | crypt floor fully playable through new scene, no simulation divergence | Flame-in-Flutter proof; fallback retained until accepted |
| Unit 2 — graphical dungeon language | Unit 1 | pending | target-size screenshot matches approved direction | deterministic texture, lighting, fog |
| Unit 3 — crawl interaction reboot | Unit 2 | pending | one-handed movement/melee/targeting/wait/pack without the old dock | map-first melee; favorites + overflow |
| Unit 4 — turn timeline + duplicate identity | Unit 3 | pending | next activation sequence readable with duplicates + fast actors | encounter-local labels, timeline→map highlight |
| Unit 5 — log drawer | Unit 3 | pending | history reviewable during combat without shrinking the map | 3-line peek, half/full overlay, auto-follow |
| Unit 6 — character / spells / pack | Unit 3 | pending | no duplicated information architecture | consolidation |
| Unit 7 — town + rooms + heroes | Unit 6 | pending | transactional/refusal semantics preserved | art bible locked before static art |
| Unit 8 — world + theme parity | Unit 7 | pending | final accessibility + device-size pass | Sea-Cave/Keep material identity |

Units 3/5 may reorder by recon findings; the sequence is the handoff's
proposal, not yet a locked order — lock it at Unit 0 close.

## Locked cross-unit contracts (inherited from the handoff, section 18)

- Phone-first; tablet later. Flame only for the dungeon scene — never the
  whole app, and **Flame is never authoritative game state**.
- Graphical-glyph dungeon (not sprite-tile), procedural deterministic
  terrain texture, smooth lighting over rules-driven FOV.
- Four-region responsibility rule: map = space/targets, timeline = time,
  log = causality, action shelf = verbs. No concern duplicated across
  regions.
- Map-first melee (tap adjacent enemy); explicit Attack shelf control is
  removed once direct melee is proven; long-press/timeline token inspect,
  never long-press-only.
- Targeted abilities: arm → map target marks → tap to cast; disarm path
  obvious.
- Full spell access with compact favorites/readied presentation + overflow
  (progressive disclosure, NOT a mechanical kit restriction; promotion to a
  true prepared-kit system is a separate future decision).
- Activation queue replaces `NOW`/`IN n` prose; repeated fast-actor
  activations shown literally; duplicate enemies get stable encounter-local
  labels used consistently across map/timeline/targeting/inspect/log.
- 3-line scrollable log peek + half/full overlay history; auto-follow with
  `↓ N new` return affordance.
- No pinch zoom in the first pass; no decorative interactable-looking props
  unsupported by rules; non-dungeon UI quiet and subordinate to the map.
- Accessibility non-negotiable (AGENTS.md + handoff 3.5): no important state
  carried by hue alone; targeting marks readable in greyscale/value.
- Input boundary: Flame hit-tests and emits intents; app state decides
  meaning and dispatches core actions. Presentation actor labels are not
  core entity identity.
- Dependency rule `app → content → core` preserved; no combat balance,
  content, generator, or recipe changes ride this epic (explicit non-goals,
  section 14).
- Everything locked in `../m3/LEDGER.md` (save v3, band controls, house
  method D113, CI/merge flow) still binds.

## Environment traps

- All M3 traps carry (`../m3/LEDGER.md`): no root pubspec (suites per
  package dir); copy BOTH device save slots aside before any install; phone
  build not debuggable (adb screenshots only); squash merges invisible to
  merge-base; never rename CI job/check names; widget-driven UI units with
  the AVD pass as final acceptance gate (D113).
- The band lines remain byte-identical controls for anything that could
  touch balance — this epic should not move them at all (non-goal).
- Old-era artifact paths in any inherited text (`docs/epic/…`,
  `docs/plans/…`, `docs/superpowers/…`) are stale — the docs tree merged
  into `.flow/ldd/` on 2026-09-13.

## Open questions

### User/product decisions

- Supply the approved mock PNG and fix its evidence home.
- Art bible (handoff 11.4): palette, lighting rules, engraving treatment,
  texture density, portrait framing, icon language, contrast targets — must
  be locked with the user before Unit 7's static art (and ideally before
  Unit 2 sets the material language).
- Do Units 3/5/6 keep the proposed order, and does the old-wave m3-quests
  (M3Q, save v4, `../m3/LEDGER.md`) still run, and where in the sequence?
- Tablet composition is explicitly deferred — confirm it stays out of scope
  through Unit 8.

### External dependencies

- Curated static art generation (section 11.2) requires a generation
  workflow outside the repo — owner and tool not yet decided.

## Decision log

Append-only. Supersede old decisions; do not rewrite history.

- 2026-09-13 — Epic bootstrapped during the docs/LDD restructure. The
  external handoff is accepted as approved design direction; its proposed
  unit sequence is adopted as the working plan; its baseline summary is
  recorded as inherited locked contracts pending Unit 0 recon validation.
  No implementation authorization granted yet — Unit 0 (read-only recon)
  is the first authorized step, and the Unit 1 contract requires review
  before any production code.

## Verification receipts

- None yet. (Intake reconciliation above is a read of the handoff only;
  no repository claims in it have been verified at source. Unit 0 does
  that.)

## Corrections to inherited assumptions

- None yet — expected to arrive from Unit 0 recon (the handoff's own
  section 12.4 says its paths/details are evidence, not permission to skip
  repo inspection).