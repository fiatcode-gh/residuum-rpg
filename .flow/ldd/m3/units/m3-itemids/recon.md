# m3-itemids recon — 2026-09-03

Architect recon, story M3I. Sources read at line level this session; two
read-only Explore sweeps (id mints/consumers; codec/boundaries) verified
against source before use. The live confirmation (V10, worn-test on the
user's phone) is in D97.

## The defect (confirmed)

Item ids minted per-run collide across delves because the pack rides the
Profile and persists. Three mint families share the defect:

| Family | Format | Mint site | Collision shape |
|---|---|---|---|
| drops | `drop-<n>` | `engine/step.dart:578`, counter `GameState.nextDropNumber` (default 1, `game_state.dart:64`) | every `startRun` / `startRoadEncounter` restarts at 1 |
| floor litter | `floor-<depth>-<n>` | `content/new_game.dart:96`, `content/dungeons.dart:329` | no visit component — delve 2's floor-3 litter collides with delve 1's picked-up floor-3 item |
| boss trophy | `trophy-<node>` | `content/dungeons.dart:334` | constant per node — a second delve's trophy collides with the first's |

Non-colliding mints: `brew-<n>` (Profile.brewNumber — never resets, THE
precedent), `kit-1..3` (constants), `market-<town>-<visit>-<slot>-<n>`
(`content/economy.dart:189-195`, visit-scoped, prefix-unique).

## Consumer semantics (all verified)

Remove-ALL (destructive on duplicates): `town.dart:358 _without` (behind
sell/deposit/withdraw/readBook), `town.dart:255-280 temperItem` rebuild,
`wear.dart:110-112 wear`, `step.dart:130/139/168` Drink/Read/Drop,
`town_bloc.dart:823 _without` (stock). First-match find everywhere:
`town.dart:352 _find`, `wear.dart:41`, `magic/read.dart:44`,
`temper.dart:114-122 heldItem`. Remove-ONE exists only at
`step.dart:109-112` PickUpAction (per-tile `removeLast`). No `Set<Item>`
or `Map<String,Item>` anywhere (grep-verified). `Item` is Equatable with
`affixes` List in props (follow-up 18 hazard, unchanged by this unit).

## Codec + boundaries (verified)

- Omit-on-default precedent to copy: `actor_codec.dart:66` encode
  `if (actor.reach != 1) 'reach': ...` / `:118` decode
  `containsKey ? intAt : 1` — "an unconditional encode would rewrite
  every golden document".
- `brewNumber` encodes unconditionally (`profile_codec.dart:37`) and
  decodes REQUIRED (`:79` — absent refuses the save). Do NOT copy that
  for the new field.
- Run codec: `nextDropNumber` unconditional encode (`run_codec.dart:39`),
  required decode (`:146`), round-trips suspend/resume;
  `resumeRun:244` passes it verbatim, no reconciliation exists.
- Boundaries hand-copy field-by-field: `startRun` (~50-71, does NOT pass
  nextDropNumber), `endRun`/death (~100-120, copyWith), `suspendRun`
  (~158-166), `resumeRun` (180-245), `startRoadEncounter`
  (`content/world.dart:399-441`) — whose dartdoc is the standing order:
  "A field the profile gains later goes on this list the day it lands."
- Goldens: `content/test/save/golden_save_test.dart` pins three documents
  bytewise; `profile_codec_test.dart:113-117` pins the encoded key set;
  refusal fixtures live in `version_gate_test.dart` (own-commit-first
  convention). This unit adds NO refusal (new field decodes absent-as-1),
  so no fixture commit — but the run golden pins must be argued: with
  omit-on-default on BOTH codecs, every golden stays byte-identical.

## What the recon did not check

Test-file semantics beyond corroboration; app save/boot write paths
(`packages/app/lib/save/`); git history of the refusal-fixture commit;
`item_codec.dart`/`craft_codec.dart` internals beyond the quoted lines;
Profile construction sites outside `new_game.dart`.