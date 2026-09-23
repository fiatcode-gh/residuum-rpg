# Roadmap Supersession — post-U15

The U13 roadmap was correct for the visual direction known on 2026-09-18.

The user has now approved a material dungeon-direction pivot.

## Superseded old sequence

The old immediate next unit:

- U16 — Authored icon and art families

is **deferred and loses the U16 number**.

Likewise, the old dungeon sequence:

- U18 — Dungeon light and stone value
- U19 — Dungeon structure and props
- U20 — Actor representation
- U21 — Combat chrome density

must not be executed as written.

Why:

- U19's structural dungeon asset kit is no longer the chosen dungeon language.
- U20's creature-art layer is no longer required; actors remain ASCII glyph identities.
- U18 lighting and U21 chrome still matter, but they now belong inside the new ASCII-main-screen parity slice rather than on top of textured terrain.

## New immediate route

**U16 — ASCII Atmospheric Crawl Parity**

U16 absorbs/reframes:

- old U18's lighting/value responsibility;
- old U21's crawl-density/main-screen parity responsibility;
- the terrain side of old U19 as pure ASCII rather than structural assets;
- the actor side of old U20 as refined glyph presentation rather than creature sprites.

## Deferred asset work

Authored asset generation remains useful for non-dungeon UI:

- room/navigation medallions;
- spell/item icons;
- log pictograms;
- hero portrait;
- other exact consumer slots that survive U16.

Those assets should be re-numbered/re-cut **after U16 acceptance**, because U16 may change main-screen consumer geometry.

Use `flow-assets` only after those consumers are real and stable.

## Existing environment art

Stonebridge / Forge / Tavern illustrations remain valid and are outside this pivot.

## Roadmap discipline

Do not mechanically renumber old U17–U21 now.

After U16 device acceptance, perform a small roadmap reconciliation based on what remains visibly far from the approved UI/town mocks and which placeholder consumers now exist.
