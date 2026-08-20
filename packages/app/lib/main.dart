import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';

import 'town/town_bloc.dart';
import 'town/town_screen.dart';

void main() => runApp(const ResiduumApp());

class ResiduumApp extends StatelessWidget {
  const ResiduumApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Residuum',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0E1014),
      useMaterial3: true,
    ),
    home: BlocProvider(
      create: (_) => TownBloc(profile: newProfile()),
      child: const TownScreen(),
    ),
  );
}
