# Handoff record — m3-saves (M3S) — OPEN

- Story: M3S "Saves" (ledger D23, inputs D24)
- Branch: `m3-saves, base `0656eb1`
- Worktree: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-saves`
- Spec: `m3-saves-spec-M3S.md` · Prompt: `m3-saves-build-prompt.md` · Recon: `m3-saves-recon.md`
- Suggested session: `residuum-m3-saves, started by the user with:
  `cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-saves && claude -n residuum-m3-saves --bg`
- Build session: `residuum-m3-saves [51b7fd]` — kickoff pointer sent
  2026-08-21, delivered OK (msg ba7a5523).
- Baseline: 395 core + 95 content + 129 app = 619, measured fresh
  2026-08-21 at `0656eb1` by the architect. Exact survivability: 24/40.
- Scope addition flagged for user veto: the abandon-hero door (delete both
  save slots, roll a new world, guarded by a confirmation).
- Standing rules for this unit: core untouched (getters are pre-declared
  deviations); the suspend theorem in some end-to-end form is
  non-negotiable; cadence measured on device before it is chosen.

## Mid-flight Q&A

- 2026-08-21, worker pre-declaration (msg from [51b7fd]), architect reply
  sent same session:
  - THREE SPEC/RECON CLAIMS WRONG, all verified by the architect at the
    cited lines, all architect errors: (1) `FloorMap.toAscii()` already
    exists (recon said "no inverse" — head-limited read); (2)
    `baseItemById`/`affixById` already exist (recon grep used
    case-sensitive `byId` — unmatchable pattern, doctrine rule 2); worker
    adds OrNull variants beside them and pins affix-id uniqueness across
    pools; (3) the D24 "JSON doubles" hazard is FALSE on VM/AOT —
    dart:convert round-trips full-width ints exactly, so spec mutation
    row 6 was unfailable as written.
  - RULING: string encoding for wide fields KEPT, with the worker's strict
    decoder (a JSON number in a wide field is a structured failure) and the
    corrected justification (the document outlives the runtime; one meaning
    for every reader). Row 6 re-armed by strictness; worker's row 20
    (decoder-accepts-int) welcomed.
  - Spec cite error acknowledged (saves are design-spec section 11, not
    13). Design-spec supersessions (three manual slots; coarser autosave
    cadence) to be recorded as a ledger decision at story close.
  - All shape deviations approved as declared: sealed SaveRead single file;
    seven codec files; C1 clause-for-clause replacement by three boot
    tests; Autosaver owns profile+run (boot-resume argument); minimal
    abandon-hero with AVD-verified guard; hero normalization + verbatim hp
    with the over-ceiling note under "cannot prove".
  - No core getter needed — core diff will be empty.
- 2026-08-21, post-verification user finding → fix task sent to the worker
  (msg dadf3aac): system back pops the crawl route with no RunEnded — town
  desyncs from the on-disk suspended run, next entry overwrites it. Ruling:
  back is not an exit; PopScope canPop:false + bloc-evented log line "You
  can only leave at the stairs." AVD-verified (widget wiring = the boot
  blind spot). PR held until the delta returns.
- User Q&A: abandon-hero confirmed as the permanent New Game door (not
  testing-only); may be moved somewhere colder if it feels dangerous.
- 2026-08-21, back-guard delta returned and ACCEPTED (verified: 745 green,
  PopScope + SystemBackPressed + tests; rows 22/24 invisible = widget-
  wiring blind spot, escalated to the user). Judgment calls ratified:
  silent over death overlay; didPop guard.
- 2026-08-21, D28 task sent (msg 25a81823): document v1 goes multi-hero —
  {version, active, heroes: {id: {label, profile, run|null}}}; hero id from
  the clock site; label in the document not Profile; abandon = replace
  active slot; golden regenerated; two-hero tests + named mutation rows;
  roster UI explicitly NOT this unit (queued as m3-heroes with buy-back).
  PR waits on this delta.
- 2026-08-21, hash episode: the back-guard message cited docs commit
  `6c8fd0a`; the branch shows `a92bc79`. Asked per doctrine; worker owned
  it fully — the hash was FABRICATED (typed, never read; reflog shows no
  rewrite), the branch itself always correct. No breach (M2E/D9
  precedent: owned mismatch = correction). House method adopted:
  identifiers in reports are pasted from command output, never typed.
