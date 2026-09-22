# Unit 14 Gate C — the device pass, dispatch plan

Written by the architect at `68d0d96`, before any device action, alongside
`.flow/checkpoints/68d0d96.md`. The thirteen capsules are defined in
`PLAN.md` section "Gate C — the device pass"; this file is how they are
dispatched and what each session is told.

**The device is exclusive, so every session is sequential.** One
`flow-evidence-verifier` per session, fresh each time, never two at once.
Main inspects each receipt and the consequential artifacts, and owns the
acceptance decision. Main does not drive the device sequence itself.

## Shared facts every session is given

- Repository `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg`,
  branch `residuum-visual-reboot-13`, head **`68d0d96`**. Every capsule cites
  `68d0d96`; `8ab8d09` is superseded.
- Device: user-started `Medium_Phone`, expected `emulator-5554`,
  1080x2400 at density 420 — **411.4 x 914.3 dp, 2.625 device pixels per dp**.
  Verify the serial and the density at the start of each session rather than
  assuming; `adb shell wm size` and `adb shell wm density`.
- Evidence destination: `.flow/evidence/68d0d96/<capsule-id>/`, absolute path
  given per session. That subtree is untracked by repository convention
  (`.git/info/exclude` carries `.flow/evidence/`).
- **Every frame is captured in colour and as a greyscale twin.** The twin is
  a `-colorspace Gray` conversion of its own colour frame and nothing else;
  Main verifies that correspondence.
- **This workstation's ImageMagick returns an anomalous `compare -metric AE`**
  on some content, about nineteen times the pixel count, while correct on
  identical inputs. Count differing pixels with a difference/threshold/mean
  route, never bare `-metric AE`.
- The verifier may operate the emulator and capture evidence. It **may not**
  edit production behaviour, and it does not declare the unit accepted.

## Stop-and-escalate, in every brief

- any glyph rendering as tofu;
- any clipped or ellipsised label in the route diagram or a value row;
- **worst legal combat above 600 dp on device**;
- in capsule J, the `BattleDock` covered by the map — that reopens U13.1.

None of these is an executor's call and none is a tuning target. Report the
measurement and the scene; do not adjust a constant to make it pass.

## Session order

| # | session | owns | restore obligation |
|---|---|---|---|
| 0 | `u14-setup` | back up both save slots with SHA-256, build the debug APK at `68d0d96`, install | NONE — it creates the backups the closing session restores from |
| 1 | `u14-A-town` | capsule A | NONE — the closing session restores |
| 2 | `u14-B-character` | capsule B | NONE |
| 3 | `u14-C-pack` | capsule C | NONE |
| 4 | `u14-D-forge` | capsule D | NONE |
| 5 | `u14-E-tavern` | capsule E | NONE |
| 6 | `u14-F-rooms-and-roster` | capsule F | NONE |
| 7 | `u14-G-world-map` | capsule G | NONE |
| 8 | `u14-H-exploration` | capsule H | NONE |
| 9 | `u14-I-combat-typical` | capsule I | NONE |
| 10 | `u14-J-ceiling` | capsule J | NONE |
| 11 | `u14-K-log` | capsule K | NONE |
| 12 | `u14-L-overlays` | capsule L | NONE |
| 13 | `u14-M-dungeon-glyphs` | capsule M | NONE |
| 14 | `u14-restore` | restore both slots from session 0's backups and verify byte identity | **YES — both slots, from the backups, never from the device** |

Restoration is deliberately **not** split across capsules. The app's own
rotation moves current to previous during play, so restoring mid-pass would
destroy the staged state the next capsule needs. One closing session owns it,
exactly as Unit 12.5 did at its pause points.

If the user pauses part-way, the closing restore session runs **then**, and a
fresh setup session re-backs-up before the pass resumes.

## The manifest each session carries

Inside that session's own brief, not only in shared context:

```text
Evidence capsule:
- ID: u14-<letter>-<slug>
- Owns: <the one scene family from PLAN.md's capsule table>
- Independent split check: none
- Excludes: every other capsule in this table, each left to a fresh session
- Restore obligation: NONE | both save slots, from the setup session's backups
```

## Session 0 — setup, in exact order

1. `adb devices -l`; confirm the `Medium_Phone` serial and record it.
2. **Back up both slots before anything else.** The live path is
   `app_flutter/save.json` — **not** `files/app_flutter/save.json`, a trap
   already on record — and the second slot is `app_flutter/save-previous.json`.
   Pull both, record **SHA-256** for each, and write the hashes into the
   receipt and beside the backups.
3. Build the debug APK from `packages/app` at `68d0d96` and install it.
4. Confirm the installed build is the one just built, and record how.

A session that cannot read a slot **stops and reports**. It does not install
over an unbacked-up save.

## What each scene capsule records

Per `PLAN.md`: whether any label ellipsised or clipped; whether any of F3's
twelve marks rendered as tofu; which weight the display face resolved to; and
for **H, I and J**, the measured device chrome against Gate A's widget-test
figures.

**Gate A, for comparison:** exploration worst **331.0 dp**, combat typical
**429.0 dp**, combat worst legal **578.0 dp**. Expected agreement within
2 dp. A wider divergence is the first thing the receipt must explain, and the
likeliest cause is F3 — `✳ ✚ ⛒` are absent from Spectral and sit inside chip
labels `_fitFor` measures, so their advance is host-dependent.

Measure chrome as Unit 12.5 did: from the capture, the map's own box against
the surface height, converted at 2.625 device pixels per dp. State the pixel
figures as well as the dp, so the arithmetic is checkable.

Compare A–M against the ten mock frames on type register, hierarchy, contrast
and control clarity. **The mock is directional, not a pixel target.**

## What the three special capsules carry

- **J** — the eleven-chip worst legal combat, and **U13.1's hardware
  confirmation**. U13.1's fix is proved headlessly and on no real screen
  until this capsule passes. If the `BattleDock` is covered, U13.1 reopens.
- **F** — the roster's **first visual baseline** in this epic. There is no
  prior frame to compare against; judge internal consistency and record the
  baseline for U15 and U17 to re-shoot.
- **G** — the world map's **first visual baseline**, plus F8's clip risk:
  every node discovered with a journey in progress, which is the state that
  renders `TRAVEL IN PROGRESS` in a 120 dp box. The widget test measured
  98.79 dp there; the device is the real test of it.

## After the pass

Main folds the results into the ledger: the device dp figures at all three
densities beside Gate A's, the list of rewritten tests and what each defends
(AC9), the weight budget (AC1), A2's twelve fallback marks, and A3's widened
boundary. Then `flow-integrating` for the user's integration choice.

At most **one** constants-only tuning pass is allowed inside the dp gate's
envelopes. If it happens, it reopens the barrier: rerun every focused and
package proof those constants traverse, plus Gate A and a scoped acceptance
review, and recapture the affected capsules.

Nothing remote is authorized. Push, pull request and merge are each their own
gate.
