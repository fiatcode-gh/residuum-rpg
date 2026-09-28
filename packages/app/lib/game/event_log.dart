import 'package:flutter/material.dart';

import '../style/tokens.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';
import 'log_line.dart';

const eventsStripKey = Key('events-strip');
const logPageKey = Key('log-page');
const logCloseKey = Key('log-close');
const logUnreadKey = Key('log-unread');

/// The Material icon a category's expanded-log row draws in its leading
/// column (PLAN.md G10). Exhaustive over [LogCategory] so a new category
/// cannot ship without a pictogram.
IconData logPictogram(LogCategory category) => switch (category) {
  LogCategory.struck => Icons.heart_broken,
  LogCategory.hit => Icons.gavel,
  LogCategory.died => Icons.dangerous,
  LogCategory.noticed => Icons.visibility,
  LogCategory.moved => Icons.directions_walk,
  LogCategory.refused => Icons.block,
  LogCategory.item => Icons.inventory_2,
  LogCategory.raised => Icons.trending_up,
  LogCategory.gathered => Icons.diamond,
  LogCategory.reported => Icons.priority_high,
};

/// The mono role a category's pictogram and sentence both render in
/// (PLAN.md G10): one tint carries the category, shared by the glyph and
/// the words so neither alone has to.
TextStyle logTint(LogCategory category) => switch (category) {
  LogCategory.struck => monoLogHostile,
  LogCategory.hit => monoLogHostile,
  LogCategory.died => monoLogTorch,
  LogCategory.noticed => monoLogHostile,
  LogCategory.moved => monoLog,
  LogCategory.refused => monoLog,
  LogCategory.item => monoLogCold,
  LogCategory.raised => monoLogCold,
  LogCategory.gathered => monoLogTorch,
  LogCategory.reported => monoLog,
};

class EventsStrip extends StatelessWidget {
  const EventsStrip({required this.state, required this.bloc, super.key});

  final GameViewState state;
  final GameBloc bloc;

  @override
  Widget build(BuildContext context) {
    final log = state.log;
    final shown = log.length > crawlEventsLines
        ? log.sublist(log.length - crawlEventsLines)
        : log;
    final gameOver = state.game.isGameOver;
    return Semantics(
      button: true,
      enabled: !gameOver,
      label: 'Open the message log',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: gameOver ? null : () => bloc.add(const LogOpened()),
        child: DecoratedBox(
          decoration: crawlEventsStripDecoration,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              8,
              crawlEventsStripTop,
              8,
              crawlEventsStripBottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < shown.length; index++)
                  SizedBox(
                    height: crawlLogLine * crawlScale(context),
                    child: Opacity(
                      opacity: crawlEventsFade[shown.length - 1 - index],
                      child: Text(
                        shown[index].sentence,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: logTint(shown[index].category),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One line of the expanded log: its category pictogram and its sentence,
/// both in the row's own tint (PLAN.md G10) so one hue carries the glyph
/// and the words rather than either alone. The category word is exposed to
/// accessibility and nowhere else, which is what keeps the pictogram from
/// doubling as a second sighted-only cue.
class _LogRow extends StatelessWidget {
  const _LogRow({required this.line, required this.newest});

  final LogLine line;
  final bool newest;

  @override
  Widget build(BuildContext context) {
    final style = logTint(line.category);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: crawlLogRowPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              logPictogram(line.category),
              size: crawlLogPictogram,
              color: style.color,
            ),
          ),
          Expanded(child: Text(line.sentence, style: style)),
        ],
      ),
    );
    return Semantics(
      label: '${line.category.word}. ${line.sentence}',
      child: ExcludeSemantics(
        child: newest ? row : Opacity(opacity: 0.78, child: row),
      ),
    );
  }
}

class LogPage extends StatefulWidget {
  const LogPage({required this.state, required this.bloc, super.key});

  final GameViewState state;
  final GameBloc bloc;

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
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
  void didUpdateWidget(covariant LogPage oldWidget) {
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
  Widget build(BuildContext context) {
    final count = widget.state.log.length;
    return BlockSemantics(
      child: Material(
        color: crawlPanelFill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: gutter),
          child: Column(
            children: [
              SizedBox(
                height: crawlTouchTarget,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('RECENT EVENTS', style: displaySheetTitle),
                    const Spacer(),
                    Text('$count entries', style: monoMeta),
                    const SizedBox(width: gutter),
                    Semantics(
                      button: true,
                      label: 'Close the message log',
                      child: GestureDetector(
                        key: logCloseKey,
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.bloc.add(const LogClosed()),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: crawlTextDim,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: hairline, color: crawlDivider),
              Expanded(
                child: Stack(
                  children: [
                    RawScrollbar(
                      controller: _controller,
                      thumbVisibility: true,
                      thickness: 3,
                      radius: const Radius.circular(1.5),
                      thumbColor: const Color(0x809CA3AF),
                      child: ListView.builder(
                        controller: _controller,
                        itemCount: widget.state.log.length,
                        itemBuilder: (context, index) => _LogRow(
                          line: widget.state.log[index],
                          newest: index == widget.state.log.length - 1,
                        ),
                      ),
                    ),
                    if (!widget.state.logFollowing &&
                        widget.state.logUnread > 0)
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
}
