import 'package:equatable/equatable.dart';

/// The four skills this milestone trains.
///
/// Learn-by-doing: there are no skill points to spend. Arms and Might come from
/// swinging one-handed and two-handed weapons, Bulwark from being hit in heavy
/// armour, Fleetfoot from being hit or dodging without any.
enum SkillId { arms, might, bulwark, fleetfoot }

/// The highest level any skill reaches.
const int maxSkillLevel = 100;

/// The experience it costs to leave [level] behind.
///
/// Strictly rising, so the twentieth level of a skill is a real investment and
/// the first is nearly free. Linear rather than exponential because the whole
/// curve has to be walkable inside a five-floor crawl: at one point per
/// trigger, reaching level five costs eighty hits, which is roughly a full
/// descent's worth of swinging.
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

/// All four skills, untouched. Every crawl starts here.
const Map<SkillId, SkillState> untrainedSkills = {
  SkillId.arms: SkillState(),
  SkillId.might: SkillState(),
  SkillId.bulwark: SkillState(),
  SkillId.fleetfoot: SkillState(),
};
