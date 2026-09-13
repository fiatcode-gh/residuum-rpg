# m3-craft-risk — handoff (CLOSED)

The unit's mailbox, folded chronologically. Story M3CR, verdict V4 — free
benches, tiered level-scaled craft failure. Verified and accepted by the
architect (D125), shipped as PR #9 (`bd848f7` on GitHub main). The channel
directory is retired; this file is the record.

## 1 — dispatcher — 2026-09-07T18:13:21+07:00
Dispatch: you are the build session for m3-craft-risk (story M3CR, verdict V4 — free benches, tiered level-scaled craft failure).

First command: cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-craft-risk && pwd — confirm the output.

Read in full and execute the build prompt at:
/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-craft-risk-build-prompt.md

It names the spec (absolute path), the worktree, the method (written plan first, then TDD), the mutation table, and your verification block. The mailbox tool lives at:
/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox
— every write to worker.md goes through it; answers come from dispatcher.md here.

Pre-declare any deviation from the spec BEFORE code. Disagreement in the open is expected behaviour — attack the spec central contract by measurement.

disposed through worker entry: none yet

## 1 — worker — 2026-09-07T18:18:25+07:00
Worker ack. Worktree confirmed at the m3-craft-risk path. Build prompt and dispatch read in full. Now reading the spec before anything else; plan doc lands at docs/plans/2026-09-07-m3-craft-risk.md before any code. Will pre-declare any deviation in this mailbox first.

disposed through dispatcher entry 1

## 2 — worker — 2026-09-07T18:21:41+07:00
Pre-declaring three rulings BEFORE code, per the build prompt. None changes a locked V4 decision; all three are gaps the spec does not cover.

1. How the failure notice rides. The spec says the transaction signatures do not change, but Transacted = (Profile, TownRefusal?) cannot honestly carry a failure: TownRefusal's own contract is that a refused transaction changes nothing at all, and a failed craft DOES change the profile (one ingot gone, skill trained). Returning a failure as a TownRefusal would make that documented contract a lie and would suppress the level-up path in town_bloc's _crafted for an attempt that trained. Plan: temperItem and brewPotion return a widened Crafted = (Profile, TownRefusal?, CraftLoss?) — a new small Equatable class CraftLoss carrying the loss sentence; refusal stays the second voice, loss the third. town_bloc's _crafted gains one branch: a loss shows its sentence in the notice slot; parameters and purity are untouched. I read the spec's 'signatures do not change' as 'same pure parameter shape, profile in, profile out' — flag me if you meant the return type literally.

2. M1's '+0' prose. The odds are keyed on the tier being bought: a tier-2 attempt starts from an item at +1 (gate Blacksmith 5). 'A forced-fail temper leaves the item at +0' cannot be literal — an item at +0 is a tier-1 attempt, which never fails. I read it as 'the item does not gain its tier'. Test: item at +1, forced-fail state, blacksmith 5 -> item still +1, exactly 1 ingot lost, Blacksmith trained.

3. Level-up versus loss on one notice line. A failed attempt still trains and can also level. The slot shows one line; the loss is the news, so on a failed attempt the loss sentence wins over the level-up sentence. Success paths keep today's wording exactly.

Also attacking the two named claims and accepting both as written: the brew odds (no gate is right — Herbcraft has no tiers today, and a gate would lock the only thing herbs are for behind training a new hero has no reason to have started; floor at level 8 keeps failure alive forever, same shape as tempering) and one-attempt-one-advance (skipping the draw on the 0% tier would make stream consumption outcome-dependent, which is exactly what the determinism story cannot afford). Disposed through 1.

disposed through dispatcher entry 1

## 3 — worker — 2026-09-07T18:22:02+07:00
Correction to ruling 1 in entry 2, before any code exists. A third tuple slot would break every existing two-element destructure of temperItem/brewPotion across the suites. Better shape: a sealed base — TownAnswer (sentence) with TownRefusal and CraftLoss as its two kinds; Crafted = (Profile, TownAnswer?) stays a 2-tuple, so existing tests and call sites compile untouched. TownRefusal keeps its 'changes nothing' contract intact; CraftLoss is a different kind of answer, not a subclass faking one. town_bloc's _crafted still gains the one branch: a loss answers in its own sentence and yields the level-up line (ruling 3 stands). This is the shape the plan will build.

disposed through dispatcher entry 2

## 2 — dispatcher — 2026-09-07T18:22:24+07:00
All three rulings RATIFIED — proceed on entry 3's shape.

1. Sealed TownAnswer with TownRefusal and CraftLoss as kinds, Crafted = (Profile, TownAnswer?) — approved as the ruling of record. Your reading of the spec is the one I meant: pure parameter shape, profile in / profile out; the return type widens to the sealed answer. Entry 2's third tuple slot is superseded; good catch before code.

2. M1 corrected: your reading is right and the spec prose was sloppy — the mutation row means "the item does not gain its tier" (item at +1, forced-fail state, Blacksmith 5 -> still +1, exactly 1 ingot lost, skill trained). Build the test your way.

3. Loss sentence wins the notice slot on a failed attempt; success wording unchanged. Ratified as ruled.

All three are promoted to the ledger as D123 before you continue. The two named claims stand as written per your own attack. Carry on — plan doc, then code.

disposed through worker entry 3

## 4 — worker — 2026-09-07T18:23:53+07:00
Plan written and committed to the branch: docs/plans/2026-09-07-m3-craft-risk.md (commit bb83e68). It embeds the four pre-declared rulings from entries 2-3 and maps every spec section to a task, with the mutation table as its closing task. Executing it now, inline per flow-executing-plans' complexity judgment, flow-tdd throughout. Next entry reports at the done notice.

disposed through dispatcher entry 3

## 5 — worker — 2026-09-07T18:44:50+07:00
PAUSED just before the device-acceptance pass, on the user's instruction (laptop battery). State: all nine plan tasks done and committed (10 commits on m3-craft-risk, HEAD e99025b, tree clean); suites 2077 strict green (core 860 + content 579 + app 638, fresh, zero failures); mutation table complete, reds as named sets; band trail and goldens byte-identical; format/analyze clean x3 after pub get. REPORT.md is in the handoff directory with every item evidenced, including two spec-claim findings (M6's named red set is unrepresentable at the profile boundary — details in the report). Device pass NOT started: first emulator boot segfaulted in mesh3d scene init, the retry was killed before it could report, and the save ritual never began. Resume point: boot Pixel_10, save ritual with checksums, build + install, forge-bench greyscale shot, restore saves. The mailbox watch stays up; I will dispose of new mail as it arrives.

disposed through dispatcher entry 4

## 6 — worker — 2026-09-07T18:45:05+07:00
Cursor correction on entry 5: true disposed-through is 2, not 4 — I miscounted on entries 4 and 5 and only just read dispatcher entry 2 with my own eyes. No mail was acted on late in a way that matters: entry 2 RATIFIES all three rulings as D123, and the code already stands on exactly the ratified shape (sealed TownAnswer, Crafted = (Profile, TownAnswer?), M1 test from +1, loss sentence wins the notice slot) — zero rework. Paused as stated in entry 5, before the device pass. Resume point unchanged.

disposed through dispatcher entry 2

## 3 — dispatcher — 2026-09-07T18:45:27+07:00
Paused state acknowledged — no objection, resume point agreed exactly as you wrote it.

The M6 spec-claim finding is RATIFIED and promoted to the ledger (D124) before you continue: the spec's named red set was unrepresentable at the profile boundary, your actual mutation's red set (the four craftDraw unit tests) is the row's red set of record, and the roll-for-roll/resume tests stand as the boundary tripwire. Well caught — same lineage as the chore unit's two catches.

Nothing else pending from me. When the user resumes you: boot Pixel_10, save ritual with checksums (copy BOTH slots aside FIRST, checksums), build + install, forge-bench greyscale shot, restore saves — then the done notice. Mind the ~89% /data trap and pin -s emulator-5554.

disposed through worker entry 6

## 7 — worker — 2026-09-07T18:45:28+07:00
PAUSING on the user\'s instruction (laptop battery), just before the device-acceptance pass. Full state is in REPORT.md and entry 5; short form: all nine plan tasks done and committed (10 commits on m3-craft-risk, HEAD e99025b, tree clean), suites 2077 strict green fresh with zero failures, mutation table complete with reds as named sets, band trail and v3 goldens byte-identical, format/analyze clean x3. Device pass NOT started: two boot attempts of Pixel_10 both segfaulted (exit 139, scene init) and the ritual never began — no install, no uninstall, no save touched. The mailbox watch stays up; on resume I boot the AVD, run the save ritual, and shoot the forge bench.

disposed through dispatcher entry 2

## 8 — worker — 2026-09-08T07:10:29+07:00
Resume ack. Entry 3 read with my own eyes: M6 finding ratified as D124, the craftDraw unit tests are the row's red set of record, roll-for-roll/resume tests stand as the boundary tripwire. Watch restarted after this entry. Starting the device pass now, in your stated order: boot Pixel_10, both save slots copied aside FIRST with checksums, then build + install pinned to emulator-5554, forge-bench greyscale shot, saves restored, done notice.

disposed through dispatcher entry 3

## 9 — worker — 2026-09-08T07:21:41+07:00
DONE — m3-craft-risk build complete, REPORT.md mirrors the verification block in this directory.\n\nWorktree proof: 11 commits on m3-craft-risk only (HEAD a119643), tree clean, nothing under docs/epic/ committed.\n\nCounts, measured fresh at close: 2077 strict green (core 860 + content 579 + app 638, zero failures) against a fresh-measured baseline of 2045 on unmodified e0544f4 — matches the carried D118 number exactly.\n\nCharacterization: all three suites green on unmodified code before the first change; band trail and goldens green in that same run.\n\nMutation table: all seven rows run, reds as named sets (full table in REPORT.md). M6's finding stands ratified as D124 — the red set of record is the four craftDraw unit tests.\n\nBand trail + goldens: all five lines byte-identical to baseline (crypt 16/40, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40); golden save test green throughout; crypt tripwire never reddened.\n\nFormat/analyze: clean x3 after pub get per package (the D115 trap bit twice and was caught both times).\n\nDevice acceptance: DONE. The sandbox could not boot the AVD (four SIGSEGVs — the unsandboxed-commands trap); the user started the AVD and the pass ran pinned to emulator-5554. Save ritual first (both slots aside, sha256 18dbf676... / 4b6f8e29...), install -r kept data (731 MB free, no uninstall dance), acceptance save crafted from the user's own hero and pushed via run-as stdin, forge-bench greyscale shot saved here as forge-bench-greyscale.png showing 'Next tier: 1 ingot.' with no gold term and greyscale-legible marks, both slots restored byte-exact and verified. The user's playtest crawl is untouched; app left closed as found.\n\nWhat the tests cannot prove is stated in REPORT.md, as are the two spec-claim findings (M6 red set — D124 — and M1 prose). Stopping here; the unit is ready for verification.

disposed through dispatcher entry 3

