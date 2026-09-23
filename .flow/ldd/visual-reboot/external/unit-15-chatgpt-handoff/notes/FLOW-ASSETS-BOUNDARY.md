# U15 ↔ flow-assets Boundary

## Purpose

U15 is the last layout/consumer-definition unit before U16's authored icon/art family work.

The `flow-assets` doctrine applies here as a **future-consumer contract**, not as generation work.

## U15 must do

For every new art host introduced by the shared row/control grammar, leave enough real production information that U16 can derive an asset contract from the consumer:

- owning widget/component;
- exact rendered envelope on target device;
- shape: circular/square/rectangular;
- internal padding and safe area;
- alignment;
- transparent-background expectation;
- whether the image is untinted;
- scaling/filtering behavior;
- accessibility/fallback behavior when art is absent;
- surrounding type styles and surface values;
- greyscale/context evidence.

Prefer constants or directly queryable layout facts over prose-only dimensions.

## U15 must not do

- no image generation;
- no semantic image editing;
- no speculative production icon pack;
- no placeholder promoted as final art;
- no asset-family naming that contradicts existing `art_assets.dart` conventions without local recon;
- no layout that depends on the yet-unknown visual mass of U16 art.

## U16 handoff expectation

After U15, U16 can create bundles such as:

`.flow/assets/<asset-id>/ASSET.md`

using the actual consumer.

U16 should use `flow-assets` GENERATE/EDIT/CONFORM as appropriate and accept promoted candidates in-context.

## Later units

The same rule applies to:

- U19 dungeon stairs/doors/props;
- U20 creature art;
- U17 hero portrait if newly authored rather than reused.

Generate late from the real renderer/widget consumer.
