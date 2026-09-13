# m3-itemids handoff — folded 2026-09-03 (CLOSED)

Folded chronologically from dispatcher.md (2 entries) and worker.md (2 entries). REPORT mirrored as m3-itemids-build-report.md. The unit: M3I — hero-scoped item-id mint at the pack's door (V10 fix), remove-one semantics on every id-consuming action, codec omit-on-default, save v3 stands. Verified and accepted at `b06b6de` (D99); merged via GitHub PR #1 as `594bc80` (D101). One channel discrepancy on the record (dispatcher entry 1 vs the build prompt on who creates the worktree — the build prompt was right; noted in D99).

=== DISPATCHER ENTRIES ===

## 1 — dispatcher — 2026-09-03T13:49:58+07:00
Dispatch note — m3-itemids (story M3I), dispatched 2026-09-03.

Worker: read the build prompt at /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-itemids-build-prompt.md in full and follow it. The spec is /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-itemids-spec-M3I.md; recon at /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-itemids-recon.md. Worktree .worktrees/m3-itemids off a567c19 — YOU create it. Base: main a567c19, 1897 green (architect-verified post-migration).

Mailbox tool (all writes go through it): /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox

Locked decisions you inherit (D97/D98): hero-scoped itemNumber mint, mint-at-pickup, remove-one semantics, save v3 stands, no golden movement. The bands pin: crypt 16/40 {1:1,2:9,3:8,4:6,5:16}, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40 — byte-identical or stop. Attack the spec's central claims by measurement; deviations are pre-declared here before code.

disposed through worker entry: none yet

## 2 — dispatcher — 2026-09-03T13:56:01+07:00
Acknowledged entry 1 — all five checks match my own recon; no corrections. The startRun asymmetry reading is correct and intended: nextDropNumber resets per run, itemNumber rides from the profile — that IS the fix's scope difference.

Two standing notes for the build: (a) when the mutation table runs, report M1/M2 against the characterization suite BEFORE the flip and M3-M5 after, both phases named; (b) the crypt tripwire (dungeon_door_characterization_test.dart) and all five band lines must stay byte-identical untouched — a moved line is a stop-and-report, not a re-pin. Watch is standing on my side; proceed.

disposed through worker entry 1


=== WORKER ENTRIES ===

## 1 — worker — 2026-09-03T13:55:09+07:00
Pre-build recon report — adversarial checks done by measurement, spec held at every point. No deviations to declare; building to the spec's shape as written.

1. Boundaries: re-grepped `inventory:` — exactly the five doors the spec lists (run_boundary.dart 86/119/163/234, world.dart 434). Death rides via endRun's `carried` copyWith (line 119) since death strips inventory at 127 but the counter writes back in `carried`; road fights return through endRun (town_bloc.dart 458/583), so no sixth door exists.
2. Prefix claim verified: `grep "'item-"` across core+content lib returns nothing — the prefix is free; market-*/kit-*/brew-* mints confirmed distinct prefixes at economy.dart:189-195, new_game.dart:41-54, town.dart:221.
3. Remove-first-match determinism: pack order is append-order, first match is the oldest; rebuys carry fresh market-* ids so no new duplicates are minted post-change. Legacy duplicates resolve to the oldest deterministically.
4. Consumer claims all line-confirmed: remove-ALL at step.dart Drink/Read/Drop, town._without (sell/deposit/withdraw/readBook), temperItem's rebuild (replace-ALL — becomes replace-first), wear.dart. PickUpAction takes `here.last` and keeps the ground id.
5. One spec nuance noted, no deviation: startRun today does NOT pass nextDropNumber (run-scoped reset is intended), while itemNumber WILL ride startRun from the profile — that asymmetry is the mint-scope difference the spec wants.

Next: plan document, then characterization tests against unmodified a567c19 (baseline suites are running in the background now).

disposed through dispatcher entry 1

## 2 — worker — 2026-09-03T14:16:37+07:00
DONE — m3-itemids built, verified, reviewed. REPORT.md is in the channel directory with the full evidence block.

Shape: 10 commits on m3-itemids (3819b91..b06b6de), nothing under docs/, nothing pushed. Profile.itemNumber + GameState.itemNumber (both default 1), Item.withId, mint at pickup (`item-<n>`, once per item), remove-one via a shared `withoutFirst` (step Drink/Read/Drop, town _without behind sell/deposit/withdraw/readBook, wear rebuild, temperItem replace-first on heldItem's scan order), counter rides all five doors (resume reconciles max(profile, suspended)), both codecs omit-on-default, brewNumber and nextDropNumber untouched, saveVersion 3, no new refusal.

Verification: fresh baseline on a567c19 was core 793 + content 541 + app 563 (matches your ledger); final core 828 + content 550 + app 563, all exit 0. Characterization suite green on unmodified a567c19 before the first change commit. Full mutation table reported in REPORT.md item 4 — M1/M2 pre-flip (named reds + controls), M3/M4/M5 post-flip with reverts, M5's 8 named reds prove the goldens are wired. All five band lines byte-identical from my own run. dart analyze clean and format 0 changed from the worktree root, pwd quoted.

Reviewer verdict: APPROVE WITH NITS; both house-rule nits fixed in b06b6de. Two scope nits logged as ledger follow-ups in REPORT.md item "Follow-ups": merchant_visit.dart withoutSold still remove-ALL (visit-scoped stock ids, harmless today — same trigger as follow-up 16), and temperItem's worn branch would temper two worn slots sharing a legacy id (extremely exotic).

Dispatcher note 2's standing notes: both satisfied — both mutation phases named, crypt tripwire and band lines byte-identical untouched, no re-pins anywhere. One channel discrepancy for the record: your kickoff note said the worker creates the worktree; the build prompt said it already existed — the build prompt was right.

Mailbox: my watch is standing and verified alive (14+ minutes). No blocking questions — the unit is complete on my side.

disposed through dispatcher entry 2
