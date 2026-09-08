import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'town_bloc.dart';
import 'town_style.dart';

/// Why a Bank commit is dead.
///
/// Under the row rather than on the button, and only when the side is empty —
/// an empty purse cannot bank anything, and the dial that cannot move is the
/// control that says so.
const String purseIsShort = 'Your purse does not have it.';

/// Why a Take commit is dead.
const String vaultIsShort = 'Your vault does not have it.';

/// The vault: what death can reach above, what it cannot below.
///
/// Carried always sits above banked, on this screen and on the town menu, so
/// the position of a row says which side of the death penalty it is on.
///
/// **The gold moves by dial, by ruling, not by argument.** The fixed buttons
/// stood on an argument — three taps of a number pad versus one button that
/// already said it — and the dial retires that argument BY USER RULING, not by
/// refuting it: counted work got a dial everywhere else in the town, so the
/// bank got two. What the old argument was defending survives in the cap
/// clamp, and that is the honest thing the new dartdoc can say: the dial never
/// offers past what the purse or the vault actually holds, and its commit
/// always says exactly what it will move — one press, the whole dial, the
/// existing core transaction called once with the amount.
///
/// **The item rows are never dead, and the gold commits are.** Banking and
/// taking out an item always work — the pack cap refuses in a notice when it
/// has to — while an empty purse or vault leaves its dial at zero with its
/// sentence beside it, which is the inn's rule: a dead control with its reason
/// beside it, never vanishing.
class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

/// The two pending gold counts, one per side.
///
/// **View state, not game state** — dials, things the player is about to do,
/// held by the screen that drew them. They die with the screen and re-clamp
/// whenever the state changes: a purchase that shrinks the purse pulls the
/// bank dial down with it. Committing calls `depositGold`/`withdrawGold` once
/// with the dialed amount — the core already takes an amount, and a clamped
/// dial can never refuse.
class _BankScreenState extends State<BankScreen> {
  int _pendingBank = 0;
  int _pendingTake = 0;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) {
        final pendingBank = _pendingBank.clamp(0, state.gold);
        final pendingTake = _pendingTake.clamp(0, state.bankedGold);
        return TownRoom(
          title: 'Bank',
          children: [
            Purse(carried: state.gold, banked: state.bankedGold),
            Notice(state.notice),
            const Heading('Gold'),
            CountStepper(
              value: pendingBank,
              cap: state.gold,
              onChanged: (next) => setState(() => _pendingBank = next),
            ),
            FilledButton(
              onPressed: pendingBank <= 0
                  ? null
                  : () {
                      bloc.add(DepositGoldPressed(pendingBank));
                      setState(() => _pendingBank = 0);
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Bank gold',
                style: TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
            if (state.gold <= 0) Text(purseIsShort, style: monoDim),
            const SizedBox(height: 10),
            CountStepper(
              value: pendingTake,
              cap: state.bankedGold,
              onChanged: (next) => setState(() => _pendingTake = next),
            ),
            FilledButton(
              onPressed: pendingTake <= 0
                  ? null
                  : () {
                      bloc.add(WithdrawGoldPressed(pendingTake));
                      setState(() => _pendingTake = 0);
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Take gold',
                style: TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
            if (state.bankedGold <= 0) Text(vaultIsShort, style: monoDim),
            const Heading('Carried — lost if you die'),
            if (state.profile.inventory.isEmpty)
              const NothingHere('You are carrying nothing.'),
            for (final item in state.profile.inventory)
              ItemRow(
                marking: item.rarity.marking,
                name: item.displayName,
                action: 'Bank',
                onPressed: () => bloc.add(DepositItemPressed(item.id)),
              ),
            const Heading('Banked — safe from death'),
            if (state.profile.bank.isEmpty)
              const NothingHere('The vault is empty.'),
            for (final item in state.profile.bank)
              ItemRow(
                marking: item.rarity.marking,
                name: item.displayName,
                action: 'Take out',
                onPressed: () => bloc.add(WithdrawItemPressed(item.id)),
              ),
          ],
        );
      },
    );
  }
}
