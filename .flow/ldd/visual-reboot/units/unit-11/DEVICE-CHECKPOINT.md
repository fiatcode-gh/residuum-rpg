# Unit 11 device checkpoint

Date: 2026-09-17

## Tree and ownership

- Branch: `residuum-visual-reboot-11`
- HEAD: `0692bbcce7570df988f6daab9b357a2557e58b39`
- The implementation is intentionally uncommitted. Preserve the listed dirty app files and the architect-owned LDD records/bundle; do not reset, stash, switch or overwrite them.

## Accepted automated evidence

- Integrated gate on this tree: `dart format --set-exit-if-changed --output=none lib test` passed with 114 files and 0 changed; `flutter analyze` passed; `flutter test` passed with 883 tests before the correction round.
- U11-ACC-1/2 correction evidence: focused 47 tests passed, formatter 114 files/0 changed, analyzer clean, full app suite 884 passing.
- Scoped independent acceptance closure PASS on the current dirty tree. It reviewed remembered base-only rendering and all eight real mirror/quarter-turn overlay variants; it permits device evidence.

## Remaining acceptance criteria

Capture one colour frame and a greyscale twin for each: Crypt structure/knowledge, Crypt stairs, Sea-Cave combat/targeting, Ruined Keep structure, and lowland-road regression. Compare the dungeon capsules beside the approved mock. No second colour pass is planned unless the one permitted constants-only tuning pass changes an affected scene.

## Device state and restore obligation

- Device: user-started `Medium_Phone`; agent-shell emulator launch is prohibited.
- Before any install, back up both `app_flutter/` save slots and record SHA-256 hashes.
- After all captures/install activity, restore both slots and verify byte-identical hashes using the same SHA-256 comparison scheme.

## Exact next action

Once `Medium_Phone` is running and visible to ADB, dispatch fresh evidence-verifier capsules: Crypt structure/stairs, Sea-Cave combat/targeting, Ruined Keep structure, and lowland-road regression. Each capsule owns only its assigned scene family and reports its save restore obligation.