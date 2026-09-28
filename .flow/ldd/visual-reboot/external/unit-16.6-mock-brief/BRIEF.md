# Residuum — crawl UI revamp mock brief (Unit 16.6)

Draft 2026-09-24, repository head `4b8bd10`. Paste this brief into the image
session and attach the files listed under "Attach". The mocks that come back
are design proposals, not authority. The game's code decides every fact and
every action.

## Attach

- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-atmosphere-art-bible.png` (the art direction to keep)
- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-exploration-mock.png`
- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-combat-targeting-mock.png`
- `.flow/evidence/4b8bd10/UXW-EXP/20-at-west-edge.png` (the current build, exploration, "before")
- `.flow/evidence/4b8bd10/UXW-BAT/11-battle-first-frame.png` (the current build, battle, "before")

## Goal

Redesign the controls, panels and layout of the dungeon crawl screen of
Residuum, an ASCII roguelike for Android phones. **Keep the art direction
exactly as in the art bible.** Change the layout and controls: they are
cramped, change between exploration and battle, and move under the player's
thumb.

## Keep (art direction)

- Near-black background `#0A0F14`, soft blue-grey fog `#1A2430`, vignette,
  and a warm torchlight pool `#FFD27A` around the hero.
- Map drawn as monospace glyphs (IBM Plex Mono): `#` walls in warm tan,
  `·` floor dots in dim warm, `<` `>` stairs, `@` hero `#FFF4D6` with a soft
  glow, monster letters in enemy red `#FF5B5B`. Remembered terrain dimmer
  than visible terrain; unknown terrain is empty darkness.
- Type: EB Garamond for display (names, section titles, spaced capitals),
  Spectral for prose and control labels, IBM Plex Mono for numbers, data
  and log sentences.
- UI gold `#D6C280` for frames and titles, text `#E6E1D6` / `#9CA3AF`, cold
  blue `#4FC3FF` for mana and the armed spell.
- Thin framed panels with small corner radius. No ornament.
- Never show meaning by colour alone: every state also has a shape, a mark
  or a word. Never pair red with green.

## Change (the revamp)

1. **Full-screen.** No Android status bar, no navigation bar. The phone is
   1080×2392 px (393×870 dp). Keep a safe margin at the top for the camera
   cut-out and at the bottom for the gesture handle.
2. **Top HUD, identical in every mode.** Thin, about 56 dp:
   - HP bar with `HP 14/20`; mana bar with `Mana 3/8` (only when the hero
     knows spells); gold with a coin mark and a number.
   - One small line: `Depth 2/5 · The Crypt · Day 2` and one status chip
     (`Steady` / `Wounded` / `Critical`, plus `Watched 1` or `Engaged 3`
     when a monster is watching or fighting).
   - No `RESIDUUM` wordmark on this screen.
3. **Bigger map.** The map fills everything between the HUD and the bottom
   bar. Cells are larger than now, about 24 dp wide and 30 dp tall (about 16
   columns across), so a finger can hit the floor next to the hero. The
   camera keeps the hero centred; the player can drag to pan.
4. **Persistent bottom bar.** Five framed slots, always the same five in the
   same order, in exploration and in battle. Icon above label:
   `Wait` (hourglass) · `Potion ×2` · `Spells` · `Pack` · `Character`.
   A slot that cannot be used right now is shown dimmed, never removed.
5. **Things on the map are used on the map.** When the hero stands on or
   next to something, a small prompt card appears just above the hero with
   one button: `Pick up Iron Helm`, `Mine`, `Gather`, `Descend >`,
   `Ascend <`, `Leave`, `Move on`, `Flee`. Tapping the hero does the same.
6. **Log ticker, not a log panel.** The last two log lines float over the
   bottom of the map, fading older lines out, in mono, category-tinted
   (hostile red, spell/item cold blue, discovery amber, neutral ivory).
   Tapping the ticker opens the full log.
7. **Battle keeps the same frame.** Nothing above or below the map moves
   when a fight starts. Battle information floats over the map:
   - A timeline strip along the top edge of the map: `NOW` then `NEXT` pills,
     each a glyph and a name (`@ You`, `r¹ giant rat`, `w dire wolf`). When
     more pills exist than fit, the strip shows `+2` at the end.
   - A compact target card docked just above the bottom bar: name in
     display type, HP bar with `HP 3/4`, `ATK 1–2  SPD 10  Reach 1`.
   - A small HP pip bar under each engaged monster glyph.
   - Tapping `Spells` opens a small tray above the bottom bar with up to
     three readied spells (glyph, name, mana cost). The armed spell gets a
     cold-blue border glow; legal targets on the map get corner brackets
     `[ ]`, the selected target heavier brackets.
8. **Character screen**, opened from the bottom bar: hero name, HP, mana,
   ATK, ARM, gold, and the worn gear by slot (weapon, head, body, hands,
   legs, off-hand), with the same frames and type as the art bible's
   character screen.

## Frames to render (one board, seven phone frames, same style as the attached mocks)

1. **Exploring.** Lit room, remembered corridor dimmer, stairs `>` far away,
   the hero standing on an item: the prompt reads `Here: Common Iron Helm`
   with a `Pick up` button. Ticker: "You step east." / "You step east."
2. **Watched.** A giant rat `r` visible five cells away. Chip `Watched 1`.
   Ticker: "The giant rat comes into view." Bottom bar unchanged; Wait is
   live.
3. **Gathering.** Hero on an ore vein: prompt `Mine`.
4. **Battle.** Hero adjacent to `r²`, with `r¹` and `w` (dire wolf) nearby.
   Chip `Engaged 3`. Timeline strip, target card for the giant rat², HP pips
   under all three monsters. Ticker: "The giant rat² claws you for 2." in red.
5. **Targeting.** Same fight; the spells tray open with `Frost Lance 4`,
   `Firebolt`, `Mend`; Frost Lance armed (cold-blue glow); legal targets
   bracketed; the wolf selected with heavier brackets.
6. **Full log.** A sheet over the lower map, titled `RECENT EVENTS` with
   `12 entries` and a close `×`; one icon per category and a mono sentence
   per row. The bottom bar stays visible.
7. **Character screen.** As in item 8 above; `Rusty Sword` as the weapon,
   `Leather Cap` and `Leather Jerkin` worn, other slots empty.

## Real names only

Monsters: the giant rat, the dire wolf, the ghoul, the skeleton, the wight.
Spells: Frost Lance (4 mana, frost), Firebolt, Mend, Ward, Bind, Banish.
Items: Healing Potion, Rusty Sword, Iron Sword, Iron Helm, Leather Cap,
Leather Jerkin, Kite Shield. Places: The Crypt, The Sea-Cave, The Ruined Keep.

## Leave out (the game has no such thing)

Torch, hunger, "Clear", seed numbers, auto-walk or help buttons, an Inspect
button, hamburger or settings buttons, clock timestamps in the log, turn
numbers in the timeline, to-hit percentages, monster flavour text, doors
`+`, water `~`, dotted range paths, minimaps, experience bars.
