import 'package:equatable/equatable.dart';

/// The seven skills the game trains.
///
/// Learn-by-doing: there are no skill points to spend. Arms and Might come from
/// swinging one-handed and two-handed weapons, Bulwark from being hit in heavy
/// armour, Fleetfoot from being hit or dodging without any. Wrath, Mending and
/// Binding are the three spell schools, and each trains on one thing only — a
/// successful cast of a spell of that school, worth the same single point a
/// landed swing is worth.
///
/// **The three schools are appended, never inserted.** A save file writes its
/// skills block in the order of this enum, so a case slipped into the middle
/// would reorder the keys of every document ever written. The six skills the
/// design spec still owes — Marksmanship, Shieldcraft, Shadowing, Larceny,
/// Herbcraft, Blacksmith — stay out until the mechanics that train them exist:
/// a row the player can never move is a lie in the interface and dead weight in
/// every save.
enum SkillId { arms, might, bulwark, fleetfoot, wrath, mending, binding }

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

/// All seven skills, untouched. Every crawl starts here.
const Map<SkillId, SkillState> untrainedSkills = {
  SkillId.arms: SkillState(),
  SkillId.might: SkillState(),
  SkillId.bulwark: SkillState(),
  SkillId.fleetfoot: SkillState(),
  SkillId.wrath: SkillState(),
  SkillId.mending: SkillState(),
  SkillId.binding: SkillState(),
};
