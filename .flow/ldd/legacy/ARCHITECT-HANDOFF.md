# Architect session handoff — Residuum epic

You are the **architect session** for the Residuum epic (turn-based dungeon
crawler, Flutter monorepo). You decide, spec, hand off, and verify. You never
write production code. This file is your entry point; the ledger is your
memory and it outranks everything, including any conversation summary you
arrived with.

Regenerated: 2026-09-08, after the m3-craft-risk unit (V4) fully shipped —
merged as PR #9 `bd848f7`, post-merge verified (tree diff empty), main CI
green, close-out done, session flushed (D122–D126). **Next work:
`m3-town-ux` (V3+V5+V6+V7) → m3-quests (M3Q, save v4).**

## First actions, in order

1. Invoke the `flow-ldd` skill and follow its phase loop.
2. Re-orient from `docs/epic/LEDGER.md` in this exact order: the CURRENT
   RESUME snapshot (m3-craft-risk shipped) → the epic status table → the
   decision-log tail (D126 the PR #9 merge and close-out + the worktree
   anomaly; D125 the architect verification and acceptance; D124 the M6
   correction, worker-caught; D123 the three ratified pre-declared rulings;
   D122 the dispatch) → open questions → follow-ups 13, 20, 28, 32–34,
   43–46 (41/42 are CLOSED by M3CH; 43/44 need the author; 45/46 ride later
   units) → environment traps.
3. Skim the canonical sources when a decision touches them:
   `docs/superpowers/specs/2026-08-20-dungeon-game-design.md` (supersessions
   in D27/D28/D34/D35/D40/D43/D46/D50/D55/D59, the battle overhaul
   D71/D74, and D97 — shipped) and `CLAUDE.md` at the repo root. The
   2026-09-03 code audit lives at
   `docs/reports/2026-09-03-audit-residuum-rpg.md` (gitignored, absolute
   path); groups 1 and 2 are both SHIPPED.
4. **No mailbox exists** (`handoff/` retired at the m3-craft-risk close-out)
   and no worker session is open. Start a dispatcher watch only when a unit
   channel opens (at build-prompt dispatch):
   `mailbox watch --as dispatcher --home
   /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff`
   (tool at
   `/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox`,
   wrapped in `bash -c`). A watch's launch receipt is not liveness — verify
   past one poll tick; the watch fires on the watched file's mtime, so your
   own entries cause one spurious wake.
5. **The next work, in order:** `m3-town-ux` (V3+V5+V6+V7 — the FIRST unit
   under the amended D113 method) → m3-quests (M3Q, save v4 — builds on the
   hardened codec). The wave's unit scopes and orders are ALREADY
   brainstormed and locked (D98, as amended D103) — do not re-fork them; go
   straight to recon.

## Where things are

- Repo: `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg`.
  Remote: **GitHub** — `git@github.com:fiatcode-gh/residuum-rpg.git` (ssh);
  `gh` authenticated as `fiatcode-gh` (ADMIN). `gh` works from worktrees.
- **History was rewritten at the GitHub migration (D96)**; cite `bd848f7`
  as main. GitHub PRs: #1 m3-itemids, #2 m3-battle-flow, #3
  m3-save-hardening, #4+#6 m3-chore, #9 m3-craft-risk; the ledger's
  PR #1–#16 citations are Forgejo-era.
- **Merge flow is PR-based (D22), forge is `gh` (D96)**: commit the plan doc
  on the branch, push, `gh pr create` (works from the worktree), per-round
  user approval, user squash-merges in the GitHub UI, architect verifies
  `main` (`git diff <verified-head> origin/main` EMPTY — squash merges are
  invisible to merge-base), then close-out: mirror shots + report, fold the
  mailbox chronologically (strip newlines only, never indents), remove the
  channel, `handoff/` retired, worktree + branch removed, watch stopped
  with the kill confirmed and a process scan, `ls-remote` for stray remote
  branches. The `forgejo` skill is retired for this repo.
- Ledger + epic artifacts: `docs/epic/` — LOCAL, gitignored (D1). Never
  commit anything under it; cite its files by absolute path. Worktrees:
  `.worktrees/<branch>` (gitignored). `docs/plans/` IS tracked — plan docs
  ride the branch (commit them before the push).
- **This monorepo has NO root pubspec — suites run per package directory**
  (`cd packages/<pkg> && flutter test`); from the repo root
  `flutter test packages/<pkg>` fails with "No pubspec.yaml" (D101).
- **CI is LIVE (D118) and ENFORCED (D121):** the `main` ruleset requires the
  three `gates` legs (+ GitGuardian) — a PR cannot merge without a green
  matrix. The workflow must never rename the job or the check names, or the
  required checks silently stop matching (a required check that no longer
  fires is a stuck PR, not a red).
- The user's phone may be attached over wireless debugging and MAY be
  driven by consent (screenshots, taps). Never install or uninstall on it;
  the build is not debuggable — screenshots are the on-device instrument.
  Pin every adb/flutter command to the AVD (`-s emulator-5554`).

## State in one breath (the ledger has the detail)

`main` = `bd848f7` on GitHub, **2077 strict green** at the unit's
verification (860/579/638; D118's all-main baseline was 835/573/637 =
2045), main CI green, branch protection SET (D121). **Unit `m3-craft-risk`
(V4) is SHIPPED**: free benches (tempering's gold cost retired, forge line
ingots-only), tiered level-scaled failure (t1 0% / t2 20% / t3 35%, −2% per
level past the gate, floor 5%; brew 20% − 2%/level, floor 5%, no gate),
lose-1-on-fail, xp on failure, sealed `TownAnswer` (`TownRefusal` |
`CraftLoss`), profile-carried craft stream (`craftRngState`, salt `0x0C7A`,
omit-on-default — save v3 stands, goldens byte-identical). All five band
lines verbatim through the merge. **Playtest #2 verdicts: V1/V2/V8/V9/V10
SHIPPED (battle flow, itemids); V4 SHIPPED (craft risk); V3+V5+V6+V7 = the
next unit.** Band baseline of record (D79-pinned, held byte-identical
through seven merges): crypt 16/40 (40.0% BY RULING), casting 40/40
(informational), greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40.
Save v3 stands. The user's delve sits resumed at Sea-Cave depth 1/5.

## The operating model (hard-won, do not re-derive)

- **Full workflow, every story:** locked scopes (D98, as amended D103) →
  recon fresh (never inherit a number — eight architect claim errors are on
  record, most worker-caught) → story spec → user approval → build prompt →
  user-launched build session (ask which harness EVERY dispatch — pi and
  Claude Code both field-proven; pi last) → evidence-first verification →
  ledger record → PR on user approval. Brainstorm output is a locked ledger
  decision, not a spec file. Every unit is reconned fresh all the same.
- **Build sessions are user-created and user-harnessed.** Address sessions
  through the unit mailbox; send the PATH to the build prompt, never its
  contents; REPORT.md is the designed fallback. A broken session re-binds
  from the mailbox. Run the dispatcher watch only while a unit channel is
  open; restart it FIRST on every wake, before reading anything.
- **Workers pre-declare shape deviations before code** and correct the
  architect freely; corrections that change a locked decision or the
  spec's shape are promoted to the ledger BEFORE the worker continues.
  Invite the worker to ATTACK the spec's central claim by measurement. A
  spec's prediction is a prediction; the worker's observed measurements
  supersede it — and **a mutation row's red set must be expressible at the
  boundary the contract draws** (D124: the spec predicted a red set the
  central contract made unreachable).
- **Verification is yours, with your own instruments:** re-run all suites
  (strict counts from result files — grep `"type":"testDone"` +
  `"result":"success"` minus `"hidden":true`, or the loader events
  overcount by ~35; per package directory); re-run at least one mutation
  row via your own edit — match the row's DEFINITION exactly (D69); read
  the diff at the HUNK level; band lines verbatim; read the shots in
  pixels; re-run format/analyze yourself; re-run a report's claims even
  when they sound settled. Read the report LAST.
- House method: mutation reds as NAMED SETS never counts; analyze from the
  WORKTREE ROOT with pwd quoted, resolution first (D115); goldens BY HAND,
  old value quoted in the same commit; refusal fixtures as their own commit
  BEFORE any codec change; copy BOTH device save slots aside before ANY
  install AND before any play session; salts CHOSEN BY COLLISION SWEEP;
  mailbox stamps from the tool, entries never edited; subagent policy:
  read-only fan-out free, never spawn writers (D9).
- **House method, UI units (amended D113): WIDGET-DRIVEN.** Screen-shaped
  widget tests, phone-sized via a shared helper (`_onAPhone`, 1080×2424 @
  2.625), drive implementation; the AVD pass stays MANDATORY but is the
  final acceptance gate only (one install + save ritual + scripted taps +
  greyscale shots at unit close), never the inner loop. Paint-timing and
  real-disk defect classes remain device-pinned.
- Per-unit close-out order: post-merge verify → mirror shots + REPORT →
  fold the mailbox chronologically into `<unit>-handoff.md` (CLOSED) →
  remove the channel directory → `handoff/` retired → worktree + branch
  removed → watch stopped (kill confirmed + process scan). Fold-check
  removals with errors visible and `ls` the result; `ls-remote` for stray
  remote branches.

## Standing cautions

- **The D56 lesson:** no table edit is ever "additive" to a pinned seeded
  run; bands hold only when nothing bot-visible moves. `Profile.copyWith`
  is hand-rolled field by field — grep EVERY new profile field against
  EVERY boundary that copies one. `craftRngState` is the latest omit-on-
  default example (with `itemNumber`).
- **The actor codec REQUIRES `resists` in a hand-built monster document**
  (D93); duplicate item ids are REFUSED at decode (D108); the tiered lever
  rule stands (content tables free with a trail; bestiary/hero stats
  forbidden without a ruling); **no instrument measures bosses or the
  road** (follow-up 28); the casting line is informational (29, closed);
  **save format v3; m3-quests brings v4 (D59 doctrine)** — the decode
  validation in place (speed/energy/hp/skills/reach/ids) is part of v3's
  contract and v4's codec inherits it; the crypt's floor LAYOUTS are
  byte-frozen forever — `dungeon_door_characterization_test.dart` is the
  sharpest tripwire; the crypt is a 40%-crawl for the melee bot BY RULING
  (D79).
- **The battle interaction is REBUILT (m3-battle-flow, D106)**, the save
  pipeline is HARDENED (m3-save-hardening, D112), and **crafting now rolls
  (m3-craft-risk, D125)** — future craft/save/notice/door work reads
  `m3-save-hardening-spec-M3SH.md` and `m3-craft-risk-spec-M3CR.md` first.
  The forge price-line grammar was left PARTIALLY built by M3CR on purpose:
  the always-visible price + separate refusal word completes it in
  m3-town-ux; the "(worn)" suffix still stands (retires there too).
- Widget traps: `find.textContaining` is case-sensitive;
  `scrollUntilVisible` scrolls one way; size EVERY screen-shaped widget
  test like a phone (`_onAPhone, 1080×2424 @ 2.625`).
- **Format/analyze premises need RESOLUTION first (D115):** a fresh
  worktree must run `dart pub get` per package before any format/analyze
  claim. The ci.yml gate ordering is load-bearing. The lockfile drift gate
  is `ls-files --error-unmatch` + diff (D119).
- **A harness auto-format hook can re-dirty a file seconds after a
  revert** — re-check `git status --porcelain` a beat later (D115; it also
  left whitespace-only drift on a plan doc after the worker's final commit,
  caught at verification).
- Worker harnesses: **background-runner shells may be fish — wrap
  watch/suite commands in `bash -c`**; a watch's launch receipt is not
  liveness — verify past one poll tick; sandbox `rm` can fail silently —
  retry with errors visible.
- **Phone builds are not debuggable** — adb screenshots and taps are the
  on-device instruments; `adb input swipe` needs 1200ms or it is not a
  pan. Machine-reporter test counts need the non-hidden filter.
- **The AVD /data sits at ~89%** — the next install may need the uninstall
  dance (copy-aside FIRST, checksums, then uninstall the old build).
  m3-craft-risk's `install -r` kept data (731 MB free) — recheck before
  assuming. Pixel_10 boots segfaulted four times under the sandbox
  (exit 139, scene init) before the user started the AVD manually —
  the unsandboxed-commands trap; budget a human hand for the boot.
- Accessibility binds every visual fork: deuteranomalous author — state by
  shape, marking, position, or word, never hue; every screen must read in
  greyscale (the author's eye is the final authority).
- Two shells matter: check both from reality once per session — the tool's
  shell: `ps -p $$ -o comm=`; the user's login shell: `basename "$SHELL"`.
  They have disagreed on this machine; write tool commands in POSIX sh and
  wrap bash-only syntax in `bash -c`.
- **Worktree anomaly (D126):** the m3-craft-risk worktree was found already
  removed at close-out, by no recorded hand. Next unit: re-verify the
  worktree exists right after creating it AND again at dispatch.

## The recurring ritual (why this file exists)

The user restarts the architect session whenever its context grows large
or their quota runs out. Before ending a session (or at the user's word,
or after any wave closes): flush decided-but-unwritten state into the
ledger, regenerate THIS file, and tell the user it is ready. The new
session starts with the resume command, then: "resume residuum — read
docs/epic/ARCHITECT-HANDOFF.md".