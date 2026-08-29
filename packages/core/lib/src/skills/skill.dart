import 'package:equatable/equatable.dart';

/// The nine skills the game trains.
///
/// Learn-by-doing: there are no skill points to spend. Arms and Might come from
/// swinging one-handed and two-handed weapons, Bulwark from being hit in heavy
/// armour, Fleetfoot from being hit or dodging without any. Wrath, Mending and
/// Binding are the three spell schools, and each trains on one thing only — a
/// successful cast of a spell of that school, worth the same single point a
/// landed swing is worth. Herbcraft and Blacksmith are the two crafts:
/// Herbcraft from gathering a patch and from brewing, Blacksmith from mining a
/// vein, from smelting and from working a temper.
///
/// **Every addition is appended, never inserted.** A save file writes its skills
/// block in the order of this enum, so a case slipped into the middle would
/// reorder the keys of every document ever written. The four skills the design
/// spec still owes — Marksmanship, Shieldcraft, Shadowing, Larceny — stay out
/// until the mechanics that train them exist: a row the player can never move is
/// a lie in the interface and dead weight in every save.
enum SkillId {
  arms,
  might,
  bulwark,
  fleetfoot,
  wrath,
  mending,
  binding,
  herbcraft,
  blacksmith,
}

/// The highest level any skill reaches.
const int maxSkillLevel = 100;

/// The experience it costs to leave [level] behind.
///
/// Strictly rising, so the twentieth level of a skill is a real investment and
/// the first is nearly free. Linear rather than exponential because the whole
/// curve has to be walkable inside a five-floor crawl: at one point per
/// trigger, reaching level five costs forty hits — four, six, eight, ten and
/// twelve — which is roughly a full descent's worth of swinging.
int xpToNext(int level) => 4 + 2 * level;

/// How far one skill has come.
class SkillState extends Equatable {
  const SkillState({this.level = 0, this.xp = 0});

  final int level;

  /// Experience banked toward the next level, always below [xpToNext].
  final int xp;

  /// This skill after one more use of it.
  ///
  /// Surplus experience carries into the new level rather than being discarded,
  /// so a level-up never silently throws away a trigger. At [maxSkillLevel]
  /// training stops entirely: banking experience that can never be spent would
  /// leave the state growing forever for no visible effect.
  SkillState trained() {
    if (level >= maxSkillLevel) return this;
    final banked = xp + 1;
    final cost = xpToNext(level);
    if (banked < cost) return SkillState(level: level, xp: banked);
    return SkillState(level: level + 1, xp: banked - cost);
  }

  @override
  List<Object?> get props => [level, xp];

  @override
  String toString() => 'SkillState($level, $xp xp)';
}

/// All nine skills, untouched. Every crawl starts here.
const Map<SkillId, SkillState> untrainedSkills = {
  SkillId.arms: SkillState(),
  SkillId.might: SkillState(),
  SkillId.bulwark: SkillState(),
  SkillId.fleetfoot: SkillState(),
  SkillId.wrath: SkillState(),
  SkillId.mending: SkillState(),
  SkillId.binding: SkillState(),
  SkillId.herbcraft: SkillState(),
  SkillId.blacksmith: SkillState(),
};

/// [skills] after one more use of [skill].
///
/// **The whole of the learn-by-doing grant, in one place.** The dungeon trains
/// through `step`, which has an event list to announce a level-up on, and the
/// town trains through the forge and the alchemist, which have no events at all
/// — so the two callers differ in what they say and must not differ in what they
/// do. A missing skill counts as untrained rather than throwing, because a
/// fixture is allowed to carry a partial map and the rules are not allowed to
/// care.
Map<SkillId, SkillState> trainedIn(
  Map<SkillId, SkillState> skills,
  SkillId skill,
) => {...skills, skill: (skills[skill] ?? const SkillState()).trained()};
