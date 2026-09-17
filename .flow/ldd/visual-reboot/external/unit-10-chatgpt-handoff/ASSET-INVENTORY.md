# Unit 10 — Working Asset Inventory

Status: **logical inventory only; exact files not verified by ChatGPT.**

The actual asset files were not visible in the connected repository or retrieved
file-library results. These entries capture the roles discussed for Unit 10 so
the receiving local session can bind them to the real files without inventing
paths.

## Environment art

| Logical role | Proposed surface | Contract note |
| --- | --- | --- |
| Stonebridge environment | `TownScreen` when town is Stonebridge | Do not reuse for Northgate. |
| Forge environment | `ForgeScreen` | Atmospheric only. |
| Tavern environment | `TavernScreen` | Atmospheric only. |

## Dungeon material sources

Expected region families:

- Crypt material sources;
- Sea-Cave material sources;
- Ruined Keep material sources.

The discussion assumed a mix of base floor/wall material images plus decorative
crack/rubble imagery. Exact counts, filenames, dimensions, alpha, and which
images are base-vs-overlay must be verified locally.

Lowland road has no assumed authored asset in this proposal.

## UI/icon roles discussed

Candidate roles, only when a matching actual file exists:

- Potion / Drink
- Pack
- Wait
- Ascend
- Descend
- Firebolt
- Mend
- More / overflow
- Back
- Melee

Scope cautions:

- labels/counts stay visible beside icons;
- Melee must not create a button because melee is currently map-direct;
- Back is intentionally outside the base first icon slice unless separately
  approved because it is a cross-screen navigation sweep;
- missing spell/action icons fall back to text rather than a misleading generic
  icon.

## Local inventory work required

Before Unit 10 contract approval/planning, record for every real file:

- exact repository-relative filename/path;
- format (PNG/WebP/etc.);
- pixel dimensions;
- alpha/transparency behavior;
- intended logical role;
- whether it is safe to crop/sample or must render whole;
- whether visual edges are seamless/repeatable;
- any provenance/licensing metadata the project requires.

Any mismatch that changes Unit 10 behavior or scope should amend the proposed
contract before approval rather than being hidden in implementation.
