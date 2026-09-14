# Unit 5 — Log Drawer: source recon

Verified at `0eb76d3` (`residuum-visual-reboot-4`, Unit 4 accepted). Read-only;
no production code was written. This is the WHAT-side evidence for the Unit 5
contract, not a plan.

## What the log is today

| Fact | Source | Consequence for Unit 5 |
| --- | --- | --- |
| History is `List<String>` | `game_bloc.dart:171` (`GameViewState.log`) | Sentences are already formatted when they reach the view. A drawer can ship without structured entries; anything richer (icons per line, tap-to-actor) needs a presentation entry type first. |
| Every view-only transition threads `log: state.log` unchanged; only `_act`, `_afterAction`, `_onAutoWalkAdvanced` append `presentation.lines` | `game_bloc.dart:602-918` | Exact history and causal order are already preserved. Unit 5 must not re-derive, re-sort, or truncate the list. |
| Refusals are appended as ordinary lines (`_watchedRefusal`, `_backRefusal`, `_roadBackRefusal`) | `game_bloc.dart:623,815` | The drawer shows refusals in the same stream. No separate channel. |
| `_MessageLog` is a fixed 104-logical-pixel `Container` with a `reverse: true` `ListView.builder`; newest line is `0xFFE6EAF0`, older lines `0xFF8A919E` | `game_screen.dart:682-706` | Roughly three lines already fit. The viewport is scrollable but has no handle, no follow state, and no expansion. The newest/older contrast is value-only, so it survives greyscale and should be kept. |
| `_MessageLog` renders **after** `_Controls` in the column | `game_screen.dart:120-121` | The mock puts the peek above the controls. Any reordering is a composition decision for the contract, not an accident to fix silently. |
| `describeEvent` receives the pre-step name map | `event_messages.dart`, via Unit 4's `eventNames` | Log sentences already carry `r¹`/`r²` identity. Unit 5 inherits identity-correct text and must not re-label. |

## What does not exist yet

- No drawer, overlay, or half/full state.
- No auto-follow state, no "scrolled away" detection, no `↓ N new` affordance
  or unread count.
- No structured log entry: no severity, no category, no actor reference, no
  timestamp.
- No tap-to-actor navigation. The handoff explicitly rules this out as a
  first-unit requirement (section 8.4).

## Inherited direction (handoff sections 8.1-8.4, 9.5)

- Peek stays about three lines at the phone target, fixed compact height,
  scrollable in place, newest last, with one clear expansion handle.
- Expansion is an **overlay**, never a reflow that permanently shrinks the
  dungeon: peek → half (about 40-50% height) → full.
- Auto-follow holds while the reader is at the newest entry, stops when they
  scroll up, accumulates without yanking the viewport, and offers `↓ N new`
  to return.
- The log owns causality; the map owns space, the timeline owns time, the shelf
  owns verbs. Do not duplicate any of those in the drawer.

## Traps for the contract

- The mock's expanded log draws a small icon per line. That implies a category
  on each entry, which the current `List<String>` cannot carry. Either the
  contract adds a structured presentation entry or it drops per-line icons for
  this unit. It must not infer a category by matching sentence text.
- Accessibility: any category treatment must be a shape or word, never hue
  alone, and the existing newest/older value contrast must survive greyscale.
- A road encounter builds a fresh `GameBloc`, so its log starts empty. The
  drawer must read naturally on a short history, not only on a long delve.
- The death overlay (`_DeathOverlay`) already covers the screen. Decide how an
  open drawer and that overlay interact rather than letting z-order decide.
