# Unit 7 — Town, Transactional Rooms, and Heroes Contract

Status: **draft for user approval; planning and implementation are separate
authorization steps.**

## Outcome

Bring every non-dungeon town surface onto the reboot's presentation grammar.
Today the town shell, the six transactional rooms, and the Heroes roster are
still original M3-era composition (`TownRoom` + `town_style.dart`: monospace
rows, uniform full-width buttons, stacked panels). Units 1–6 rebooted the crawl
and the Character/Gear/Spells/Skills/Pack information architecture only.

After this unit:

- **Stonebridge/Northgate** reads as a place with a header, a compact hero
  status, and destination rows that say what each door is for.
- **Merchant, Bank, Inn, Tavern, Forge, Alchemist** keep every current
  transaction, price, count, and refusal sentence, presented with the reboot's
  quieter hierarchy instead of heavy uniform card furniture.
- **Heroes** presents roster state — who is playing, where each hero stands,
  what they carry — and keeps switching, creation, and confirmed irreversible
  deletion exactly as they behave now.

The unit changes presentation and composition only. Every rule, price, count,
refusal, save shape, and navigation semantic stays as source defines it today.

## Locked product decisions

### No static art, no asset pipeline, in this unit

Sequencing was already settled with the user: the art pass is planned after
Unit 8, and no asset unit is interleaved. Therefore the "atmospheric
Stonebridge header" and room atmosphere of handoff sections 9.1/9.9/9.10 are
delivered here as **typographic and procedural treatment only** — type scale,
rules, spacing, value contrast, and at most Canvas-drawn ornament consistent
with the dungeon's deterministic material language.

`packages/app` gains no `assets/` declaration, no image file, and no
portrait slot. Portrait framing, room-background aspect ratios, bulk
static-art composition, and the full icon-stroke language stay deferred to the
post-Unit-8 art bible. This unit must not force any of those decisions.

Marks stay text codepoints. Any new mark codepoint must be read on device
before acceptance (Unit 5 trap: `↕` U+2195 resolved to a colour emoji on
Android and no widget test can see it; U+2B65 is tofu on this target).

### Town shell: header, status, purposeful doors

The town screen keeps its current job — a menu, not a walkable scene — and
keeps **exactly the seven existing doors in their current order**: Merchant,
Bank, Inn, Character, Tavern, Forge, Alchemist. No door is added, removed,
renamed, reordered, or grouped behind a submenu.

Each door gains a short purpose line drawn from what the room actually does in
source. The compact status keeps health, carried gold, banked gold, the
descents sentence, gathered materials, and the notice. The last door must stay
reachable on a 600-pixel-tall phone; the screen scrolls rather than clips.

The way out of town stays the back button, and dungeon entry stays at the
dungeon's own world node. This unit does not move either.

### Heroes stays a world action, rebooted in place

Recon correction 9 stands: Heroes is a `WorldScreen` action, not a town door.
This unit reboots `RosterScreen`'s presentation and leaves its entry point,
its `RosterChoice` (`PlayHero` / `MakeHero` / `DropHero`) pop protocol, and
`main.dart`'s session-rebuild handling untouched. Placing the Heroes entry
point is Unit 8's world work.

Roster behavior that must survive verbatim: the screen reads the live
`SaveDocument` (not a bloc), every hero row states health, carried gold,
banked gold, visit count, and where that hero is standing; the played hero
carries the word `playing`; creation offers a prefilled name and falls back to
the offered label when blank; deletion is confirmed, warns when that hero has a
living crawl, and deleting the last hero is the replacement write that keeps
the roster non-empty.

### Transactional grammar is preserved sentence for sentence

Refusal prose is product behavior, not decoration. Every refusal, reason, and
explanatory sentence currently shown keeps its exact wording and keeps
appearing in the same situation:

- the inn always says why the bed is unavailable or what it does, including
  the short-purse arithmetic;
- the forge shows `smeltReason`, per-item `temperReason`, and the next-tier
  ingot cost; the alchemist shows `brewReason`;
- the alchemist's batch-loss sentence still wins the notice slot over a
  level-up sentence;
- the merchant still says `you cannot afford this`, keeps Buy / Sell / Buy back
  with stacked rows and explicit prices, and buy-back still refunds at the sell
  price;
- the bank keeps `Your purse does not have it.` / `Your vault does not have
  it.`, its carried-versus-safe two-zone reading, and its counted gold dials;
- the tavern keeps the rumor purchase that debits through core and speaks
  through either bloc, both its headings, the last six world log lines, and its
  "nothing left to tell you" line.

Dead controls stay dead and visible: a control that cannot act is dimmed beside
its reason, never removed. `CountStepper` keeps its dead edges and its
tap-and-hold auto-repeat.

### One town grammar, not seven

`town_style.dart` is the single presentation source for the town. Rebooted
composition is extracted there (headings, rows, panels, notice, stepper, room
scaffold) and reused; no room may grow a private second grammar for the same
concept. `PackContents`, `ItemRow`, `MaterialRows`, `Purse`, `Notice`,
`SpellRow`, and item presentation remain single sources of truth shared with
the Unit 6 routes and the crawl Pack.

## Boundaries and invariants

1. `packages/core` and `packages/content` remain untouched. No rule, price,
   band, recipe, refusal string owned by core, item id, save version, or save
   document shape changes.
2. `TownBloc`'s 23 events, `TownViewState`'s fields and computed reasons,
   `WorldBloc`'s rumor seam, and `main.dart`'s session/roster handling keep
   their current meaning. A widget may re-compose what it shows; it may not
   compute a game fact or invent an action.
3. Every existing transaction remains reachable in the same room with the same
   outcome: buy, sell, buy back, bank/take gold, bank/take item, rest, ask for
   a rumor, smelt, temper, brew, wear, read, take off.
4. Notice precedence, merchant visit carry-over, camp/overrun handling, and
   save-write failure reporting behave as they do today.
5. Accessibility is non-negotiable: state, category, and rarity read by mark,
   word, number, or position. Nothing new is hue-only, and every rebooted
   screen reads in greyscale. Mark alignment stays column-based, not
   space-padded (the device monospace widths differ).
6. No behavior is hidden behind a compatibility shim. Replaced composition is
   deleted, not left beside the new one.

## Explicit non-goals

- No static art, image asset, portrait, asset pipeline, or icon-family work.
- No world map, travel, route, discovery, or Heroes-entry-point redesign
  (Unit 8).
- No crawl, Flame, timeline, log drawer, shelf, targeting, or HUD-chrome work.
- No new room, currency, action, price, recipe, stacking rule, or sorting rule.
- No rewording of a refusal, price, or explanatory sentence.
- No generic "room framework" abstraction beyond what the six rooms already
  share.

## Acceptance criteria

1. The town screen shows a town header, compact hero status (health, carried
   gold, banked gold, descents sentence, materials, notice) and the same seven
   doors in the same order, each with a source-true purpose line; the last door
   is reachable on a 600-pixel-tall screen.
2. Merchant keeps Buy / Sell / Buy back with stacked rows, explicit prices,
   purse, buy-back at sell price, and the unaffordable refusal on a dead
   control.
3. Bank keeps two-zone carried-versus-safe reading for items and gold, counted
   dials with dead edges, and both short-purse/short-vault sentences.
4. Inn keeps price, health, the rest control, and a sentence in all three
   states (nothing wrong, short purse with arithmetic, success).
5. Tavern keeps the rumor purchase through core, both headings, the last six
   world log lines, the exhausted-rumors line, and notices from either bloc.
6. Forge keeps the smelting ratio line, the counted dial, worn-versus-carried
   steel sections, per-item temper reasons, next-tier cost, and the blacksmith
   level-up sentence.
7. Alchemist keeps the brewing ratio line, the counted dial, the brew refusal,
   and batch-loss precedence over the level-up sentence.
8. Heroes shows every hero with health, carried gold, banked gold, visits, and
   location; marks the played hero with the word `playing`; keeps prefilled
   creation, confirmed deletion with the living-crawl warning, the never-empty
   roster, and the existing `RosterChoice` protocol.
9. No hue-only distinction exists on any rebooted screen, and every screen
   reads in greyscale.
10. Touched-file `dart format`, `flutter analyze`, and the full `flutter test`
    suite pass from `packages/app`. Widget/bloc tests cover each room's
    preserved transaction and refusal surface; existing town tests either pass
    unchanged or are updated only where they pinned composition rather than
    behavior.
11. Device evidence on the current AVD shows the town shell, all six rooms, and
    Heroes in normal colour and greyscale, proves every new mark codepoint
    renders as text (not colour emoji, not tofu), and both device save slots are
    backed up before install and verified byte-identical afterwards.

## Verification and review disposition

- **COR:** run — the unit rewrites the only visible path to every town
  transaction; a silently dropped refusal or control is the primary risk.
- **TTC:** run — refusal visibility, notice precedence, dead-control
  behavior, and roster protocol are behavioral contracts.
- **CRF:** run — the unit must consolidate one town grammar without inventing a
  room framework.
- **SEC:** skip — local Flutter presentation over existing state; no new
  external boundary.
