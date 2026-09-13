# M3 — Decision Ledger

Grow the game from a crawl-plus-town loop into the M3 milestone of the
canonical design spec (`../../../docs/specs/2026-08-20-dungeon-game-design.md`):
saves and the hero roster, the overworld with travel and rumors, themed
dungeons with rolled depth and bosses, rebalance, magic, crafting, the
battle overhaul, and the defect/UX units fed by playtests. Governed also by
`AGENTS.md` conventions.

## Mode

- shared (tracked in git)

## Current state

- **closed except `m3-quests` (M3Q)** — every dispatched unit is merged and
  accepted. M3Q (save v4, side-quest templates/quest state/payouts/
  reputation) was locked into the wave (D98) but never specced or
  dispatched; the visual-reboot epic (`../visual-reboot/`) is now the
  active epic and owns whether/when M3Q runs.
- Test-count figures below are carried forward from the era, not fresh —
  re-measure on `main` before relying on them. Current `main` after the
  last accepted unit (m3-town-ux): `85e8bcc`.

## Epic status

| Unit | Story | State | Merge | Notes |
|---|---|---|---|---|
| m3-rng | M3R | merged | `3e49d85` | splitmix64 behind the `Rng` API; same-seed determinism |
| m3-saves | M3S | merged | `eb4689f` | multi-hero suspend-save, corrupt fallback, rolled worlds |
| m3-heroes | M3H | merged | `37a7383` | roster, merchant buy-back, first widget tests |
| m3-leave | M3L | merged | `6f8ac86` | suspend at the stairs; resume or delve anew |
| m3-world | M3W | merged | `5ba2b39` | overworld, travel days, road encounters, rumors |
| m3-dungeons | M3D | merged | `cebc06b` | sea-cave + ruined keep; core diff EMPTY; crypt pin promoted to code assertions |
| m3-depth | M3X | merged | `e762162` | a delve rolls its depth (derived, no save change) |
| m3-balance | M3B | merged | `0bc6db2` | pierce, scarcity, camp expiry; bands re-pinned by design |
| m3-magic | M3M | merged | `08f60e6` | three schools, six spells; save v1 → v2 (sanctioned break) |
| m3-craft | M3C | merged | `5d154fb` | gathering, smelt/temper/brew; save v2 → v3 |
| m3-fixes | M3F | merged | `a2cc723` | road carries magic; remembered nodes; Character screen |
| m3-dock | M3V | merged | `eb2877f` | battle docks over the map; the map never leaves the screen |
| m3-battle | M3U A | merged | `1054142` | ambush opening, explicit cast targets, the `reach` field, the spitter |
| m3-battle-ui | M3U B | merged | `c6b730c` | battle screen: stage, turn strip, skill bar, tap-to-target |
| m3-battle-flow | M3BF | merged | `d2b78be` (GitHub PR #2) | armed-target actions, wait verb, dock chips |
| m3-itemids | M3I | merged | `a990414` (GitHub PR #1) | pack item id minted once; V10 duplication bug dead |
| m3-save-hardening | M3SH | merged | `b2c1381` (GitHub PR #3) | save pipeline stops failing silently |
| m3-chore | M3CH | merged | `348cb14` + `e0544f4` (GitHub PRs #4/#6) | CI gates, analyzer config, lockfiles, READMEs |
| m3-craft-risk | M3CR | merged | `bd848f7` (GitHub PR #9) | free benches, tiered level-scaled failure |
| m3-town-ux | M3TUX | merged | `85e8bcc` (GitHub PR #10) | forge price grammar, steppers, Worn/Carried bench, merchant stacking |
| m3-quests | M3Q | not started | — | save v4; only by a future wave decision |

GitHub-era PR numbers are #1–#10 as cited; older citations (#1–#16) are
Forgejo-era and stale since the history rewrite (D96).

## Locked cross-unit contracts

- **Save format v3 stands** (v1 → v2 at M3M, v2 → v3 at M3C; both codecs
  omit-on-default). Save breaks are sanctioned per-unit — D59 doctrine:
  never declare "the last break".
- **Band baseline of record (byte-identical controls for any unit touching
  balance/combat; carried forward, not fresh — re-verify before relying):**
  crypt `16/40 (40.0%) {1:1,2:9,3:8,4:6,5:16}` — the crypt's soft floor is
  0.40 BY RULING (D79), sea-cave/keep keep 0.45; casting build `40/40`
  (informational, kit door); greedy `16` / fleetfoot-first `13`; sea-cave
  `26/40`; keep `24/40`.
- **House method (D113):** UI units are widget-driven — phone-sized widget
  tests via a shared helper drive implementation; the AVD pass is mandatory
  but is the final acceptance gate only (one install + save ritual +
  scripted taps + greyscale shots). Paint-timing and real-disk classes stay
  device-pinned.
- **CI is live and enforced (D118/D121):** the `main` ruleset requires the
  three `gates` legs (+ GitGuardian). The workflow must never rename the job
  or check names — a required check that no longer fires is a stuck PR.
- **Merge flow (D22/D96):** PR-based, forge is `gh`; per-round user
  approval; the user squash-merges in the GitHub UI; the architect verifies
  `main` by `git diff <verified-head> origin/main` EMPTY (squash merges are
  invisible to merge-base).
- Everything M1/M2 locked (state model, dependency rule, injected `Rng`,
  seeded determinism) still binds.
- **Tiered lever rule:** content tables are free with a measured trail;
  bestiary/hero stats need a user ruling.
- Accessibility (AGENTS.md, non-negotiable): encode state/rarity by shape,
  marking, position, or word — never hue alone; every screen reads in
  greyscale. The author is deuteranomalous and is the final visual
  authority; greyscale shots accompany every UI unit.

## Environment traps

- This monorepo has NO root pubspec — suites run per package directory
  (`cd packages/<pkg> && flutter test`); `flutter test packages/<pkg>` from
  the root fails (D101).
- **Copy BOTH device save slots aside (with hashes) before any install** —
  `flutter install` has destroyed device saves twice (M3M/M3X era); the
  copy-aside ritual saved them both times.
- The user's phone build is not debuggable — `run-as` is refused; adb
  screenshots + taps are the on-device instruments (consent-driven). Never
  install/uninstall on the user's phone.
- `adb input swipe` needs ~1200ms; fish shells wrap in `bash -c` (old-harness
  watches died of this).
- Harness auto-format hooks can re-dirty a reverted file — re-check status
  a beat later; format-clean requires the resolved language version.
- The lockfile drift gate is diff-blind to deletion — closed with
  `git ls-files --error-unmatch`.
- Widget tooling: `find.textContaining` is case-sensitive;
  `scrollUntilVisible` is one-way.
- The actor codec REQUIRES `resists` in a hand-built monster document —
  hand-staged saves without it are refused whole (fallback works as
  designed) (D93).
- Crypt floor layouts are byte-frozen; the crypt 0.40 floor is by ruling.
- No instrument measures bosses, the road, or magic deeply (the casting
  line is informational) (follow-ups 28/29).
- No instrument measures the band lines' boss floors — no bot fights a boss.
- Old-era harness mechanics (mailbox channels, dispatcher watches,
  `watch-architect.sh`, worktree-per-unit dispatch via `claude -n`) are
  retired execution mechanics — revalidate against the current stack, do
  not resurrect them from the legacy ledger.

## Open questions

### User/product decisions

- m3-quests (M3Q, save v4): locked into the D98 wave but not dispatched —
  the active epic decides whether it still runs and when.
- Legacy follow-ups still open at M3 close: 13, 20 (v1-freeze wording —
  superseded in practice by the D59 doctrine), 28, 32–34, 43–46 (43/44 need
  the author; 45/46 ride later units).

### External dependencies

- GitHub (`git@github.com:fiatcode-gh/residuum-rpg.git`), `gh` authenticated
  as `fiatcode-gh`. Branch protection active on `main`.

## Decision log

Append-only. Full D-number history (D1–D126): `../legacy/LEDGER.md`. The
entries below are the ones a future architect must still know.

- 2026-08-24 (D55) — M3M forks: typed spells only, hero-only mana, three
  schools, save break sanctioned (v2). Consequence: the four then-band
  lines became byte-identical controls.
- 2026-08-25 (D59) — M3C forks: save v3, materials as counters, lean scope;
  corrected doctrine: save breaks are sanctioned per-unit; never claim a
  "last break".
- 2026-09-02 (D90/D91) — playtest defect: the battle view replaced the map
  and could trap the hero. Ruled: the battle view docks over the map, no
  full swap ever. Consequence: m3-dock (M3V).
- 2026-09-03 (D97/D98) — playtest verdicts V1–V10 locked the wave order:
  itemids → battle-flow → craft-risk → town-ux → quests. All but quests
  shipped.
- 2026-09-03 (D102/D103) — the four-lens audit (evidence in
  `../evidence/2026-09-03-audit-residuum-rpg.md`) routed group 1 (save
  hardening) and group 2 (CI chore); both shipped.
- 2026-09-07 (D113) — house method amended: UI units widget-driven, AVD as
  final acceptance gate. Applies from m3-town-ux onward.
- 2026-09-08 (D126) — m3-craft-risk closed as PR #9; main CI green.
  Last pre-restructure RESUME state of the M3 era.

## Verification receipts

- Each unit's merge was verified at its time by the architect's own
  instruments (suite runs, band-line byte-compares, hunk-level diff reads,
  mutation re-runs, shot reads) — receipts per unit in
  `../legacy/LEDGER.md` (D-numbers cited above). This ledger carries the
  merge hashes; it does not re-assert the era's test counts as current.

## Corrections to inherited assumptions

- Pre-rewrite hash citations and Forgejo PR numbers are stale (D96) — cite
  the hashes in the table above.
- D113–D119 are dated 2026-09-08 but were decided 2026-09-07 (WIB) — dating
  error, content unaffected.