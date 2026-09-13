# Resume M3

- M3 is closed except `m3-quests` (M3Q, save v4) — locked into the old wave
  (D98), never dispatched. The active epic is `../visual-reboot/`; it owns
  what happens to M3Q.
- Current accepted state: `main` = `85e8bcc` (m3-town-ux, GitHub PR #10),
  CI-enforced, 20 units merged (table in `LEDGER.md`).
- Locked decisions that still bind: save v3 with per-unit sanctioned breaks
  (D59); the five band lines as byte-identical controls (carried forward —
  re-verify before relying); widget-driven UI units with the AVD pass as
  final gate (D113); never rename CI job/check names (D121).
- Traps that burn the next session: no root pubspec (suites per package
  dir); copy BOTH device save slots aside before any install; phone build
  is not debuggable (adb screenshots only); squash merges are invisible to
  merge-base (`git diff <head> origin/main` is the check).
- Full D-number history: `../legacy/LEDGER.md` (D1–D126).
- Untracked evidence (audit report, shots, device saves):
  `../evidence/` (gitignored; cite by absolute path).