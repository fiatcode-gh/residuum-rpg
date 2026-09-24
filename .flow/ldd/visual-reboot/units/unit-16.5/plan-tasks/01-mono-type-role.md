# 01 — Mono type role, crawl palette tokens, AGENTS Type rule

Governing: `../CONTRACT.md` (settled decision 2, scope items 1 and 5),
`../PLAN.md` §2 G2, G3. Work from `packages/app` unless a path says otherwise.

## Starting repository state

Head `2c073b7` (or the latest accepted U16.5 commit if replanned), branch
`residuum-visual-reboot-16`. `LEDGER.md`/`RESUME.md` may be dirty — not
yours, never touch. No IBM Plex Mono anywhere in the repo;
`lib/style/tokens.dart` has `textFace`/`displayFace` only;
`test/support/fonts.dart::loadResiduumFonts` registers Spectral and EB
Garamond; `test/style/type_authority_test.dart` checks family as
`isDisplay ? displayFace : textFace`.

## Owned files

- new `assets/fonts/IBMPlexMono-Regular.ttf`, `assets/fonts/IBMPlexMono-SemiBold.ttf`, `assets/fonts/OFL-IBMPlexMono.txt`
- `pubspec.yaml` (fonts section only)
- `lib/style/tokens.dart`
- `test/support/fonts.dart`, `test/style/type_authority_test.dart`
- repo-root `AGENTS.md` (the **Type** bullet only)

Non-goals: no consumer of the new roles/tokens yet (Tasks 02+); no CI edit
(Task 02); no other doc.

## Locked decisions

1. Download with curl from
   `https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexmono/{IBMPlexMono-Regular.ttf,IBMPlexMono-SemiBold.ttf,OFL.txt}`;
   save `OFL.txt` as `OFL-IBMPlexMono.txt`. Verify SHA-256 equals
   Regular `6a3412f058c7d8dfd9170c41e85ade48e5156ecb89356110ca57a0a27734af46`,
   SemiBold `d3c38e55c78f5b0f28009fddba4834ec503278936a5986032424c9bd2d23aa46`,
   OFL `7e6b2818edbd8f6a01ae80641cc8f16a51080d08fb4e532be3a0b6f74adb07da`.
2. `pubspec.yaml` adds, after EB Garamond:
   ```yaml
       - family: IBM Plex Mono
         fonts:
           - asset: assets/fonts/IBMPlexMono-Regular.ttf
             weight: 400
           - asset: assets/fonts/IBMPlexMono-SemiBold.ttf
             weight: 600
   ```
3. `tokens.dart`: `const String monoFace = 'IBM Plex Mono';`; every colour
   token in PLAN G3 (exact names/values); every role in PLAN G2 table
   (exact names, sizes, weights, heights, letterSpacing, colours), each
   `inherit: false`, explicit `height`, `textBaseline: TextBaseline.alphabetic`,
   `fontFeatures` containing `FontFeature.tabularFigures()` (display roles
   also `FontFeature.liningFigures()` and
   `fontVariations: [FontVariation('wght', 500)]`, matching existing display
   roles). Two functions:
   `TextStyle mapGlyphStyle(Color ink)` (monoFace, 17, w400, height 1.0) and
   `TextStyle mapBadgeStyle(Color ink)` (monoFace, 8, w400, height 1.0), same
   invariants, `color: ink`. Existing roles/colours unchanged.
4. `loadResiduumFonts` adds `(monoFace, ['assets/fonts/IBMPlexMono-Regular.ttf', 'assets/fonts/IBMPlexMono-SemiBold.ttf'])`.
5. `AGENTS.md` Type bullet becomes exactly:
   `- **Type:** \`fontFamily\` appears only in \`packages/app/lib/style/tokens.dart\`.`
   `  Every text style is a role from that module: EB Garamond for display,`
   `  Spectral for body prose and control labels, IBM Plex Mono for map glyphs,`
   `  log sentences, numbers and data values (Unit 16.5). A role needing a`
   `  second colour gets a \`const\` sibling there; \`copyWith\` of a token is`
   `  prohibited, because its consumers are \`const\`. The only non-\`const\``
   `  styles are \`mapGlyphStyle\` and \`mapBadgeStyle\`, whose ink is continuous;`
   `  they are built in \`tokens.dart\` too.`
   (wrapped to the file's existing width; the "Monospace was retired" sentence is removed).

## Proof (Red first)

In `type_authority_test.dart`:
- group "the faces resolve": add
  `test('monoData advances a fixed 0.6 em per glyph', …)` expecting
  `_widthOf('MMMMMMMMMM', monoData)` and `_widthOf('iiiiiiiiii', monoData)`
  both `closeTo(69.0, 0.5)` (Ahem would give 115).
- new group "Plex Mono glyph coverage": for both Plex files, `_cmapContains`
  is true for every code point 0x20–0x7E and for
  `· – — × ⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹ ← → ↓ † § ›`.
- the roles map lists every new role; the family test becomes
  `name.startsWith('display') ? displayFace : name.startsWith('mono') ? monoFace : textFace`;
  add a test that `mapGlyphStyle(const Color(0xFF123456))` and
  `mapBadgeStyle(…)` satisfy the same invariants and carry the given colour.
Expected Red: compile error on missing symbols, then (tokens added, fonts
absent) the width test measures Ahem and the coverage tests fail to read the
files. Green: `flutter test test/style/type_authority_test.dart`. Also run
`flutter test test/widget/town_shell_test.dart` (a font change must not move
town layout), `dart format lib/style/tokens.dart test/support/fonts.dart test/style/type_authority_test.dart`, `flutter analyze`.

## Executor discretion

Order/grouping of declarations in `tokens.dart`; test names; whether the
coverage loop is one test per code point or one aggregate test with a
listed-missing message.

## Escalate when

A download hash differs; any listed code point is missing from either file;
the width test is not 69.0 ± 0.5 with the font registered; a town/other
screen test changes behaviour.

## Completion receipt

Hashes verified, Red output (first failing assertion), Green command + exit,
analyzer/format exits, changed-file list. Commit:
`feat(app): add IBM Plex Mono data role and crawl palette tokens`.
