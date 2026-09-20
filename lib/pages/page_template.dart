import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/widgets/footer.dart';
import 'package:free_open_ocean/widgets/header.dart';
import 'package:free_open_ocean/widgets/menu.dart';
import 'package:free_open_ocean/widgets/ocean_map_background.dart';
import 'package:free_open_ocean/widgets/top_header.dart';

import '../widgets/page_width.dart';

// Top bar data and notifier so pages can set a title and submenu that the header will render.
class TopBarData {
  final String? title;
  final List<Widget>? submenu;
  final String? ownerId;

  const TopBarData({this.title, this.submenu, this.ownerId});
}

final ValueNotifier<TopBarData> topBarNotifier = ValueNotifier(
  const TopBarData(),
);

/// Helper that updates the notifier immediately if safe, or schedules it for the next frame.
void _updateTopBarNotifier(TopBarData data) {
  final phase = SchedulerBinding.instance.schedulerPhase;
  void doUpdate() {
    if (kDebugMode) {
      final prev = topBarNotifier.value;
      // print a concise debug message showing previous and new top bar states
      // include a short stack trace for context
      final trace = StackTrace.current
          .toString()
          .split('\n')
          .take(3)
          .join(' | ');
      // ignore long prints in non-debug builds
      debugPrint(
        '[TopBar] update: prev(owner=${prev.ownerId}, title=${prev.title}) -> new(owner=${data.ownerId}, title=${data.title}) ; trace: $trace',
      );
    }
    topBarNotifier.value = data;
  }

  // Only update immediately when the framework is idle; otherwise schedule a post-frame callback
  if (phase == SchedulerPhase.idle) {
    doUpdate();
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      doUpdate();
    });
  }
}

/// Set top bar title and/or submenu. Use `submenu` as a list of small widgets (e.g. AppButton).
void setTopBar({String? title, List<Widget>? submenu, String? ownerId}) {
  // Merge with existing data so partial updates don't clear other fields.
  final current = topBarNotifier.value;
  final merged = TopBarData(
    title: title ?? current.title,
    submenu: submenu ?? current.submenu,
    ownerId: ownerId ?? current.ownerId,
  );
  _updateTopBarNotifier(merged);
}

/// Clear top bar content.
void clearTopBar({String? ownerId}) {
  // If ownerId is provided, only clear if current owner matches. If no ownerId, clear unconditionally.
  final current = topBarNotifier.value;
  if (ownerId != null) {
    if (current.ownerId == ownerId) {
      _updateTopBarNotifier(const TopBarData());
    }
  } else {
    _updateTopBarNotifier(const TopBarData());
  }
}

class PageTemplate extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final bool fullScreen;

  /// Map compass; only Charts should enable this.
  final bool showCompass;
  final ValueChanged<MapLibreMapController>? onMapCreated;
  final ValueChanged<CameraPosition>? onCameraMove;

  const PageTemplate({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.fullScreen = false,
    this.showCompass = false,
    this.onMapCreated,
    this.onCameraMove,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = context.getThemeSizes('pageLayout');
    final footerTheme = context.getTheme('footer');
    final showTopHeader = sizes['topHeader'] == true;
    final showFooter = sizes['footer'] == true;
    final topHeaderHeight = showTopHeader
        ? (context.getTheme('topHeader').sizes['height'] as double? ?? 0)
        : 0.0;
    final footerHeight = showFooter
        ? (footerTheme.sizes['height'] as double? ?? 30.0)
        : 0.0;
    final topChrome = kToolbarHeight + topHeaderHeight;
    final background =
        context.getThemeColor('background') as Color? ??
        Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AppMenu(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final inset = PageWidth.outerInset(context, constraints.maxWidth);
          return Stack(
            children: [
              Positioned.fill(
                child: OceanMapBackground(
                  interactive: fullScreen,
                  showCompass: showCompass,
                  onMapCreated: onMapCreated,
                  onCameraMove: onCameraMove,
                ),
              ),
              // Charts: full-bleed interactive map. Other pages: content panel over map.
              if (fullScreen)
                Positioned(
                  top: topChrome,
                  left: 0,
                  right: 0,
                  bottom: footerHeight,
                  child: IgnorePointer(child: body),
                )
              else
                Positioned(
                  top: topChrome,
                  left: inset,
                  right: inset,
                  bottom: footerHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: background.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: sizes['contentHorizontalPadding'] as double? ?? 30.0,
                            vertical: sizes['contentVerticalPadding'] as double? ?? 30.0,
                          ),
                          child: ClipRect(child: body),
                        ),
                      ),
                    ),
                  ),
                ),
              // Header stays inside the content column.
              Positioned(
                top: 0,
                left: inset,
                right: inset,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MyAppBar(),
                    if (showTopHeader) const TopHeader(),
                  ],
                ),
              ),
              if (showFooter)
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Footer(),
                ),
            ],
          );
        },
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
