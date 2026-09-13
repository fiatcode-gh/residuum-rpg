# Residuum

A turn-based dungeon crawler for Android. Offline-first, seeded, and built in
plain Flutter — no game engine. Medieval fantasy with a roguelike heart:
travel an overworld of themed dungeons, descend one that reshuffles on every
visit, fight on a grid, loot gear with rarities and affixes, train skills by
using them, then decide at every staircase whether to bank the haul or risk
one more floor.

The name comes from the setting: magic is the residue of a dead god, and
dungeons are the wounds where it pools — which is why they refill.

## Current state — milestone M3 complete

The core loop exists end to end, and the world around it:

- Start in town. Travel the overworld to three themed dungeons — the crypt,
  the sea-cave, the ruined keep — each seeded, fog-of-war, tap-adjacent to
  move or attack, tap any explored tile to auto-walk. Road encounters ambush
  the journey between them.
- Turns run on a speed clock; monsters chase down a shared flow field. The
  battle flow is rebuilt around armed-target actions, the wait verb, and
  battle-screen dock chips.
- Stairs offer the game's central decision: descend, ascend, or return to
  town with everything you carry. Floors persist exactly within a run.
- Loot drops with rarity tiers (Common → Legendary = affix count), six
  equipment slots, healing potions. Deeper creatures pierce armor.
- Nine skills train by doing — arms, might, bulwark, fleetfoot by fighting,
  wrath, mending, binding by casting the spell school they name, herbcraft
  and blacksmith by gathering, brewing, mining, smelting, and working a
  temper.
- Magic: read spell books, learn spells of the three schools, cast them from
  the skill bar.
- Gathering and crafting: work herb patches and ore veins in the world,
  brew at the alchemist, smelt and temper at the craft shop.
- Town: merchant (buy/sell), bank (items and gold), inn (rest for gold),
  alchemist, craft shop, and the roster of saved heroes.
- Runs save and resume: two save slots with a rolling previous save; death
  burns carried items and carried gold. Worn gear, skills, and the bank
  survive. The dungeon reshuffles.

Everything is deterministic per world seed: the same seed is the same world,
and how a fight goes can never reshuffle a map or a drop (layout, loot, and
combat draw from separate random streams).

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
| `packages/content` | Declarative data: creatures, items, affixes, drop tables, economy, dungeons, spells. Adding a monster touches no logic. |
| `packages/app` | Flutter shell: HUD, dock, controls, log, routing, and BLoC state; Flame owns only the dungeon scene. No game rules. |

Design spec: `docs/specs/2026-08-20-dungeon-game-design.md`.
Code conventions: `AGENTS.md`.

## Tests

```
cd packages/core && dart test      # rules, mock-free
cd packages/content && dart test   # data validation + the survivability bot
cd packages/app && flutter test    # BLoC-level only
```

The suites are enforced by CI on every pull request to main (format, analyze,
and the tests, per package). Balance is pinned by simulation, not by feel: a
deterministic bot must complete the crypt descent in at least 16 of 40 seeded
runs (the crypt's soft floor, 0.40, ruled deliberately), and the sea-cave and
ruined keep each at their own 0.45 floors — currently sea-cave 26/40 and keep
24/40. Below the floor the game is unfair; above the ceiling it is trivial;
either fails the build. Note the band's limit: it is a floor and a ceiling,
not a pin — it cannot detect the game quietly getting easier.

## Visuals and accessibility

Colored glyphs on a grid (`@` you, `g` ghoul, `#` wall, `>` stairs), designed
so a pixel-tile atlas can replace them later without touching gameplay. All
state is encoded by shape, marking, or wording — never hue alone; every
screen stays legible in greyscale.

## Roadmap

- **M3 — The World:** shipped — overworld travel, three themed dungeons,
  road encounters, spell books, gathering and crafting, saves, roster.
- **M4 — The Story:** hand-authored main arc, armor sets, bosses, perks.
- **M5 — The Garden:** more of everything, pixel-tile renderer, balance.

Working title; everything subject to play.
