# 05 — Compact factual crawl status

Start: Task 04's accepted buildable atmospheric scene, same suitable feature checkout; approved `../CONTRACT.md`, `../PLAN.md` and four visual references. Own `packages/app/lib/game/crawl_status.dart`, `packages/app/test/widget/{crawl_status_test.dart,crawl_layout_test.dart}`; if a shared status-specific colour role is actually required, own only the new constant in `lib/style/tokens.dart`. Do not alter `game_screen.dart` allocation, other screens, shared `ResourceMeter`, gameplay facts or action row. Task 06 follows on this repository state.

## Locked decisions

- Bring top band toward restrained framed/mock hierarchy by wrapping the existing `_HeaderRow` and `_ResourceRow` together in one `panel`/`rule`/`hairline`/`radius` `DecoratedBox` inside the existing horizontal/vertical `CrawlStatus` padding. Do not add vertical padding, another text row, badge row, branding/menu or controls. Existing one-line location/battle/depth row then existing HP/mana meter row remain, with existing `rhythm` gap and bottom hairline. The frame changes value separation, not `CrawlStatus` height or the `Expanded` map allocation.
- Preserve `_placeName`, `_battleWord`, `_BattleGlyph`, `_condition` and `ResourceMeter` meaning/format/keys: road is `THE ROAD` with no depth, dungeon names and depth remain real, watched/engaged glyph + word/count never colour-only, HP condition remains, mana conditional on known spells, Ward note conditional on `warded > 0`. Keep `depthPairKey`, `hpMeterKey`, `manaMeterKey`. No mock-only health, gear, seed or status facts. Longest keep name and 1.3x text scale must not overflow or silently truncate a factual word.
- Worst legal target-device chrome must stay strictly <600dp. This task spends **zero new vertical dp** at the status seam; change only internal rule/border treatment if needed. The test-host `onAPhone` size is a proof of fit/order, never hardware chrome acceptance. Retain 36dp map cell.

## Red → Green and proof

1. First add a behavioral widget proof at `onAPhone`: real status contents are enclosed in one visible non-M3 panel and exploration/battle with the same facts keeps status height and map rectangle at/below the pre-change fixture; verify actual text/semantics, not the existence of a decorative widget alone. Red is the current unframed status. Retain existing cases for all three dungeons/road, watched vs engaged, hurt/dead, no mana, ward and worst-case intrinsic widths.
2. Apply only the frame/rebalance within old allocation. Confirm `CrawlStatus` preserves order above map, and `CrawlActionRow` remains bottom without changed action dispatch or number. No new placeholder well.
3. From `packages/app`: `flutter test test/widget/crawl_status_test.dart test/widget/crawl_layout_test.dart test/widget/crawl_action_row_test.dart`; `dart format <touched Dart paths>`; `flutter analyze`. Record Red/Green exits and measured test-host status/map rectangles. Main separately measures physical-device chrome on final tree.

## Executor discretion

Small colour/border choices from existing tokens, provided one factual band reads above map and no vertical height is gained. Avoid a new global theme or panel abstraction for one status widget.

## Escalate when

A frame cannot fit without losing a real fact or increasing worst-case height; text scale forces clipping/ellipsis; watched/engaged or road depth meaning must change; matching the reference would require fake facts or a new top control.

## Handoff receipt

Red failing case, focused Green/format/analyzer exits, previous/new test-host status/map rect, factual state cases including road and worst keep, changed files. Handoff is a framed factual status with no added chrome; Task 06 receives unchanged timeline APIs.
