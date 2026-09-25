import 'package:flutter/material.dart';

import 'crawl_style.dart';
import 'game_bloc.dart';
import 'log_drawer.dart';

const logRowKey = Key('log-row');

class LogRow extends StatelessWidget {
  const LogRow({required this.state, required this.bloc, super.key});

  final GameViewState state;
  final GameBloc bloc;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: crawlLogRowHeight * crawlScale(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
      child: LogPeek(key: logPeekKey, state: state, bloc: bloc),
    ),
  );
}
