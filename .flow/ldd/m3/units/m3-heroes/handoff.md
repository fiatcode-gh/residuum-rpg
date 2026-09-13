# Handoff record — m3-heroes (M3H) — OPEN

- Story: M3H "Heroes" (ledger D28, D31)
- Branch: `m3-heroes, base `f758c3f`
- Worktree: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-heroes`
- Spec: `m3-heroes-spec-M3H.md` · Prompt: `m3-heroes-build-prompt.md` · Recon: `m3-heroes-recon.md`
- Suggested session: `residuum-m3-heroes, started by the user with:
  `cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-heroes && claude -n residuum-m3-heroes --bg`
- Build session: `residuum-m3-heroes [af0b75]` — kickoff pointer sent
  2026-08-21, delivered OK (msg dc4c6016).
- Baseline: 395 core + 197 content + 176 app = 768, measured fresh
  2026-08-21 at `f758c3f` by the architect. Exact survivability: 24/40.
- Standing rules for this unit: core untouched; mutation rows 7–9 (the
  formerly invisible wiring mutations) MUST redden or their widget tests
  are wrong; the CLAUDE.md change is the D31 Testing amendment only; one
  more in-place v1 reshape is sanctioned (unshipped), golden regenerated
  in the same commit.

## Mid-flight Q&A

- 2026-08-21, worker pre-declaration (11 items), ALL APPROVED same
  session: `merchant` block name (spec correction — `visit` collided with
  Profile.visit); MerchantVisit value object with stillOnTheShelf;
  broughtUpToDate rename; SaveDocument.addingHero/playing/without —
  `without` returns nullable, making never-zero type-level;
  heroLabelFor(n); boot.dart createHero/switchHero/deleteHero/
  replaceOnlyHero; RosterScreen pops a sealed RosterChoice;
  Autosaver.document getter is the roster's read path; TownViewState
  gains carried-forward merchant + BuyBackPressed; merchant screen
  section order; roster says "in town" as a positive statement. No
  pubspec change at all (flutter_test already a dev dependency).
- Worker verified rows 7/8 reachable by reading Flutter 3.47.0 SDK source
  (handlePopRoute → maybePop → onPopInvokedWithResult mechanics, cited by
  file:line). It is also re-deriving the id-duplication mechanics at base
  through the real relaunch path rather than trusting the recon.
- TRAP RECURRENCE: two sessions named "[arch] residuum-rpg" again
  ([0958c2] live, [114a3e] stale) — worker duplicated its message to
  both; architect confirmed identity and asked the user to close the
  stale one.
