# Unit 16.6 Contract — Crawl Controls and Layout Revamp

Status: **approved 2026-09-24; amended 2026-09-24 (touch-target rule) and
2026-09-25 (action card, from the user's device feedback).**

Observed head: `4b8bd10` (`main`, Units 16 and 16.5 merged). Feature branch
`residuum-visual-reboot-16.6`.

Evidence: `units/unit-16.6/recon.md` and the device walkthrough under
`.flow/evidence/4b8bd10/UXW-EXP/` and `UXW-BAT/`.

## Why this unit exists

Units 16 and 16.5 matched the approved mocks, and the crawl screen still plays
badly on a phone. The walkthrough found the map cells too small to tap
accurately, and a hero panel whose contents change when a fight starts. It
also found a bottom bar whose buttons appear, disappear and change order, a
map that loses 92 dp the moment a fight starts, and a Watched state that
looks like a stall. The user decided on 2026-09-24 that **"feels right" wins
over mock parity, and the art direction stays.**

## Outcome

The crawl screen is organised around the player's thumb: fixed information
at the top, a map big enough to tap, the log, and a bottom menu that never
changes. Actions tied to the moment (place actions, Wait, Flee) sit in one
action card pinned to the map's bottom edge, with a leader line to the hero.
The palette, type roles, glyph
rendering, light and fog are unchanged.

## Settled decisions (user, 2026-09-24)

1. **Persistent bottom menu:** four slots, always in this order in every
   crawl state: `Quests`, `Spells`, `Quick`, `Hero`.
2. **Spells** opens a child pop-up listing the readied spells. It works in
   and out of combat (for example Mend while exploring).
3. **Quick** replaces the potion button. It opens a child pop-up listing the
   consumables carried; today that is the Healing Potion only. Drinking
   always takes two taps (open, choose), including while only one kind
   exists.
4. **Hero** opens the character screen. The full Hero screen (stats,
   inventory, equipped gear) is Unit 16.7. Until then, `Hero` opens today's
   crawl pack screen, so inventory, equip and drop stay reachable.
5. **Quests** is built now and, when tapped, shows a "coming soon" notice.
   The game has no quest system yet; the user chose to show the slot anyway.
6. **Wait and Flee live in the action card** (item 8), not beside the log.
   Wait shows in combat and while the hero is Watched; Flee shows when
   fleeing is legal. (User, 2026-09-25: the log-side placement was
   rejected; a later shield "block" action is expected to join the card.)
7. **Top HUD replaces the `RESIDUUM` wordmark:** HP bar, mana bar (when
   spells are known) and gold, identical in every crawl state.
8. **One action card, pinned to the map's bottom edge** (user, 2026-09-25):
   Pick up, Mine, Gather, Descend `>`, Ascend `<`, Leave or Finish, Move on,
   Flee and Wait share one card in the target card's visual family — the
   same frame, and a thin leader line from the card to the hero. It never
   floats beside the hero, so the area around the hero stays open while
   exploring (for example on a cleared road where Move on is offered).
9. **Battle information floats over the map:** the turn order as a strip
   along the top edge of the map, and the target's facts in a card next to
   the target. The fixed combat panel is removed.
10. **Full-screen:** the app hides the Android status and navigation bars.
11. **The map is big enough to tap the floor next to the hero accurately;**
    drag to pan stays a feature.

Architect proposals carried from the discussion (part of this approval):

- Map cells about **24 dp wide × 30 dp tall** (about 16 columns on a 393 dp
  phone). The hero sees 8 cells in every direction, so the lit area is 17
  cells wide; at 24 dp nearly all of it stays on screen.
- The camera keeps the hero centred, including near the floor's edges; the
  darkness beyond a floor edge may show. Drag to pan and recenter keep
  working.

## In scope

### 1. Screen composition, top to bottom (every crawl state)

1. **HUD.** Row one: HP bar with `HP a/b`, mana bar with `Mana a/b` only when
   spells are known, gold with its mark and number. Row two: the meta line
   (`Depth N/M | place | Day D`) and the existing status chips (battle or
   watch state, HP condition, ward). Same position and content in
   exploration, Watched, battle and armed states.
2. **Map.** Everything between the HUD and the log row. **Its rectangle is
   identical in exploration, Watched, battle and armed states.**
3. **Log row.** The framed recent-events peek, full width, with its truthful
   count and expand control. Nothing else sits in this row.
4. **Bottom menu.** Four framed slots: `Quests`, `Spells`, `Quick`, `Hero`.
   A slot with nothing to offer right now is dimmed, never removed. Each
   slot shows only its icon above its label, centred in the slot, with no
   count or other metadata (user, 2026-09-25).

Removed from the crawl: the wordmark, the hero panel, the combat panel and
the contextual action bar.

### 2. Spells pop-up

- Lists the readied spells (today up to 3), each with its mark, name and
  mana cost. Reaching known spells beyond the readied three stays possible,
  as today.
- Choosing a spell that needs a target arms it and enters today's targeting
  flow (legal-target reticles, tap to cast, the armed state shown by the
  existing cold-blue treatment plus a word). Choosing a spell that needs no
  target casts it.
- Available in and out of combat. When the rules refuse a cast, the player
  sees the refusal the way refusals are shown today; nothing fails silently.
- No known spells: the slot is dimmed, and tapping it says so.

### 3. Quick pop-up

- Lists each consumable kind carried, with its count; choosing one drinks it
  through the existing drink action.
- Nothing carried: the slot is dimmed, and tapping it says so.

### 4. Action card

- The card appears whenever at least one of its actions applies: a place
  action (with what is here, for example `Here: Common Iron Helm and 1 more`,
  `Underfoot: ore vein`), Wait, or Flee. One button per legal action;
  several actions share the card.
- It is pinned to the map's bottom edge, full map width less the map margin,
  with a leader line to the hero's cell. If the hero's cell or its four
  neighbours would be covered there (the player has panned the hero low), the
  card pins to the top edge instead, below the turn-order strip.
- It takes input only inside its own bounds and does not stop the map from
  being tapped or panned. The target card and the card never overlap.
- The map rectangle does not change when the card appears or goes.

### 5. Battle overlays

- **Turn-order strip** along the top edge of the map: `NOW` then `NEXT`
  tokens with today's identity, ordinals and secrecy. When the tokens do not
  fit, the strip shows that more exist (scroll or a `+N` cue); nothing
  clips silently.
- **Target card** next to the current target on the map: name, HP bar with
  `HP a/b`, and the facts the enemy sheet shows today. The monster's reach
  is worded so it cannot be read as distance (today `Adjacent` means reach
  1).
- Neither overlay changes the map rectangle. Neither covers the hero.

### 6. Map and input

- Cells about 24×30 dp in the mono role; glyph set, value hierarchy, light
  pool, fog, vignette and parallax as today, scaled to the new cell.
- The camera keeps the hero centred. Drag to pan and recenter keep working
  on every floor size.
- Touch-by-intent rules from Unit 16.5 stay (nearest legal target, monster
  within reach, step toward a tap near the hero), with their radii
  re-checked against the new cell. Monster reach is a 24 dp radius (48 dp
  across); near-hero stepping uses a 48 dp reach box; discrete controls keep
  targets of at least 48 dp. **A near-hero step starts only from a tap on a
  floor cell; a tap on the void beyond the floor never steps.** Outside the
  step box a tap selects the exact cell under the finger for auto-walk; that
  24×30 dp cell is an accepted exception to the 48 dp target.

### 7. Full-screen

- The app runs without Android status and navigation bars on every screen.
  Content stays clear of the camera cut-out and the gesture handle; the
  bottom menu and side edges stay usable with gesture navigation.

### 8. Documentation

Mark superseded in `units/unit-13/VISUAL-SYSTEM.md` and the ledger's locked
section: the 16×20 dp cell, the Unit 16.5 fixed-chrome-by-mode rule and its
45%/35% map floors, the five-slot contextual action bar, the three-column
hero and combat panels, and the four-region rule's "action shelf = verbs"
(verbs now split between the bottom menu, the action card and the map
itself). Historical entries are not rewritten.

## Protected boundaries

- No change to `packages/core` or `packages/content` behaviour, save schema,
  RNG outcomes, map topology, field of view, encounter generation or balance.
  Every verb uses an existing core action. When a new availability (Wait
  while Watched, spells outside combat) meets a rules refusal, the rules
  decide.
- Timeline schedule and identity semantics, hidden-actor secrecy,
  `LogCategory` semantics, event ordering, follow/unread and causal text are
  unchanged.
- Determinism: no unseeded randomness; decoration stays hashed from
  coordinates and a fixed salt.
- Accessibility: nothing important carried by hue alone; no red-versus-green
  pair; every state also has a shape, mark or word.
- Type rule unchanged: `fontFamily` only in `lib/style/tokens.dart`, every
  style a token role.
- Town, world and roster screens are unchanged except for full-screen.
- No generated or semantically edited images. Shipped icons, the Material
  icon font and code-drawn shapes only.
- No widget golden tests.

## Out of scope

- The Hero screen's stats, inventory and equipment layout (Unit 16.7).
- A quest system, or any quest content.
- New consumables, spells, monsters or items.
- HP pips under monsters, minimaps, range paths.

## Acceptance

1. On the target phone, the map rectangle measures the same in exploration,
   Watched, battle and armed states.
2. The HUD's HP, mana and gold sit in the same place with the same content in
   all four states, and no wordmark appears.
3. The bottom menu shows `Quests`, `Spells`, `Quick`, `Hero` in that order
   in every state. Dimmed slots explain themselves when tapped. `Quests`
   shows the coming-soon notice.
4. Every verb the crawl offers today is still reachable: attack, move,
   auto-walk, inspect, cast, drink, wait, flee, pick up, mine, gather,
   ascend, descend, leave/done, move on, pack. Each is reached through the
   surface this contract names.
5. Spells: an untargeted spell casts outside combat; a targeted spell arms,
   shows reticles and casts on tap; refusals are visible.
6. Quick: drinking takes exactly two taps, in and out of combat.
7. While Watched in a dungeon, Wait is visible in the action card and ends
   the stall from the walkthrough (UXW-BAT 27–32) without special taps.
8. The action card appears exactly when one of its actions applies, sits on
   the map's bottom edge (top edge when the hero is there) with a leader line
   to the hero, never covers the hero or its neighbours, and leaves the rest
   of the map tappable. The log row holds only the log.
9. Turn-order strip and target card: no silent clipping with four or more
   actors; reach cannot be read as distance.
10. Map cells are about 24×30 dp. On the physical phone, the user taps each
    floor cell next to the hero with a finger and the hero steps there;
    taps on the void beyond the floor never step; distant taps auto-walk to
    the exact tapped cell. Drag to pan and recenter work on a depth-1 floor
    and a deepest floor.
11. No status or navigation bar in the crawl, town or world screens; nothing
    under the cut-out; the bottom menu works with gesture navigation.
12. Formatter, analyzer and the full app suite pass. New or changed
    availability rules have bloc tests; pop-ups, notices and full-screen
    have widget tests where a bloc test cannot observe them.
13. Device review on the vivo I2505 or I2219 (whichever is attached):
    colour-first, with user sign-off. User-owned save slots are backed up
    before any install and restored byte-identically afterwards; a phone
    that had no app before is returned to having none.

## Authorization boundary

Approval of this contract authorizes planning only. Implementation needs an
approved plan. Local commits need the plan's approval; push, pull request and
merge each need explicit user approval.
