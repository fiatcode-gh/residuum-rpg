import 'package:flutter/material.dart';

import 'game_bloc.dart';
import 'log_line.dart';

const logPeekKey = Key('log-peek');
const logHandleKey = Key('log-handle');
const logDrawerKey = Key('log-drawer');
const logCloseKey = Key('log-close');
const logUnreadKey = Key('log-unread');

const Color _logBacking = Color(0xFF15181F);
const Color _logNewest = Color(0xFFE6EAF0);
const Color _logOlder = Color(0xFF8A919E);
const Color _logHandle = Color(0xFF8A919E);

TextStyle _rowStyle(bool newest) => TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  color: newest ? _logNewest : _logOlder,
);

/// The centred drag handle pill the mock draws atop both the peek and the
/// drawer: the one shape that says "there is more here" without a word.
class _HandlePill extends StatelessWidget {
  const _HandlePill();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: _logHandle,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// The fixed compact strip above [_Controls]: the last few lines of the
/// message log, newest last, the same value-only contrast the log has always
/// used. The whole strip is the handle that opens the drawer.
class LogPeek extends StatelessWidget {
  const LogPeek({required this.state, required this.bloc, super.key});

  final GameViewState state;
  final GameBloc bloc;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: !state.game.isGameOver,
    label: 'Open the message log',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: state.game.isGameOver
          ? null
          : () => bloc.add(const LogDrawerHandlePulled()),
      child: Container(
        height: 104,
        width: double.infinity,
        color: _logBacking,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            const SizedBox(height: 12, child: _HandlePill()),
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: state.log.length,
                itemBuilder: (context, index) => Text(
                  state.log[state.log.length - 1 - index].sentence,
                  style: _rowStyle(index == 0),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One line of the expanded log: its category glyph in a leading column and
/// its sentence, both in the row's own colour so hue never carries the
/// category. The category word is exposed to accessibility and nowhere else,
/// which is what keeps the mark from doubling as a second sighted-only cue.
class _LogRow extends StatelessWidget {
  const _LogRow({required this.line, required this.newest});

  final LogLine line;
  final bool newest;

  @override
  Widget build(BuildContext context) {
    final style = _rowStyle(newest);
    return Semantics(
      label: '${line.category.word}. ${line.sentence}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 20, child: Text(line.category.mark, style: style)),
            Expanded(child: Text(line.sentence, style: style)),
          ],
        ),
      ),
    );
  }
}

/// The overlay panel: the handle, the title row with its close affordance,
/// and the expanded, glyphed log. Peek → half → full is driven entirely by
/// [GameViewState.logDrawerExtent]; this widget owns only scroll position and
/// reports the reader crossing the newest-entry boundary.
class LogDrawer extends StatefulWidget {
  const LogDrawer({required this.state, required this.bloc, super.key});

  final GameViewState state;
  final GameBloc bloc;

  @override
  State<LogDrawer> createState() => _LogDrawerState();
}

class _LogDrawerState extends State<LogDrawer> {
  static const double _followTolerance = 8;

  final ScrollController _controller = ScrollController();
  late int _lastLogLength;

  @override
  void initState() {
    super.initState();
    _lastLogLength = widget.state.log.length;
    _controller.addListener(_onScroll);
    _maybeJumpToNewest(grew: false, justFollowed: widget.state.logFollowing);
  }

  @override
  void didUpdateWidget(covariant LogDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final grew = widget.state.log.length > _lastLogLength;
    final justFollowed =
        widget.state.logFollowing && !oldWidget.state.logFollowing;
    _lastLogLength = widget.state.log.length;
    _maybeJumpToNewest(grew: grew, justFollowed: justFollowed);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _maybeJumpToNewest({required bool grew, required bool justFollowed}) {
    if (!widget.state.logFollowing || !(grew || justFollowed)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToNewest());
  }

  void _jumpToNewest() {
    if (!mounted || !_controller.hasClients) return;
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final atNewest =
        _controller.position.maxScrollExtent - _controller.position.pixels <=
        _followTolerance;
    if (widget.state.logFollowing && !atNewest) {
      widget.bloc.add(const LogFollowBroken());
    } else if (!widget.state.logFollowing && atNewest) {
      widget.bloc.add(const LogFollowResumed());
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: FractionallySizedBox(
      widthFactor: 1,
      heightFactor: widget.state.logDrawerExtent == LogDrawerExtent.full
          ? 1.0
          : 0.45,
      child: ColoredBox(
        color: _logBacking,
        child: Column(
          children: [
            Semantics(
              button: true,
              label: 'Resize the message log',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.bloc.add(const LogDrawerHandlePulled()),
                child: const SizedBox(
                  key: logHandleKey,
                  height: 20,
                  child: _HandlePill(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Text(
                    'MESSAGE LOG',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: _logNewest,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: logCloseKey,
                    icon: const Icon(Icons.close),
                    tooltip: 'Close the message log',
                    onPressed: () => widget.bloc.add(const LogDrawerClosed()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _controller,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: widget.state.log.length,
                    itemBuilder: (context, index) => _LogRow(
                      line: widget.state.log[index],
                      newest: index == widget.state.log.length - 1,
                    ),
                  ),
                  if (!widget.state.logFollowing && widget.state.logUnread > 0)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: FilledButton(
                        key: logUnreadKey,
                        onPressed: () {
                          widget.bloc.add(const LogFollowResumed());
                          _jumpToNewest();
                        },
                        child: Text('↓ ${widget.state.logUnread} new'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
