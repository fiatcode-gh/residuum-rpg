# Unit 10 — device-evidence recovery checkpoint

Written 2026-09-16, **before any device, emulator, ADB, install or screenshot
action**. Nothing device-side has happened in this controller session.

## Exact tree

- Branch **`residuum-visual-reboot-10`**, HEAD `4bf865c` (the merged Unit 9
  head). **No commit exists on this branch** and no remote branch exists. No
  push or pull request is authorized.
- Modified, all Unit 10 implementation: `packages/app/lib/main.dart`,
  `packages/app/pubspec.yaml`, `packages/app/lib/town/{town_screen.dart,
  forge_screen.dart,tavern_screen.dart}`, `packages/app/lib/game/
  {game_screen.dart,dungeon_material.dart,dungeon_scene_material.dart,
  dungeon_scene.dart}`.
- **Untracked and load-bearing — a `git clean` destroys the unit:**
  `.gitattributes`, `tool/derive-visual-assets.sh`,
  `packages/app/assets/visual/` (29 derived assets, 2.15 MB),
  `packages/app/lib/art/{art_assets.dart,dungeon_art.dart}`,
  `packages/app/lib/town/illustration.dart`,
  `packages/app/lib/game/action_icon.dart`, and six new test files under
  `packages/app/test/{art,game,widget}/`.
- **Untracked and irreplaceable:** `art/visual-reboot/` — 31 approved authored
  masters, 48.1 MB, verified byte-identical to `SHA256SUMS.txt`. The repository
  cannot regenerate these.
- Architect-owned: `.flow/ldd/visual-reboot/LEDGER.md`, `RESUME.md`,
  `units/unit-10/`.
- `packages/core` and `packages/content` have **zero** changes.

## Fresh evidence already accepted (do not re-earn)

Architect-run from `packages/app` at this exact tree:

- `dart format --set-exit-if-changed --output=none lib test` — 112 files, 0 changed
- `flutter analyze` — no issues
- full `flutter test` — **870 passing** (834 at Unit 9's close, plus the unit's
  35 planned tests and one activation test from the correction round)

`agent://U10Acceptance` reviewed the whole unit read-only: **no Critical
finding**, all 18 criteria satisfied, the four safety invariants verified
structural at source, base-tracked tests byte-unchanged. Its three Important
findings were verification-side and closed by `agent://U10Corrections`; the
architect confirmed at source that that worker's temporary falsifiability probes
were reverted (`dungeon_scene_material.dart:545` reads
`crackGate && overlayImage == null`; `_texturePhase` derives both axes from
`palette.themeSalt`). `agent://U10Closure` holds the remaining scoped review.

## Device state

`Medium_Phone` (Android 17) is **not started**. It must be user-started: a
tool-shell launch segfaults. Nothing is installed.

## Standing obligation, every capsule

Copy **both** save slots aside before any install — read
`app_flutter/save.json` and `app_flutter/save-previous.json`, never
`files/save.json` — and prove SHA-256 restoration byte-identical afterward under
one consistent comparison scheme. The known baseline hashes from Unit 8/9 are
`save.json` `18995c…2b46d3` and `save-previous.json` `8909f7…f8a9b11`; re-read
rather than assuming them. A first delve bumps `visit` to 1, so scenes must be
probed at `visit: 1`, never `visit: 0`.

## Remaining acceptance criteria

Criteria 16 and 17, in five bounded capsules, each its own fresh
`flow-evidence-verifier` session with a colour and greyscale twin per frame:

- **A — towns and rooms.** Stonebridge with its illustration; Northgate with
  none and nothing substituting; Forge and Tavern in both towns. Judge whether
  140 dp / 120 dp bands and the 2.5:1 crops read as atmosphere, and that no
  title, status, price, refusal sentence, control or door is displaced or
  unreachable.
- **B — one Crypt delve plus cold-boot cost.** Authored material, remembered
  versus visible, unknown unpainted, no hidden-geometry leak, no scene-entry or
  crawl-render hitch. **Time cold boot against `4bf865c`**: warm-up decodes 18
  images and precaches 3 JPEGs before `runApp`, now batched through
  `Future.wait`, and that cost has never been measured.
- **C — Sea-Cave and Ruined Keep cue survival.** Do the accepted tide strata,
  ashlar fracture, wall edges and runtime light still read under authored
  texture, in colour and greyscale? Overlay density and the eight-cell mirror
  period are judged here. Bounded correction is the softLight amplitude via
  re-derivation or `overlayOpacity` within 0.35-0.75. **Reducing an accepted
  regional cue is an escalation, not a cleanup.**
- **D — lowland road.** Procedural fallback visually unchanged against
  `4bf865c`.
- **E — control row and shelf.** Both worst-density five-control scenes
  including the bottom-floor underfoot case, disabled `Drink`, the shelf with
  every icon-bearing action, and the open `+N` overflow sheet. **No ellipsis
  anywhere**; every word and count complete; icons legible by shape in
  greyscale. Measure the crawl viewport height against `4bf865c`: two runs cost
  ~44 dp and that is the user-approved D2 trade, to be quantified rather than
  re-litigated.

## Next action

Wait for `agent://U10Closure`, then ask the user to start `Medium_Phone`, then
dispatch capsule A. Each capsule carries its own `Evidence capsule:` manifest.
