import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// The hero a themed dungeon is measured against: a crypt graduate.
///
/// **A test fixture, not content.** Nothing in the game hands a hero this, and
/// nothing should: it stands for the state a player is plausibly in when they
/// first walk two days past Northgate, and the survivability bands only mean
/// anything against a stated starting point. A fresh hero measured in the keep
/// would report that the keep is impossible, which is true and says nothing
/// about whether it is well made.
///
/// Fine gear rather than Rare, because Fine is what the crypt actually gives up
/// at the depths a graduate cleared; four potions rather than two, because
/// shopping is the other thing the trip pays for; Arms, Might and Bulwark at
/// five and Fleetfoot at nothing, because the greedy build wears everything it
/// finds and heavy armour is what it finds most of.
///
/// **It lives here rather than in the survivability suite because two tests now
/// stand on it.** The bands measure how often this hero comes home, and the
/// designed-difficulty pin measures what the game can do to them — and the pin
/// derives its armour from this loadout rather than writing the number down, so
/// changing the kit reddens the pin instead of quietly rescaling it.
Profile survivabilityKit(int worldSeed) =>
    newProfile(worldSeed: worldSeed).copyWith(
      equipment: const {
        EquipSlot.mainHand: Item(
          id: 'kit-weapon',
          base: ironSword,
          rarity: Rarity.fine,
          affixes: [keen],
        ),
        EquipSlot.chest: Item(
          id: 'kit-chest',
          base: mailHauberk,
          rarity: Rarity.fine,
          affixes: [sturdy],
        ),
      },
      inventory: const [
        Item(id: 'kit-potion-1', base: healingPotion, rarity: Rarity.common),
        Item(id: 'kit-potion-2', base: healingPotion, rarity: Rarity.common),
        Item(id: 'kit-potion-3', base: healingPotion, rarity: Rarity.common),
        Item(id: 'kit-potion-4', base: healingPotion, rarity: Rarity.common),
      ],
      skills: const {
        SkillId.arms: SkillState(level: 5),
        SkillId.might: SkillState(level: 5),
        SkillId.bulwark: SkillState(level: 5),
        SkillId.fleetfoot: SkillState(),
      },
    );
