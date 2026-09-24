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

/// The fixed compact strip above the crawl's action controls: the last few
/// lines of the message log, oldest to newest top to bottom, and the true
/// running count — so a glance already answers "how much have I missed"
/// without opening the drawer. The whole strip is the handle that opens it;
/// its trailing chevron-like affordance is the mock's explicit invitation.
/// No pictogram and no timestamp here — those belong to the expanded log.
class LogPeek extends StatelessWidget {
  const LogPeek({required this.state, required this.bloc, super.key});

  final GameViewState state;
  final GameBloc bloc;

  @override
  Widget build(BuildContext context) {
    final log = state.log;
    final shown = log.length > 4 ? log.sublist(log.length - 4) : log;
    return Semantics(
      button: true,
      enabled: !state.game.isGameOver,
      label: 'Open the message log',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: state.game.isGameOver
            ? null
            : () => bloc.add(const LogDrawerHandlePulled()),
        child: SizedBox(
          width: double.infinity,
          height: crawlEventsHeight * crawlScale(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: crawlPanelFill,
                border: Border.all(color: crawlFrame, width: hairline),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  gutter,
                  crawlPanelPadding,
                  gutter,
                  rhythm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 16 * crawlScale(context),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('RECENT EVENTS', style: displaySection),
                          ),
                          Text('${log.length} entries', style: monoMeta),
                          const SizedBox(width: rhythm),
                          const Icon(
                            Icons.unfold_more,
                            size: 16,
                            color: crawlTextDim,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(height: hairline, color: crawlDivider),
                    const SizedBox(height: rhythm),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var index = 0; index < shown.length; index++)
                            SizedBox(
                              height: crawlLogLine * crawlScale(context),
                              child: Opacity(
                                opacity: index == shown.length - 1 ? 1 : 0.72,
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
                  ],
                ),
              ),
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

/// The overlay panel: the drag handle, the title row with its close
/// affordance, and the expanded, pictogrammed log. Peek → half → full and
/// this panel's own extent and position are [GameScreen]'s job entirely
/// (PLAN.md G8); this widget owns only its own fill and border, scroll
/// position, and the reader crossing the newest-entry boundary.
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
  Widget build(BuildContext context) {
    final count = widget.state.log.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: crawlPanelFill,
          border: Border(
            top: BorderSide(color: crawlFrame, width: hairline),
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: gutter),
          child: Column(
            children: [
              SizedBox(
                height: crawlLogSheetHeader,
                child: Stack(
                  children: [
                    const Positioned(
                      top: 3,
                      left: 0,
                      right: 0,
                      child: Center(child: _HandlePill()),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: rhythm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                button: true,
                                label: 'Resize the message log',
                                child: GestureDetector(
                                  key: logHandleKey,
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => widget.bloc.add(
                                    const LogDrawerHandlePulled(),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'RECENT EVENTS',
                                        style: displaySheetTitle,
                                      ),
                                      const Spacer(),
                                      Text('$count entries', style: monoMeta),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: gutter),
                            Semantics(
                              button: true,
                              label: 'Close the message log',
                              child: GestureDetector(
                                key: logCloseKey,
                                onTap: () =>
                                    widget.bloc.add(const LogDrawerClosed()),
                                child: const SizedBox(
                                  width: 40,
                                  height: 40,
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

/// The drawer's own drag-handle pill: the shape that says "there is more
/// here" without a word.
class _HandlePill extends StatelessWidget {
  const _HandlePill();

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 3,
    decoration: BoxDecoration(
      color: crawlTextDim,
      borderRadius: BorderRadius.circular(1.5),
    ),
  );
}
