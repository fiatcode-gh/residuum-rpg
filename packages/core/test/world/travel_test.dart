import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/small_world.dart';

/// The danger every road of [smallWorld] carries, which is what `travelOneDay`
/// used to read off the route itself.
///
/// Named once rather than repeated, so the tests that are about *whether* a day
/// is a fight can go on being about the seed while the tests that are about the
/// number say so out loud.
const int _danger = 20;

/// A hero one road-day out of the home town, bound for the crypt.
Whereabouts _onTheRoad() {
  final (where, _) = beginTravel(atHome(), smallWorld(), crypt);
  return where;
}

/// Walks [days] days, ignoring what happens on them, so a test can reach a day
/// number without re-stating the loop.
Whereabouts _walk(Whereabouts from, int days, {int travelSeed = 1}) {
  var where = from;
  for (var walked = 0; walked < days; walked++) {
    where = travelOneDay(
      where,
      smallWorld(),
      travelSeed: travelSeed,
      travelerChance: 0,
      danger: _danger,
    ).whereabouts;
  }
  return where;
}

void main() {
  group('setting out', () {
    test('a road the hero has heard of is walked', () {
      // arrange
      final where = atHome();

      // act
      final (after, refusal) = beginTravel(where, smallWorld(), crypt);

      // assert
      expect(refusal, isNull);
      expect(after.isTravelling, isTrue);
      expect(after.journey!.to, crypt);
      expect(after.journey!.daysLeft, 1);
    });

    test('the road decides how long it takes, not the hero', () {
      // arrange
      final where = atHome().hearingOf(ridge);

      // act
      final (after, _) = beginTravel(where, smallWorld(), ridge);

      // assert
      expect(after.journey!.daysLeft, 2);
    });

    test('setting out spends no day at all', () {
      // arrange
      final where = atHome();

      // act
      final (after, _) = beginTravel(where, smallWorld(), crypt);

      // assert
      expect(after.day, where.day);
    });

    test('a place the hero has not heard of is refused', () {
      // arrange
      final where = atHome();

      // act
      final (after, refusal) = beginTravel(where, smallWorld(), ridge);

      // assert
      expect(refusal, isNotNull);
      expect(refusal!.reason, 'you have not heard of that place');
      expect(after, where);
    });

    test('a place with no road from here is refused', () {
      // arrange
      final map = WorldMap(
        nodes: [
          WorldNode(id: harbour, kind: NodeKind.town, name: 'Harbour'),
          WorldNode(id: crypt, kind: NodeKind.dungeon, name: 'The Crypt'),
          WorldNode(id: ridge, kind: NodeKind.town, name: 'Ridge'),
        ],
        routes: [
          Route(from: harbour, to: crypt, days: 1),
          Route(from: crypt, to: ridge, days: 1),
        ],
      );
      final where = Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {harbour, crypt, ridge},
      );

      // act
      final (after, refusal) = beginTravel(where, map, ridge);

      // assert
      expect(refusal!.reason, 'no road runs there from here');
      expect(after, where);
    });

    test('walking to where the hero already stands is refused', () {
      // arrange
      final where = atHome();

      // act
      final (after, refusal) = beginTravel(where, smallWorld(), harbour);

      // assert
      expect(refusal!.reason, 'you are already there');
      expect(after, where);
    });

    test('a hero already on a road cannot set out again', () {
      // arrange
      final where = _onTheRoad();

      // act
      final (after, refusal) = beginTravel(where, smallWorld(), ridge);

      // assert
      expect(refusal!.reason, 'you are already on the road');
      expect(after, where);
    });
  });

  group('a day on the road', () {
    test('the day counter goes up', () {
      // arrange
      final where = _onTheRoad();

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: 1,
        travelerChance: 0,
        danger: _danger,
      );

      // assert
      expect(walked.whereabouts.day, where.day + 1);
    });

    test('a hero standing still has no day to walk', () {
      // arrange
      final where = atHome();

      // act
      RoadDay walk() => travelOneDay(
        where,
        smallWorld(),
        travelSeed: 1,
        travelerChance: 0,
        danger: _danger,
      );

      // assert
      expect(walk, throwsStateError);
    });

    test('the last quiet day of a leg is an arrival', () {
      // arrange
      final where = _onTheRoad();

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: _quietSeedToTheCrypt,
        travelerChance: 0,
        danger: _danger,
      );

      // assert
      expect(walked.event, isA<QuietDay>());
      expect(walked.arrivedAt, crypt);
      expect(walked.whereabouts.at, crypt);
      expect(walked.whereabouts.isTravelling, isFalse);
    });

    test('arriving uncovers nothing the hero had not already heard of', () {
      // arrange
      final where = _onTheRoad();

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: _quietSeedToTheCrypt,
        travelerChance: 0,
        danger: _danger,
      );

      // assert
      expect(walked.whereabouts.discovered, where.discovered);
    });

    test('a day short of the end is not an arrival', () {
      // arrange
      final where = atHome().hearingOf(ridge);
      final (setOut, _) = beginTravel(where, smallWorld(), ridge);

      // act
      final walked = travelOneDay(
        setOut,
        smallWorld(),
        travelSeed: _quietSeedToRidge,
        travelerChance: 0,
        danger: _danger,
      );

      // assert
      expect(walked.arrivedAt, isNull);
      expect(walked.whereabouts.journey!.daysLeft, 1);
      expect(walked.whereabouts.at, harbour);
    });
  });

  group('what the road throws at the hero', () {
    test('a named world and day is a fight, every time it is asked', () {
      // arrange
      final where = _onTheRoad();

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: _dangerousSeedToTheCrypt,
        travelerChance: 0,
        danger: _danger,
      );

      // assert
      expect(walked.event, isA<DangerMet>());
    });

    test('a fight costs the day and none of the distance', () {
      // arrange
      final where = _onTheRoad();

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: _dangerousSeedToTheCrypt,
        travelerChance: 0,
        danger: _danger,
      );

      // assert
      expect(walked.whereabouts.day, where.day + 1);
      expect(walked.whereabouts.journey!.daysLeft, where.journey!.daysLeft);
      expect(walked.arrivedAt, isNull);
    });

    test('the fight is on the road the hero is actually walking', () {
      // arrange
      final where = _onTheRoad();

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: _dangerousSeedToTheCrypt,
        travelerChance: 0,
        danger: _danger,
      );

      // assert
      expect((walked.event as DangerMet).road.joins(harbour, crypt), isTrue);
    });

    test('a road nothing walks on is quiet whatever the day', () {
      // arrange
      final map = WorldMap(
        nodes: [
          WorldNode(id: harbour, kind: NodeKind.town, name: 'Harbour'),
          WorldNode(id: crypt, kind: NodeKind.dungeon, name: 'The Crypt'),
        ],
        routes: [Route(from: harbour, to: crypt, days: 40)],
      );
      final where = Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {harbour, crypt},
        journey: Journey(from: harbour, to: crypt, daysLeft: 40),
      );

      // act
      final events = <RoadEvent>[];
      var walking = where;
      for (var day = 0; day < 40; day++) {
        final walked = travelOneDay(
          walking,
          map,
          travelSeed: 12345,
          travelerChance: 0,
          danger: 0,
        );
        events.add(walked.event);
        walking = walked.whereabouts;
      }

      // assert
      expect(events, everyElement(isA<QuietDay>()));
    });

    test('the danger handed in decides, not the one written on the route', () {
      // arrange — the route the hero is on carries a danger of twenty, and the
      // day's roll is forty-five, so the route's own number would keep the day
      // quiet and the number handed in must be what makes it a fight
      final where = _onTheRoad();

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: _quietSeedToTheCrypt,
        travelerChance: 0,
        danger: 100,
      );

      // assert
      expect(walked.event, isA<DangerMet>());
    });

    test('a danger of nothing keeps a dangerous road quiet', () {
      // arrange
      final where = _onTheRoad();

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: _dangerousSeedToTheCrypt,
        travelerChance: 0,
        danger: 0,
      );

      // assert
      expect(walked.event, isNot(isA<DangerMet>()));
    });

    test('a traveler tells the hero of somewhere they had not heard of', () {
      // arrange
      final where = _onTheRoad();

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: _talkativeSeedToTheCrypt,
        travelerChance: 100,
        danger: _danger,
      );

      // assert
      expect(walked.event, isA<TravelerMet>());
      expect((walked.event as TravelerMet).told, ridge);
      expect(walked.whereabouts.discovered, contains(ridge));
    });

    test('walking somewhere leaves its neighbours for a traveler to name', () {
      // arrange
      final walkedIn = atHome().arrivingAt(smallWorld(), crypt);
      final setOut = Whereabouts(
        at: crypt,
        home: walkedIn.home,
        discovered: walkedIn.discovered,
        journey: Journey(from: crypt, to: harbour, daysLeft: 1),
      );

      // act
      final walked = travelOneDay(
        setOut,
        smallWorld(),
        travelSeed: _talkativeSeedToTheCrypt,
        travelerChance: 100,
        danger: _danger,
      );

      // assert
      expect(walked.event, isA<TravelerMet>());
      expect((walked.event as TravelerMet).told, ridge);
    });

    test('a traveler with nothing left to tell is just a quiet day', () {
      // arrange
      final where = Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {harbour, ridge, crypt},
        journey: Journey(from: harbour, to: crypt, daysLeft: 1),
      );

      // act
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: _talkativeSeedToTheCrypt,
        travelerChance: 100,
        danger: _danger,
      );

      // assert
      expect(walked.event, isA<QuietDay>());
    });
  });

  group('the road is a property of the world and the day', () {
    test('the same world and day decide the same way, asked twice', () {
      // arrange
      final where = _onTheRoad();

      // act
      final once = travelOneDay(
        where,
        smallWorld(),
        travelSeed: 4242,
        travelerChance: 25,
        danger: _danger,
      );
      final again = travelOneDay(
        where,
        smallWorld(),
        travelSeed: 4242,
        travelerChance: 25,
        danger: _danger,
      );

      // assert
      expect(once.event.runtimeType, again.event.runtimeType);
      expect(once.whereabouts, again.whereabouts);
    });

    test('a relaunch cannot re-roll a day it already walked', () {
      // arrange
      final where = _onTheRoad();
      final walked = travelOneDay(
        where,
        smallWorld(),
        travelSeed: 4242,
        travelerChance: 25,
        danger: _danger,
      );

      // act
      final reloaded = travelOneDay(
        Whereabouts(
          at: where.at,
          home: where.home,
          discovered: where.discovered,
          day: where.day,
          journey: where.journey,
        ),
        smallWorld(),
        travelSeed: 4242,
        travelerChance: 25,
        danger: _danger,
      );

      // assert
      expect(reloaded.whereabouts, walked.whereabouts);
      expect(reloaded.event.runtimeType, walked.event.runtimeType);
    });

    test('two different days of one world are decided apart', () {
      // arrange
      final map = WorldMap(
        nodes: [
          WorldNode(id: harbour, kind: NodeKind.town, name: 'Harbour'),
          WorldNode(id: crypt, kind: NodeKind.dungeon, name: 'The Crypt'),
        ],
        routes: [Route(from: harbour, to: crypt, days: 60, danger: 50)],
      );

      // act
      final seen = <String>{};
      var walking = Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {harbour, crypt},
        journey: Journey(from: harbour, to: crypt, daysLeft: 60),
      );
      for (var day = 0; day < 60; day++) {
        final walked = travelOneDay(
          walking,
          map,
          travelSeed: 777,
          travelerChance: 0,
          danger: _danger,
        );
        seen.add(walked.event.runtimeType.toString());
        walking = walked.whereabouts;
      }

      // assert
      expect(seen, hasLength(greaterThan(1)));
    });

    test('two worlds do not share a road', () {
      // arrange
      final where = _onTheRoad();

      // act
      final events = {
        for (var seed = 0; seed < 60; seed++)
          seed: travelOneDay(
            where,
            smallWorld(),
            travelSeed: seed,
            travelerChance: 0,
            danger: _danger,
          ).event.runtimeType.toString(),
      };

      // assert
      expect(events.values.toSet(), hasLength(greaterThan(1)));
    });

    test('the day walked is the day rolled, not the day left behind', () {
      // arrange
      final map = WorldMap(
        nodes: [
          WorldNode(id: harbour, kind: NodeKind.town, name: 'Harbour'),
          WorldNode(id: crypt, kind: NodeKind.dungeon, name: 'The Crypt'),
        ],
        routes: [Route(from: harbour, to: crypt, days: 9, danger: 50)],
      );
      final start = Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {harbour, crypt},
        journey: Journey(from: harbour, to: crypt, daysLeft: 9),
      );

      // act
      final first = travelOneDay(
        start,
        map,
        travelSeed: 31,
        travelerChance: 0,
        danger: _danger,
      );
      final laterStart = start.onDay(5, journey: start.journey);
      final later = travelOneDay(
        laterStart,
        map,
        travelSeed: 31,
        travelerChance: 0,
        danger: _danger,
      );

      // assert
      expect(first.whereabouts.day, 1);
      expect(later.whereabouts.day, 6);
      expect(roadSeed(31, 1), isNot(roadSeed(31, 6)));
    });
  });

  group('walking to the second town and back', () {
    test('the day counter carries across legs', () {
      // arrange
      final where = atHome().hearingOf(ridge);
      final (setOut, _) = beginTravel(where, smallWorld(), ridge);

      // act
      final after = _walk(setOut, 2, travelSeed: _quietSeedToRidge);

      // assert
      expect(after.day, 2);
      expect(after.at, ridge);
      expect(after.home, ridge);
    });
  });
}

/// A world whose first day on the Harbour-to-crypt road passes quietly.
///
/// Found by sweeping the shipped derivation rather than chosen: on day one of
/// world 3 the danger roll is 45, which clears the road's danger of 20. Every
/// seed below names a real answer read off `roadSeed`, so a change to the
/// derivation reddens these rather than sliding under them.
const int _quietSeedToTheCrypt = 3;

/// A world whose first day on that road is a fight: the roll is 15 against 20.
const int _dangerousSeedToTheCrypt = 5;

/// A world whose first day on that road meets somebody worth listening to.
///
/// The same world as [_quietSeedToTheCrypt] on purpose: day one of world 3
/// rolls 45 for danger and then 15 for company, so the one seed shows both that
/// a quiet road stays quiet at a traveler chance of nothing and that the very
/// same day is a meeting once the roads have people on them.
const int _talkativeSeedToTheCrypt = 3;

/// A world whose first two days on the Harbour-to-Ridge road pass quietly.
const int _quietSeedToRidge = 2;
