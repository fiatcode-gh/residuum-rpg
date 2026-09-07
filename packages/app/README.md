# residuum_app

The Flutter shell of Residuum: screens, BLoC state management, and the glyph
renderer that paints the dungeon on a canvas. No game rules live here — the
rules are `packages/core`, the data is `packages/content`, and this package
only renders state and turns input into actions.

Run it from an Android device, emulator, or Chrome:

```
flutter run
```

Tests are BLoC-level by default (events in, states out), with widget tests
only where a bloc test cannot observe the behavior — route guards, boot
wiring, navigation, dialogs:

```
flutter test
```

What lives where:

- `lib/game/` — battle and dungeon screens wired to the game pipeline.
- `lib/world/` — the overworld map and travel screens.
- `lib/town/` — town screens: merchant, bank, inn, alchemist, craft shop,
  roster.
- `lib/save/` — the autosaver and save-slot store.
- `lib/notice/` — the message log the game events drive.

Code conventions live in `CLAUDE.md` at the repository root.
