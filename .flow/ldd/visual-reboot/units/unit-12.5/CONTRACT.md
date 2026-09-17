# Unit 12.5 — Crawl Device Gate

Status: **drafted, awaiting explicit user approval**
Depends on: Unit 12, accepted on suite evidence
Visual reference: `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`, frames 2–5

## Why this unit exists

The user decided on 2026-09-17 that Unit 12 closes on suite evidence and the
`Medium_Phone` pass becomes its own unit. Unit 12 is therefore the first unit
of this epic to be accepted without device evidence, and this unit is the debt.

It is a verification unit. It writes no feature. Its only production changes
are corrections that its own evidence forces, and those are bounded.

## Inherited debt

Unit 12 deferred five of its seventeen criteria, wholly or in part:

- **AC5** — available, disabled and armed separable without reading colour.
  The suite proves value, weight and word differ. Greyscale on glass is this
  unit's.
- **AC12** — town, world, character, spells, roster and pack screens visually
  unchanged. The suite proves the crawl theme does not leak and the pack route
  still renders in the town's ink. Confirmation by eye is this unit's.
- **AC14** — the map remains usable at worst legal density. The suite asserts
  chrome against caps on a fallback font; whether the resulting map is
  playable is this unit's.
- **AC16** — the device capsules in full.
- **AC17** — whether the dungeon viewport is now the dominant remaining parity
  gap. That judgement needs the crawl seen on a device.

## The number that matters

Correction C1 modelled worst legal combat at **~561 dp of chrome, leaving
~283 dp of map** on `Medium_Phone` — about seven rows of sight with the hero
centred. That is a floor, not comfort. The scene is rare: the bottom floor,
standing on the up stairs, a gather node and loot underfoot, a full pack, every
spell known, and a monster holding reach. It is also the scene that needs the
least map, since melee is adjacent and targeting is centred.

The suite's figures come from `flutter_test`'s fixed-width fallback face, not
the device's `monospace`. They are an upper bound on the device's, because the
corrected fit rule is sound — but they are a model, and this unit replaces the
model with measurements.

## Scope

1. Back both device save slots up and record their hashes before any install.
2. Install the accepted Unit 12 build on a user-started `Medium_Phone`.
3. Capture the seven capsules below, each in colour **and** greyscale.
4. Measure and record the real chrome and map height for the exploration,
   typical-combat and worst-legal-combat scenes, and compare them against
   Correction C1's device thresholds: 360 / 460 / 600 dp of chrome.
5. Judge the crawl against mock frames 2–5 on hierarchy, density, rhythm,
   framing, contrast and action-state clarity. Never pixel parity.
6. Restore both slots and verify the restored bytes against the pre-install
   hashes under the same comparison scheme.

### Capsules

| capsule | scene | settles |
|---|---|---|
| A | exploration, stairs landing, loot and a gather node underfoot, potions carried | AC2, AC4, AC5, AC14 worst exploration, map framing |
| B | open combat, four known spells, potion carried | AC2, AC3, AC4, AC6, AC14 typical combat, timeline hierarchy |
| C | armed targeting, map targets marked | AC5 armed, AC10, no reflow on arming |
| D | expanded log at half and full | AC8, handle, title, rule, rhythm, mark well |
| E | spells sheet, enemy info sheet, completion confirm, death overlay | AC11 |
| F | town, world, character, spells, roster and pack screens | AC12 |
| G | the densest legal battle reachable on device | AC14 ceiling, recorded map height |

Capsule G is the one that can fail. A and B are expected to pass comfortably.

## Bounded correction allowance

At most **one** constants-only tuning pass, inside the envelopes Correction C1
names. A measured chrome height above a device threshold, or a map judged
unplayable at capsule G, is **not** a tuning problem. Its remedies are
contract-level and are recorded in `PLAN.md` Correction C1 in the order the
plan recommends them:

1. stand exploration verbs down while a monster holds reach — amends the
   "a control appears exactly when it applies" lock and AC9;
2. shrink or collapse the log peek during combat — touches AC8 and the
   four-region lock;
3. drop the icon slot past two runs — touches AC4;
4. accept the measured floor and record it.

Choosing among those is the user's, not an executor's.

## Non-goals

- Any Unit 12 feature work, restyling or scope the device pass does not force.
- New assets, including fonts and log-category icons.
- Unit 11's dungeon renderer.
- `packages/core`, `packages/content`, save schema, content, balance,
  generation, RNG.
- Dungeon Structural Asset Expansion, whatever AC17 concludes. That is its own
  unit.

## Acceptance criteria

1. Both save slots are backed up before installation and restored
   byte-identically afterwards, with hashes recorded under one comparison
   scheme.
2. All seven capsules are captured in colour and greyscale and stored under
   `.flow/evidence/visual-reboot/`.
3. Real chrome and map heights are recorded for the exploration,
   typical-combat and worst-legal-combat scenes and compared against the
   360 / 460 / 600 dp thresholds.
4. Unit 12's AC5 greyscale, AC12 by-eye and AC14 device figures are each
   settled — passed, or failed with the measurement that failed them.
5. No label ellipsises, no word breaks and no verb hides at worst legal
   density on real hardware.
6. Any correction the evidence forces is either the one allowed constants-only
   pass, or an explicit user decision among the four recorded remedies.
7. If any production, asset or build change is made, the affected suite proof
   is rerun and a scoped closure review runs on the changed tree before the
   unit closes.
8. AC17 is recorded: whether the dungeon viewport is now the dominant
   remaining parity gap, and therefore whether Dungeon Structural Asset
   Expansion becomes the immediate next unit.

## Verification disposition

Evidence capture is delegated to bounded `flow-evidence-verifier` capsules,
one coherent scene cluster each, each with an `Evidence capsule:` manifest and
a restore obligation. The architect owns the checkpoint, the acceptance brief,
inspection of the consequential evidence and the final judgement.

`Medium_Phone` must be user-started. The phone build is not debuggable; `adb`
screenshots are the instrument.
