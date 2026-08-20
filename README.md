# Residuum

A turn-based dungeon crawler for Android. Offline-first, seeded, and built in
plain Flutter — no game engine. Medieval fantasy with a roguelike heart:
descend a dungeon that reshuffles on every visit, fight on a grid, loot gear
with rarities and affixes, train skills by using them, then decide at every
staircase whether to bank the haul or risk one more floor.

The name comes from the setting: magic is the residue of a dead god, and
dungeons are the wounds where it pools — which is why they refill.

## Current state — milestone M2 complete

The core loop exists end to end:

- Start in town. Enter the dungeon: five seeded floors, fog of war,
  tap-adjacent to move or attack, tap any explored tile to auto-walk.
- Turns run on a speed clock; monsters chase down a shared flow field.
- Stairs offer the game's central decision: descend, ascend, or return to
  town with everything you carry. Floors persist exactly within a run.
- Loot drops with rarity tiers (Common → Legendary = affix count), six
  equipment slots, healing potions. Deeper creatures pierce armor.
- Four skills train by doing: Arms, Might, Bulwark, Fleetfoot.
- Town: merchant (buy/sell), bank (items and gold), inn (rest for gold).
- Death burns carried items and carried gold. Worn gear, skills, and the
  bank survive. The dungeon reshuffles.

Everything is deterministic per world seed: the same seed is the same
dungeon, and how a fight goes can never reshuffle a map or a drop (layout,
loot, and combat draw from separate random streams).

## Run it

```
cd packages/app
flutter run        # Android device, emulator, or Chrome
```

No setup beyond a Flutter SDK. No accounts, no network, no telemetry.

## Architecture

Three packages, dependency rule `app → content → core`:

| Package | What it is |
|---|---|
| `packages/core` | Pure Dart game rules. Immutable state; the only way the game changes is `step(state, action) → (state, events)`. Zero Flutter imports. |
| `packages/content` | Declarative data: creatures, items, affixes, drop tables, economy. Adding a monster touches no logic. |
| `packages/app` | Flutter shell: glyph renderer on a canvas, BLoC state, town screens. No game rules. |

Design spec: `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`.
Code conventions: `CLAUDE.md`.

## Tests

```
cd packages/core && dart test      # rules, mock-free
cd packages/content && dart test   # data validation + the survivability bot
cd packages/app && flutter test    # BLoC-level only
```

514 tests. Balance is pinned by simulation, not by feel: a deterministic bot
must complete a floor-1-to-5 descent in 50–95% of 40 seeded runs (currently
62.5%). Below the floor the game is unfair; above the ceiling it is trivial;
either fails the build. Note the band's limit: it is a floor and a ceiling,
not a pin — it cannot detect the game quietly getting easier.

## Visuals and accessibility

Colored glyphs on a grid (`@` you, `g` ghoul, `#` wall, `>` stairs), designed
so a pixel-tile atlas can replace them later without touching gameplay. All
state is encoded by shape, marking, or wording — never hue alone; every
screen stays legible in greyscale.

## Roadmap

- **M3 — The World:** overworld travel, multiple themed dungeons, random
  encounters, spell books, gathering and crafting, saves.
- **M4 — The Story:** hand-authored main arc, armor sets, bosses, perks.
- **M5 — The Garden:** more of everything, pixel-tile renderer, balance.

Working title; everything subject to play.
