# Unit 16.6 recon — crawl UX discovery (2026-09-24)

Observed head: `4b8bd10` on `main` (Units 16 and 16.5 merged). Device: vivo
I2505, 392.7×869.8 dp. Evidence: `.flow/evidence/4b8bd10/UXW-EXP/` and
`UXW-BAT/` (synthetic ADB input; finger feel not assessed). Both save slots
restored byte-identically (Main re-hashed after each capsule).

User direction: "feels right" wins over mock parity; the art direction stays.

## Measured regions (dp, from `UXW-BAT` receipt; `UXW-EXP`'s header figure is wrong)

| Region | Exploration | Battle |
|---|---|---|
| Header (wordmark, meta, chips) | 106 | 101 |
| Timeline | 0 | 60 |
| Map | 452 | 360 |
| Hero / combat panel | 91 | 118 |
| Log | 89 | 98 |
| Action bar (incl. nav inset) | 101 | 106 |

## Findings, ranked by how often the player meets them

1. **Map and floor shapes disagree.** `generator.dart:258-259`: floors are
   `24 + 2(d-1)` × `16 + (d-1)` cells; at 16×20 dp, depth 1 is 384×320 dp and
   depth 5 is 512×400 dp. The exploration map is 452 dp tall, so depth 1
   wastes 132 dp vertically and leaves walls about 4 dp from the side edges
   (`grid_geometry.dart:68` centres a floor that fits). Width is the tight
   axis, height is slack. Pan does nothing on floors that fit (UXW-EXP #5).
2. **Moving while watched is opaque.** A non-adjacent tap with an enemy in
   sight logs "Something is watching. You stay put." and changes no game
   state (`game_bloc.dart:787-801`). The action list is app-level
   (`game_screen.dart:361-453`): Wait is offered only in battle or a road
   encounter, so a dungeon Watched state has no Wait (UXW-BAT 30). The
   verifier made 10+ taps with no progress; only exact adjacent-cell taps
   move. Not a core soft-lock, but it reads as one. Verifier claim
   "dismissing a callout costs a turn" is false for the same reason.
3. **Battle entry drops the map 92 dp at once** (452 → 360): the 60 dp
   timeline row plus a combat panel 27 dp taller than the hero panel. Exit
   restores it at once.
4. **Action bar**: three of five frames empty in a fresh game; filled order
   shifts between states (Drink/Pack/Wait, Drink/Wait/Pack, Drink/Pack/Move on).
5. **Combat panel**: READIED SPELL column holds one line with no spell; YOU
   column is thin; one target shown with three engaged; "Adjacent"
   (`target_facts.dart:15`) is the monster's reach but reads as distance.
6. **Timeline**: with one actor the row is mostly empty; with four the last
   pill clips at the screen edge with no cue ("w the …").
7. **Hero panel**: weapon name wraps to two lines; dead gap under HP in the
   left column; weapon, armour and gold take permanent space though they
   rarely change.
8. **Pack screen (off the crawl)**: six stacked full-width filter buttons,
   placeholder dot for the potion icon, empty categories look identical to
   full ones, large dead space. Not restyled by U14–U16.5.

Works well: one-tap melee, one-tap potion, log sheet open/close, wall-bump
message, auto-walk stopping on sighting.
