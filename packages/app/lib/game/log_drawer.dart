import 'package:flutter/material.dart';

import '../style/tokens.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';
import 'log_line.dart';

const logPeekKey = Key('log-peek');
const logHandleKey = Key('log-handle');
const logDrawerKey = Key('log-drawer');
const logCloseKey = Key('log-close');
const logUnreadKey = Key('log-unread');

TextStyle _rowStyle(bool newest) => newest ? textLine : textLineDim;

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
        color: dim,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// The fixed compact strip above the crawl's action controls: the last few
/// lines of the message log, newest last, the same value-only contrast the
/// log has always used. The whole strip is the handle that opens the drawer;
/// its trailing chevron is the mock's explicit expand affordance.
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
      child: SizedBox(
        height: crawlLogPeekHeight,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: rhythm,
          ),
          child: CrawlPanel(
            padding: const EdgeInsets.symmetric(
              horizontal: crawlPanelPadding,
              vertical: rhythm,
            ),
            child: Row(
              children: [
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
                const SizedBox(width: rhythm),
                const Text('›', style: textGlyphDim),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// One line of the expanded log: its category glyph in an inset well and its
/// sentence, both in the row's own colour so hue never carries the category.
/// The category word is exposed to accessibility and nowhere else, which is
/// what keeps the mark from doubling as a second sighted-only cue.
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: crawlLogRowRhythm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: crawlMarkColumn,
                child: Center(
                  child: Container(
                    width: crawlMarkWell,
                    height: crawlMarkWell,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: recessed,
                      border: Border.all(color: rule, width: hairline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(line.category.mark, style: style),
                  ),
                ),
              ),
              Expanded(child: Text(line.sentence, style: style)),
            ],
          ),
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
        color: panel,
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
              padding: const EdgeInsets.symmetric(horizontal: gutter),
              child: Row(
                children: [
                  const Text('MESSAGE LOG', style: displayPanel),
                  const Spacer(),
                  CrawlPill(
                    key: logCloseKey,
                    label: 'Close the message log',
                    icon: Icons.close,
                    onPressed: () => widget.bloc.add(const LogDrawerClosed()),
                  ),
                ],
              ),
            ),
            Container(
              height: hairline,
              margin: const EdgeInsets.symmetric(horizontal: gutter),
              color: rule,
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _controller,
                    padding: const EdgeInsets.symmetric(horizontal: gutter),
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
                      child: CrawlPill(
                        key: logUnreadKey,
                        label: '↓ ${widget.state.logUnread} new',
                        onPressed: () {
                          widget.bloc.add(const LogFollowResumed());
                          _jumpToNewest();
                        },
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
