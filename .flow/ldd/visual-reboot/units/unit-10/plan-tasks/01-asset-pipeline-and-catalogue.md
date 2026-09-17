# Task 01 — Asset pipeline and typed catalogue

Owner: one fresh `flow-plan-executor` on the Unit 10 feature checkout. Read
`../PLAN.md` and `../CONTRACT.md` before editing. This is the unit's first task;
there is no prior worker transcript to inherit and none is needed.

## Expected starting repository condition

- A non-`main` checkout, by house convention `residuum-visual-reboot-10`,
  branched from `4bf865c` (the merged Unit 9 head on `main`).
- `packages/` is clean at that base. `packages/app/assets/` **does not exist**.
  `packages/app/pubspec.yaml:65-68` holds only a commented-out `assets:`
  example; `pubspec.yaml:63` is `uses-material-design: true`.
- The repository root has **no `.gitattributes`** and **no `tool/`**.
- `art/visual-reboot/` is untracked and holds 31 masters (all 1254x1254 8-bit
  sRGB PNG, 48.1 MB) plus `MANIFEST.txt`, `SHA256SUMS.txt` and
  `EXTRACT-NOTE.md`. **It is read-only input.** Never edit, move, delete,
  re-derive over or `git add -A` your way past it beyond the `.gitattributes`
  registration below.
- Architect-owned `.flow/**` records may be dirty or untracked. Preserve those
  bytes exactly: never stash, revert, commit or edit them.
- `magick` is ImageMagick 7.1.2-27 at `/usr/bin/magick`. `git lfs` is 3.7.1.

Inspect branch and worktree before editing. Implementation on `main` is
forbidden. If any named seam differs from `../PLAN.md`, stop and report rather
than adapting silently.

The monorepo has **no root pubspec**. Dart/Flutter commands run from
`packages/app`; the derivation script runs from the repository root.

## Behavioural slice

Give `packages/app` its first asset declaration: register the masters in Git
LFS, derive size-appropriate shipped assets from them by a recorded reproducible
command, declare those assets once, resolve every one of them through a single
typed catalogue, and own their decode and lifetime off every per-cell and
per-frame path. No widget or renderer consumes the catalogue yet — that is
tasks 02, 03 and 04.

Files:

- `.gitattributes` (new, repository root);
- `tool/derive-visual-assets.sh` (new, repository root, executable);
- `packages/app/assets/visual/environments/{stonebridge,forge,tavern}.jpg`
  (new, derived);
- `packages/app/assets/visual/dungeon/` — 18 new derived PNGs (6 material
  sheets, 12 overlays);
- `packages/app/assets/visual/icons/` — 8 new derived PNGs;
- `packages/app/pubspec.yaml` (three lines under a new `assets:` key);
- `packages/app/lib/art/art_assets.dart` (new);
- `packages/app/lib/art/dungeon_art.dart` (new);
- `packages/app/lib/main.dart` (one added import, one added line);
- `packages/app/test/art/art_catalogue_test.dart` (new).

Do not touch `packages/core`, `packages/content`, `pubspec.lock`, any
dependency, `.github/`, `art/visual-reboot/**` content, or any `lib/game/`,
`lib/town/`, `lib/world/` or `lib/save/` file.

## Locked implementation

`../PLAN.md` sections "Locked architecture and interfaces" 1-3 are the recipe.
Where this brief and the plan differ, the plan wins; where the plan and
`../CONTRACT.md` differ, stop and report.

### 1. Git LFS

Root `.gitattributes`, exactly one pattern line:

```gitattributes
art/visual-reboot/**/*.png filter=lfs diff=lfs merge=lfs -text
```

Nothing else goes in the file. `packages/app/assets/**` must never be matched:
derived assets stay ordinary git objects so a checkout without LFS still builds
a correct app, and CI (`.github/workflows/ci.yml:18`, `actions/checkout@v4` with
no `lfs:` input) is exactly such a checkout. `MANIFEST.txt`, `SHA256SUMS.txt`
and `EXTRACT-NOTE.md` must stay diffable text and are not matched.

Before relying on the filter, check `git config --get filter.lfs.clean`. If it
is empty, run `git lfs install --local`. **Never `--global`, never
`--system`.** Record in your receipt which of the two happened.

**Do not commit anything.** Staging and committing are Main's and the user's
integration step.

### 2. `tool/derive-visual-assets.sh`

Bash, `#!/usr/bin/env bash`, `set -euo pipefail`, executable, run from the
repository root, idempotent, prints every path it writes. Fail with a clear
message if `magick` is absent or if `art/visual-reboot/` is missing. Create the
three output directories if needed. Internal shape (loops, arrays, functions)
is yours; **the per-class commands and every one of their parameters are not.**

Environments — one command per file, `+0+251` for Stonebridge and `+0+439` for
the other two:

```sh
magick art/visual-reboot/environments/ENV-001_stonebridge.png \
  -crop 1254x502+0+251 +repage -resize 1080x432! \
  -quality 82 -sampling-factor 4:2:0 -strip \
  packages/app/assets/visual/environments/stonebridge.jpg

magick art/visual-reboot/environments/ENV-002_forge.png \
  -crop 1254x502+0+439 +repage -resize 1080x432! \
  -quality 82 -sampling-factor 4:2:0 -strip \
  packages/app/assets/visual/environments/forge.jpg

magick art/visual-reboot/environments/ENV-003_tavern.png \
  -crop 1254x502+0+439 +repage -resize 1080x432! \
  -quality 82 -sampling-factor 4:2:0 -strip \
  packages/app/assets/visual/environments/tavern.jpg
```

Material sheets — six files:

```sh
magick <master> -colorspace Gray -resize 576x576! \
  \( +clone -blur 0x24 \) \
  -compose Mathematics -define compose:args='0,-1,1,0.5' -composite \
  -function polynomial "1.6,-0.3" -depth 8 -strip \
  packages/app/assets/visual/dungeon/<out>.png
```

| Master | Shipped |
| --- | --- |
| `dungeon/crypt/DNG-001_crypt_floor_base.png` | `dungeon/crypt_floor.png` |
| `dungeon/crypt/DNG-002_crypt_wall_base.png` | `dungeon/crypt_wall.png` |
| `dungeon/sea_cave/DNG-SC-001_sea_cave_floor_material_source.png` | `dungeon/sea_cave_floor.png` |
| `dungeon/sea_cave/DNG-SC-002_sea_cave_wall_material_source.png` | `dungeon/sea_cave_wall.png` |
| `dungeon/ruined_keep/DNG-RK-001_ruined_keep_floor_material_source.png` | `dungeon/ruined_keep_floor.png` |
| `dungeon/ruined_keep/DNG-RK-002_ruined_keep_wall_material_source.png` | `dungeon/ruined_keep_wall.png` |

The `Mathematics` composite computes `source - blurred + 0.5`, which strips every
low-frequency component (any baked lighting included) and re-centres the sheet on
mid-grey. **Mid-grey is the identity element of `BlendMode.softLight`, which
task 03 draws these with**, so the centring is the mechanism that makes "no
baked lighting double-exposure" true. Verify each output with

```sh
magick <out>.png -format "%[fx:mean] %[fx:standard_deviation]\n" info:
```

and expect a mean in `0.48..0.52`. The planner measured 0.5054 (crypt floor)
and 0.4991 (sea-cave floor). A mean outside that window is an escalation, not
something to correct by eye.

Overlays — twelve files, greyscale with alpha preserved:

```sh
magick <master> -colorspace Gray -resize 144x144 -strip \
  packages/app/assets/visual/dungeon/<out>.png
```

| Master suffix | Shipped |
| --- | --- |
| `crypt/DNG-003_crypt_crack_overlay_a` | `dungeon/crypt_crack_a.png` |
| `crypt/DNG-004_crypt_crack_overlay_b` | `dungeon/crypt_crack_b.png` |
| `crypt/DNG-005_crypt_rubble_small` | `dungeon/crypt_rubble_small.png` |
| `crypt/DNG-006_crypt_rubble_medium` | `dungeon/crypt_rubble_medium.png` |
| `sea_cave/DNG-SC-003_sea_cave_crack_overlay_a` | `dungeon/sea_cave_crack_a.png` |
| `sea_cave/DNG-SC-004_sea_cave_crack_overlay_b` | `dungeon/sea_cave_crack_b.png` |
| `sea_cave/DNG-SC-005_sea_cave_rubble_small` | `dungeon/sea_cave_rubble_small.png` |
| `sea_cave/DNG-SC-006_sea_cave_rubble_medium` | `dungeon/sea_cave_rubble_medium.png` |
| `ruined_keep/DNG-RK-003_ruined_keep_fracture_overlay_a` | `dungeon/ruined_keep_crack_a.png` |
| `ruined_keep/DNG-RK-004_ruined_keep_fracture_overlay_b` | `dungeon/ruined_keep_crack_b.png` |
| `ruined_keep/DNG-RK-005_ruined_keep_rubble_small` | `dungeon/ruined_keep_rubble_small.png` |
| `ruined_keep/DNG-RK-006_ruined_keep_rubble_medium` | `dungeon/ruined_keep_rubble_medium.png` |

Ruined Keep's masters are named `fracture_overlay_a/b` and ship as
`ruined_keep_crack_a/b.png`: the recon recorded the same role under two naming
generations, and `crack` is the ubiquitous word because `MaterialMark.crack` is
the gate that selects them. Do not rename the gate to match the file.

Icons — eight files, full colour with alpha:

```sh
magick <master> -background none -resize 72x72 -strip \
  packages/app/assets/visual/icons/<out>.png
```

`UI-P0-001_potion` -> `potion.png`, `002_pack` -> `pack.png`,
`003_wait` -> `wait.png`, `004_ascend` -> `ascend.png`,
`005_descend` -> `descend.png`, `007_firebolt` -> `firebolt.png`,
`008_mend` -> `mend.png`, `009_more` -> `more.png`.

**`UI-P0-006_melee` and `UI-P0-010_back` are not derived and not shipped.** The
contract's non-goals forbid a melee button and a custom back icon; an asset
existing is not scope. The script must not mention them.

Expected totals, measured by the planner: environments 91/119/117 KB, sheets
255-288 KB each, overlays 2-30 KB each, icons 1.9-8.2 KB each, ~2.3 MB overall.

### 3. `packages/app/lib/art/art_assets.dart`

The only file in the repository that may contain an asset path string. Four
enums plus one private root constant, exactly as `../PLAN.md` section 2
specifies:

- `EnvironmentArt { stonebridge, forge, tavern }` with `String get path`;
- `ActionIcon { potion, pack, wait, ascend, descend, more, firebolt, mend }`
  with `String get path` and
  `static ActionIcon? forSpell(String spellId)` returning `firebolt` for
  `'firebolt'`, `mend` for `'mend'`, and null for everything else;
- `MaterialSurface { floor, wall }`;
- `MaterialArt` with six values carrying `RegionMaterial region`,
  `MaterialSurface surface` and `path`, plus
  `static MaterialArt? of(RegionMaterial, MaterialSurface)`;
- `OverlayKind { crackA, crackB, rubbleSmall, rubbleMedium }`;
- `TerrainOverlayArt` with twelve values carrying `RegionMaterial region`,
  `OverlayKind kind` and `path`, plus
  `static TerrainOverlayArt? of(RegionMaterial, OverlayKind)`.

Locked consequences a reviewer will check:

- **`RegionMaterial.lowlandRoad` has no value in `MaterialArt` or
  `TerrainOverlayArt`**, and both `of` lookups return null for it. Criterion 9
  is structural; do not add a road entry, a road fallback or a "reserved" value.
- **`ActionIcon.values.length == 8`**, with no `melee` and no `back`.
- The file imports `../game/dungeon_palette.dart` for `RegionMaterial` and
  nothing from Flutter beyond what the enums need (ideally nothing at all).
- No other file in `packages/app` may contain the substring `assets/visual`.

### 4. `packages/app/lib/art/dungeon_art.dart`

```dart
class DungeonArt {
  const DungeonArt({required this.surfaces, required this.overlays});
  const DungeonArt.none() : surfaces = const {}, overlays = const {};

  final Map<MaterialArt, ui.Image> surfaces;
  final Map<TerrainOverlayArt, ui.Image> overlays;

  ui.Image? surfaceFor(RegionMaterial region, MaterialSurface surface);
  ui.Image? overlayFor(RegionMaterial region, OverlayKind kind);
}

/// The decoded dungeon art this process loaded at launch, or none.
DungeonArt get dungeonArt => _loaded;

/// Decodes every shipped dungeon image and precaches the three illustrations,
/// once per process.
Future<void> warmUpArt() async { ... }
```

Binding details:

- `surfaceFor`/`overlayFor` go through `MaterialArt.of`/`TerrainOverlayArt.of`
  and return null when the region has no art or the entry failed to load.
- `warmUpArt()` **never throws.** Each asset is loaded inside its own
  try/catch; a failure leaves that entry absent. It is idempotent: a second
  call returns without redecoding.
- Decode with `rootBundle.load(path)` ->
  `ui.instantiateImageCodec(bytes)` -> `codec.getNextFrame()`. Do not use
  Flame's `Images` cache — it would impose Flame's own asset prefix on the
  declaration this unit owns.
- Illustrations are precached with
  `const AssetImage(path).resolve(ImageConfiguration.empty)` awaited to its
  first frame via a `Completer` and an `ImageStreamListener` you remove. No
  `BuildContext` is available or needed. Wrap each in its own try/catch.
- **The eight icons are not precached.** A 72x72 image decodes in well under a
  millisecond; eight more boot decodes buy nothing observable.
- **Images are never disposed.** They live for the process, exactly as
  `ImageCache` entries do.
- `_loaded` starts as `const DungeonArt.none()`. There is **no test-only
  constructor, no setter and no injection seam**: tests build a `DungeonArt`
  with the public constructor from images they decode themselves, and `main()`
  is never run by the suite so `dungeonArt` stays `none()` there.

### 5. `packages/app/pubspec.yaml`

Replace the commented-out example at `:65-68` with a live declaration under the
existing `flutter:` key, directly after `uses-material-design: true`:

```yaml
  assets:
    - assets/visual/environments/
    - assets/visual/dungeon/
    - assets/visual/icons/
```

Directories, not files: three lines that never drift instead of 29 that do. The
hole this opens — a stray file shipping silently — is closed by test 3 below.
Do not add a `fonts:` section, do not touch `dependencies`, do not touch
`pubspec.lock`.

### 6. `packages/app/lib/main.dart`

Add `import 'art/dungeon_art.dart';` in the existing import order, and one line
to `main()`:

```dart
Future<void> main() async {
  final store = SaveStore(IoSaveFiles());
  await warmUpArt();
  runApp(await guardedBoot(store, rollWorldSeed: rollWorldSeedFromClock));
}
```

**Outside `guardedBoot`, before `runApp`.** Outside, so a missing asset can
never open the boot failure screen or change its sentence. Before `runApp`, so
no screen's first frame pays for a decode — which is the only way to guarantee
criterion 17's no-hitch requirement. Nothing else in `main.dart` changes: not
`guardedBoot`, not `BootFailureScreen`, not the theme, not `_Session`.

## Red/Green proof

Establish Red before the production files exist: write
`test/art/art_catalogue_test.dart` against the interface above first and watch
it fail to compile on the missing `art_assets.dart`, then fail on missing files
until `tool/derive-visual-assets.sh` has run.

### New focused suite — `packages/app/test/art/art_catalogue_test.dart`

Pure Dart tests (`package:test`-style `test()` under `flutter_test`), using
`dart:io` for file facts. Bodies structured `// arrange` / `// act` /
`// assert`. Paths resolve relative to `packages/app`, which is
`flutter test`'s working directory.

1. **every catalogue entry names a file that exists** — for every value of
   `EnvironmentArt`, `ActionIcon`, `MaterialArt` and `TerrainOverlayArt`,
   `File(entry.path).existsSync()` is true.
2. **every catalogue path is declared once** — parse the `assets:` list out of
   `pubspec.yaml` (read the file, take the lines under `assets:` that start
   with `- `); assert every catalogue path begins with one of the declared
   directories, and that the 29 paths are all distinct.
3. **the shipped directories carry exactly the catalogue** — for each of the
   three declared directories, the set of file paths found on disk equals the
   set of catalogue paths under that directory. No stray file, no missing file.
   This is the test that makes a directory-level declaration safe.
4. **masters are not shipped** — no shipped file is 1254 bytes-wide in either
   dimension (decode each with `instantiateImageCodec` and assert
   `width != 1254 || height != 1254`, and specifically that environments are
   1080x432, sheets 576x576, overlays 144x144 and icons 72x72); the summed
   shipped byte count is under 8 MB; no catalogue path contains `DNG-` or
   `UI-P0-`.
5. **no icon exists for melee or back** — `ActionIcon.values` has length 8 and
   no value whose name is `melee` or `back`.
6. **`forSpell` matches exactly and only firebolt and mend** —
   `ActionIcon.forSpell('firebolt') == ActionIcon.firebolt`,
   `forSpell('mend') == ActionIcon.mend`, and null for `'frost-lance'`,
   `'ward'`, `'bind'`, `'banish'` and `'not-a-spell'`.
7. **the road has no authored material** — `MaterialArt.of` and
   `TerrainOverlayArt.of` return null for `RegionMaterial.lowlandRoad` across
   every surface and kind, and return a non-null entry for all six
   `(region, surface)` and all twelve `(region, kind)` combinations of the other
   three regions.
8. **an unloaded process has no art** — `dungeonArt.surfaceFor(...)` and
   `overlayFor(...)` return null for every region and kind, and
   `const DungeonArt.none().surfaces` is empty. This is the procedural-fallback
   guarantee every other suite depends on; a plausible bug is a warm-up that
   runs from a static initializer.

Do not assert source text, file byte sizes individually, or JPEG/PNG internals
beyond dimensions. No golden images (`AGENTS.md`).

### Pipeline proof, run and pasted into your receipt

```sh
# from the repository root
bash tool/derive-visual-assets.sh
bash tool/derive-visual-assets.sh   # idempotent: second run changes nothing
git status --porcelain packages/app/assets | wc -l   # unchanged between runs

git check-attr filter -- art/visual-reboot/environments/ENV-001_stonebridge.png
# expect: filter: lfs
git check-attr filter -- packages/app/assets/visual/environments/stonebridge.jpg
# expect: filter: unspecified

for f in packages/app/assets/visual/dungeon/*_floor.png \
         packages/app/assets/visual/dungeon/*_wall.png; do
  magick "$f" -format "$f %[fx:mean]\n" info:
done
# expect every mean in 0.48..0.52
```

## Proof commands

From `packages/app`, after Red and after Green:

```sh
flutter test test/art/art_catalogue_test.dart

dart format --set-exit-if-changed --output=none \
  lib/art/art_assets.dart lib/art/dungeon_art.dart lib/main.dart \
  test/art/art_catalogue_test.dart

flutter analyze
flutter test
```

`flutter analyze` and the final full `flutter test` are in scope: you are the
only writer at this point in the sequence, and a `pubspec.yaml` asset
declaration changes the test asset bundle for every suite in the package. Main
re-runs the same gate afterwards; that is acceptance, not duplication. Do not
run an app build, an emulator, a device install, a `git commit`, a `git push`,
or any external write.

## Executor discretion

Yours: the internal shape of `tool/derive-visual-assets.sh` (arrays, loops,
helper functions, logging format) provided the recorded per-class commands and
every parameter are the ones executed; private helper names in
`dungeon_art.dart`; how the pubspec `assets:` list is parsed in test 2 (a small
hand-rolled reader is fine — do not add a YAML dependency); test helper names;
import ordering; whether new app-side declarations carry dartdoc.

Not yours: the LFS pattern or anything it excludes; `git lfs install --local`
versus global; the shipped asset root, directory names, file names, formats,
dimensions, quality, crop offsets, blur radius, `compose:args` or polynomial;
which masters are derived and which are deliberately not; the `assets:`
declaration shape; any enum's values, names, order or paths; `forSpell`'s
mapping; `DungeonArt`'s public shape, its `none()` const, its never-throw rule,
its no-dispose lifetime, or the decision not to precache icons; the `warmUpArt`
call site or its position relative to `guardedBoot` and `runApp`; any verdict in
the test list above.

## Escalate when

- a master's bytes differ from `art/visual-reboot/SHA256SUMS.txt`, or a master
  is missing;
- `magick` is absent, or a derivation command errors, or a material sheet's
  measured mean falls outside `0.48..0.52`;
- `git lfs` filters cannot be configured repository-locally, or `git check-attr`
  reports LFS on a shipped asset, or reports no LFS on a master;
- declaring assets in `pubspec.yaml` makes any existing suite fail — that is a
  test-bundle interaction the plan did not predict and must not be worked
  around by narrowing the declaration;
- `rootBundle` cannot load a declared asset in the widget harness;
- the catalogue cannot express a mapping without a road entry, a placeholder
  value, or a `melee`/`back` value;
- an existing test fails for a preserved behaviour rather than an obsolete
  assumption;
- a fix would require `packages/core`, `packages/content`, `pubspec.lock`, a
  dependency, a `.github/` change, a `git commit`, or implementation on `main`.

Report; do not redesign the contract.

## Handoff state and completion receipt

The task is complete when: `.gitattributes` holds exactly the one LFS pattern;
`tool/derive-visual-assets.sh` is executable, idempotent and reproduces the
shipped assets byte-for-byte on a second run; 29 derived assets exist under
`packages/app/assets/visual/` at the locked dimensions; `pubspec.yaml` declares
the three directories; `art_assets.dart` and `dungeon_art.dart` exist with
exactly the locked surfaces; `main.dart` carries one new call; the eight focused
tests are green; `flutter analyze` is clean; the full `flutter test` passes with
no suite regressed; formatting is clean on touched files; and nothing outside
the named files changed.

Report to Main in at most eight prose lines:

- branch and base revision, and the Red you observed before the pipeline ran;
- whether `git lfs install --local` was needed, and both `git check-attr`
  results verbatim;
- the six material-sheet means, and the shipped byte total;
- confirmation that `melee` and `back` are neither derived nor in the catalogue,
  and that `assets/visual` appears in only three files;
- the results of the four proof commands and the idempotence check;
- the test count before and after;
- anything a device pass must settle (launch cost of the boot-time warm-up);
- any escalation left open for Main's acceptance review.
