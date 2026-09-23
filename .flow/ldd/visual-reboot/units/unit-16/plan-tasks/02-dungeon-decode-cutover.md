# 02 — Stop unused dungeon image decoding

Start: Task 01's focused Green receipt and buildable ASCII scene on the same suitable feature checkout; approved `../CONTRACT.md`, `../PLAN.md`, four named references. Base source `374ee775e6fd1c29519dab8fe9d597dd38650593`, revalidate touched seams on later revision. The active scene no longer consumes `DungeonArt`, but boot still invokes old `warmUpArt`; this temporary cost is this task's behavioral defect. Own `packages/app/lib/{art/dungeon_art.dart,art/art_assets.dart,art/warm_up.dart,game/dungeon_palette.dart,main.dart}` and `packages/app/test/art/{warm_up_test.dart,art_catalogue_test.dart}` only. Task 03 adds lighting afterward; no scene, renderer or UI changes here.

## Locked decisions

- `main()` retains `await warmUpArt()` before `guardedBoot`; change its import to new `art/warm_up.dart`. Move `_precache` and `warmUpArt` into that file; keep the once-per-process `_warmedUp` guard and `Future.wait(EnvironmentArt.values.map((art) => _precache(art.path)))`. No `rootBundle.load`/`instantiateImageCodec`/retained `ui.Image` for `MaterialArt` or `TerrainOverlayArt`; delete the obsolete `DungeonArt`, `dungeonArt` getter, `_decode` and `art/dungeon_art.dart` in this task, not an empty shim. Environment illustration paths/cache behavior and startup failure tolerance stay as they were.
- `RegionMaterial` is historical catalogue classification only: move its four values from `game/dungeon_palette.dart` to `art/art_assets.dart` and remove that file's import of the palette; preserve all `MaterialArt`/`TerrainOverlayArt` entries and mapping, `assets/visual/dungeon/` in `pubspec.yaml`, shipped files and asset masters. Do not delete historical catalogue or broad asset pipeline. `DungeonPalette` retains only wall/floor/stair ink, presets and route selectors already landed by Task 01.
- `art_catalogue_test.dart` keeps path existence, manifest and historical mapping coverage, removing only `DungeonArt.none()`/unloaded process assertions which are no longer consumer behavior. `warm_up_test.dart` replaces the old all-dungeon-images-loaded assertion with environment assets requested/resolved and no dungeon asset requests. No source-text or bare-not-throw test.

## Red → Green and proof

1. First write a behavioral warm-up test in `test/art/warm_up_test.dart` using `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', …)`. Decode request keys from UTF-8 `ByteData`, return real asset file bytes via `ByteData.sublistView` so image resolution is genuine, and remove the mock handler in teardown. Assert each `EnvironmentArt.path` was requested and resolved, and **no** `MaterialArt.path` or `TerrainOverlayArt.path` was requested; old `warmUpArt` fails Red by requesting all dungeon images. Guard against prepopulated image cache in the test's asset-request fixture; no fake image or silent `_precache` success. Record the Red command, observed request keys by category (not secret paths) and exit.
2. Move warm-up to `art/warm_up.dart`, update main import, move enum, delete obsolete runtime wrapper; adjust historical catalogue test. From `packages/app`: `flutter test test/art/warm_up_test.dart test/art/art_catalogue_test.dart test/widget/world_screen_test.dart test/widget/crawl_layout_test.dart`; `dart format <touched Dart paths>`; `flutter analyze`. Green means old dungeon image decode absent, environment precache still observed, scene/navigation remain alive. Record full relevant outputs/exits.

## Executor discretion

Local helper for precache error handling and binary-channel test spy cleanup, within the old startup semantics. No new asset management abstraction, lazy dungeon image loader, asset manifest removal, placeholder, production art or gameplay change.

## Escalate when

A real active consumer still imports `DungeonArt`; Flutter test bundle channel cannot observe the old manual decode or environment requests; eliminating decode breaks an actual non-crawl environment consumer; moving `RegionMaterial` would require changing palette/gameplay semantics. Never replace the Red proof with an implementation/source-text assertion.

## Handoff receipt

Red category request counts and exit; Green warm-up/catalogue/navigation/layout, formatter/analyzer exits; exact retained catalogue/manifest/historical files and removed runtime decode path; any contradiction. Handoff is the same ASCII scene with no unnecessary dungeon image decode, ready for Task 03. No device acceptance or publication.
