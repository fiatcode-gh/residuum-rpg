import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'travel_messages.dart';

sealed class WorldBlocEvent {
  const WorldBlocEvent();
}

/// The player picked somewhere to walk to.
final class TravelRequested extends WorldBlocEvent {
  const TravelRequested(this.destination);

  final NodeId destination;
}

/// The player wants a journey already in progress to carry on.
///
/// **A press rather than something that happens by itself**, and the case that
/// needs it is a launch: a hero killed by the task switcher mid-journey comes
/// back standing on the road, and nothing is walking them. Continuing
/// automatically would spend days the moment the app opened, which is the one
/// thing the confirmation before setting out exists to prevent. The road is not
/// free, so every day on it is asked for.
final class TravelResumed extends WorldBlocEvent {
  const TravelResumed();
}

/// One day of the journey in progress. Carries the [walkId] it belongs to so a
/// day left over from an interrupted journey cannot resume it.
final class DayWalked extends WorldBlocEvent {
  const DayWalked(this.walkId);

  final int walkId;
}

/// A road fight is over, one way or another.
final class RoadFightOver extends WorldBlocEvent {
  const RoadFightOver(this.ending);

  final EncounterEnding ending;
}

/// The hero was told something at a tavern.
///
/// Carries the whole of what core answered, so this bloc takes the half that is
/// its own — the map the hero now knows — and the town takes the half that is
/// its own. Neither works out the other's.
final class RumorHeard extends WorldBlocEvent {
  const RumorHeard(this.told);

  final Rumored told;
}

/// How a road fight finished.
///
/// Three endings, because three things can end one and they are not the same:
/// walking off the edge leaves the journey where it was, killing everything
/// lets it carry on, and dying ends it at the hero's own front door.
enum EncounterEnding { fled, cleared, died }

class WorldViewState {
  const WorldViewState({
    required this.world,
    this.log = const [],
    this.notice,
    this.fight,
    this.walkId = 0,
    this.walking = false,
  });

  /// Where the hero is, what day it is, and what they have uncovered.
  final Whereabouts world;

  /// The travel log, oldest first. View state: it drops when the app does,
  /// exactly as the crawl's log does.
  final List<String> log;

  /// The last refusal, for the screen to read out.
  final String? notice;

  /// A road fight to open right now, or null when there is none.
  ///
  /// An instruction rather than a fact, following the town's `run`: the session
  /// reads it once, pushes the fight, and nothing here looks at it again. It is
  /// never written to disk — a fight is re-derived from the world and the day,
  /// so there is nothing about one worth keeping.
  final DangerMet? fight;

  /// Bumped whenever a journey starts, stops or is interrupted.
  final int walkId;

  /// Whether a journey is being advanced day by day right now.
  final bool walking;

  bool get isTravelling => world.isTravelling;

  /// Where the hero is standing, or the node they set out from.
  NodeId get at => world.at;

  /// Everywhere the hero could set out for from here, in the map's own order.
  List<WorldNode> destinationsFrom(WorldMap map) => [
    for (final node in map.nodes)
      if (node.id != world.at &&
          world.discovered.contains(node.id) &&
          map.routeBetween(world.at, node.id) != null)
        node,
  ];

  /// What the tavern here would tell the hero, or null when it has nothing left.
  Rumor? rumorOnOffer(List<Rumor> pool) {
    for (final rumor in pool) {
      if (!world.discovered.contains(rumor.reveals)) return rumor;
    }
    return null;
  }
}

/// Owns where the hero is in the world, and every day they spend walking.
///
/// **It does not own the hero.** Gold, gear, hit points and the pack live in the
/// town bloc, which is the single home of a [Profile]; this is the single home
/// of a [Whereabouts]. The two meet at exactly the places one transaction moves
/// both — a rumor bought with coin, and a fight that ends with a hero coming
/// home — and at those places core answers with both halves and the caller hands
/// each to its owner. Neither bloc works out the other's business.
///
/// [worldSeed] is a constructor value rather than read off the profile, because
/// a session is one hero and a hero's world never changes. Nothing here can fall
/// out of step with the profile, because nothing here reads it.
class WorldBloc extends Bloc<WorldBlocEvent, WorldViewState> {
  WorldBloc({
    required Whereabouts world,
    required this.worldSeed,
    WorldMap? map,
    this.dayDelay = const Duration(milliseconds: 450),
  }) : map = map ?? residuumWorld,
       super(WorldViewState(world: world)) {
    on<TravelRequested>(_onTravelRequested);
    on<DayWalked>(_onDayWalked);
    on<TravelResumed>(_onTravelResumed);
    on<RoadFightOver>(_onRoadFightOver);
    on<RumorHeard>(_onRumorHeard);
  }

  /// The seed every road on this hero's world derives from.
  final int worldSeed;

  /// The world being walked. A parameter so a test can walk a smaller one.
  final WorldMap map;

  /// How long the screen holds each day before the next. Zero in tests.
  final Duration dayDelay;

  /// Sets out, or says why not.
  ///
  /// The refusal comes straight from core, so the sentence the player reads is
  /// the rule's own words rather than a second set written up here that could
  /// drift from it.
  void _onTravelRequested(TravelRequested event, Emitter<WorldViewState> emit) {
    final (after, refusal) = beginTravel(state.world, map, event.destination);
    if (refusal != null) {
      emit(
        WorldViewState(
          world: state.world,
          log: state.log,
          notice: refusal.reason,
          walkId: state.walkId,
        ),
      );
      return;
    }
    final walkId = state.walkId + 1;
    emit(
      WorldViewState(
        world: after,
        log: [...state.log, describeSettingOut(map, after.journey!)],
        walkId: walkId,
        walking: true,
      ),
    );
    add(DayWalked(walkId));
  }

  /// Picks a journey back up where a launch or a fight left it.
  ///
  /// Silent when the hero is not on a road, because then the control offering
  /// this is not on screen and the event is a press nobody made.
  void _onTravelResumed(TravelResumed event, Emitter<WorldViewState> emit) {
    if (!state.isTravelling || state.walking) return;
    final walkId = state.walkId + 1;
    emit(
      WorldViewState(
        world: state.world,
        log: state.log,
        walkId: walkId,
        walking: true,
      ),
    );
    add(DayWalked(walkId));
  }

  /// Walks one day, and keeps walking unless something stopped the journey.
  ///
  /// **A fight stops the walk rather than queueing behind it.** The day that met
  /// something is the last day walked until the fight is over, because the fight
  /// is what the player has to answer and the days behind it would otherwise
  /// resolve while a screen was open over them.
  Future<void> _onDayWalked(
    DayWalked event,
    Emitter<WorldViewState> emit,
  ) async {
    if (event.walkId != state.walkId || !state.isTravelling) return;
    final walked = travelOneDay(
      state.world,
      map,
      travelSeed: travelSeedFor(worldSeed),
      travelerChance: travelerChance,
    );
    final line = describeRoadDay(walked, map);
    if (walked.event case final DangerMet met) {
      emit(
        WorldViewState(
          world: walked.whereabouts,
          log: [...state.log, line],
          fight: met,
          walkId: state.walkId,
        ),
      );
      return;
    }
    emit(
      WorldViewState(
        world: walked.whereabouts,
        log: [...state.log, line],
        walkId: state.walkId,
        walking: walked.whereabouts.isTravelling,
      ),
    );
    if (!walked.whereabouts.isTravelling) return;
    await Future<void>.delayed(dayDelay);
    if (isClosed || state.walkId != event.walkId) return;
    add(DayWalked(event.walkId));
  }

  /// Picks the journey back up, or ends it at the hero's own front door.
  ///
  /// Fleeing and clearing both leave the hero exactly where the road left them —
  /// the fight cost the day and none of the distance — so the walk carries on
  /// from the same leg. Dying is the one ending that moves them: they wake at
  /// [Whereabouts.home], off any road, with the journey abandoned.
  ///
  /// **The camp is not touched.** A hero who was killed on the road did not die
  /// in their crawl, and the dungeon standing at the crypt with their name on it
  /// is dungeon progress rather than carried goods. `endRun` brings the unbumped
  /// visit home with everything else, so a camp stays resumable.
  void _onRoadFightOver(RoadFightOver event, Emitter<WorldViewState> emit) {
    if (event.ending == EncounterEnding.died) {
      emit(
        WorldViewState(
          world: state.world.arrivingAt(map, state.world.home),
          log: [...state.log, describeWakingAtHome(map, state.world.home)],
          walkId: state.walkId + 1,
        ),
      );
      return;
    }
    final walkId = state.walkId + 1;
    final told = event.ending == EncounterEnding.fled
        ? fledOnTheRoad
        : wonOnTheRoad;
    emit(
      WorldViewState(
        world: state.world,
        log: [...state.log, told],
        walkId: walkId,
        walking: state.isTravelling,
      ),
    );
    if (!state.isTravelling) return;
    add(DayWalked(walkId));
  }

  /// Takes the half of a tavern purchase that belongs to the world.
  ///
  /// A refused purchase and a tavern with nothing left to say both leave the map
  /// alone; only a rumor actually told widens it. The gold is the town's half and
  /// is not looked at here.
  void _onRumorHeard(RumorHeard event, Emitter<WorldViewState> emit) => emit(
    WorldViewState(
      world: event.told.whereabouts,
      log: [
        ...state.log,
        if (event.told.rumor case final Rumor heard) heard.line,
      ],
      notice: event.told.refusal?.reason,
      walkId: state.walkId,
      walking: state.walking,
    ),
  );
}
