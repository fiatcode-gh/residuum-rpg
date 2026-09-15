import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../game/pack_screen.dart';
import 'town_bloc.dart';
import 'town_style.dart';

class TownPackScreen extends StatelessWidget {
  const TownPackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) => TownRoom(
        title: 'Pack',
        children: [
          PackContents(
            inventory: state.profile.inventory,
            equipment: state.profile.equipment,
            materials: state.materials,
            readRefusalFor: state.readReason,
            wearRefusalFor: state.wearReason,
            onRead: (id) => bloc.add(ReadBookPressed(id)),
            onWear: (id) => bloc.add(WearPressed(id)),
            showBookTeaching: true,
          ),
        ],
      ),
    );
  }
}
