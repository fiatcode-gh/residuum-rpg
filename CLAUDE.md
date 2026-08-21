# Residuum — code conventions

Design spec: `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`. Read it before
substantive work.

## Architecture

- Monorepo packages: `packages/core` (pure Dart game rules), `packages/content`
  (declarative game data), `packages/app` (Flutter shell).
- **Dependency rule:** `app → content → core`. `core` and `content` must never import
  Flutter. A game rule in a widget is a bug.
- `core` is organized **by feature** (`dungeon/`, `combat/`, `skills/`, `loot/`,
  `craft/`, `world/`, `quest/`, `engine/`) — never by kind. No `models/`, `services/`,
  or `utils/` folders.

## State model

- Game state is **immutable**. The only way the game changes:
  `(GameState, List<GameEvent>) step(GameState state, GameAction action)`.
- Events drive the message log, UI updates, and quest triggers. New behavior emits
  events; it does not reach around the pipeline.
- **No global randomness.** Every random decision draws from an `Rng` carried in state.
  An unseeded `Random()` anywhere in `core` or `content` is a bug.
- Concepts get value objects (`Rarity`, `DamageType`, `SkillLevel`) — immutable,
  self-validating. No naked ints or strings for domain concepts.

## Craftsmanship

- **Comments:** none in bodies. Dartdoc `///` only, and only on public API of `core` and
  `content`. Names and small functions carry intent; if code needs a comment, rewrite it.
- **Ubiquitous language:** code uses the spec's words exactly — `temper`, `affix`,
  `beat`, `rumor`, `residue`. No synonyms, no abbreviations.
- Functions do one thing. Files stay small — a large file means a concept wants
  splitting.
- YAGNI: build for the current milestone only. No premature abstraction; duplicate twice
  before extracting.

## Testing

- **core:** strict test-driven development (red → green → refactor) for every behavior.
  Tests are pure: state in, state out, no mocks. Structure bodies as
  `// arrange` / `// act` / `// assert`.
- **content:** validation tests (every referenced ID exists, every quest beat has a
  trigger, every spell's school is a real skill).
- **app:** BLoC-level tests (events → states) are the default. Widget tests are
  permitted wherever a bloc test cannot observe the behavior — route guards, boot
  wiring, navigation, dialogs. No golden-image tests; look and feel are still
  verified manually on device.
- Determinism is tested: same seed must produce identical floors, identical rolls.

## Accessibility (non-negotiable)

- Author is deuteranomalous. Encode state, rarity, and categories by shape, marking,
  position, or a word — never hue alone. Every screen must read in greyscale.
