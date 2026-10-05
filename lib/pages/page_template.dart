import 'dart:ui' show ImageFilter;

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/core/theme/app_theme.dart';
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

int _topBarSerial = 0;

/// Parks the page on the right third of a wide screen so the map can be used.
final ValueNotifier<bool> contentDockedRight = ValueNotifier(false);

/// Desktop and TV only, and only when a third of the window is still usable.
bool contentDockAvailable(
  BuildContext context,
  double width, {
  required bool fullScreen,
}) {
  if (fullScreen || width < 1200) return false;
  final device = context.getDeviceType();
  return device == DeviceType.desktop || device == DeviceType.tv;
}

/// Applies [update] now, or on the next frame when a build is in progress.
void _scheduleTopBar(void Function() update) {
  final phase = SchedulerBinding.instance.schedulerPhase;
  if (phase == SchedulerPhase.idle) {
    update();
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) => update());
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
  final serial = ++_topBarSerial;
  _scheduleTopBar(() {
    // A newer setTopBar wins. A clear from the page we just left must not
    // erase this one: that clear checks the owner again when it runs.
    if (serial != _topBarSerial) return;
    topBarNotifier.value = merged;
  });
}

/// Clear top bar content.
void clearTopBar({String? ownerId}) {
  _scheduleTopBar(() {
    final current = topBarNotifier.value;
    // Checked at apply time. The page we left often disposes in the same
    // frame the next page sets the bar, and a deferred clear used to wipe
    // the new submenu.
    if (ownerId != null && current.ownerId != ownerId) return;
    topBarNotifier.value = const TopBarData();
  });
}

/// Content panel with the scrollbar 10px to the right of the box.
class _ContentFrame extends StatefulWidget {
  final Widget child;
  final Color background;
  final double horizontalPadding;
  final double verticalPadding;
  final double? topPadding;

  const _ContentFrame({
    required this.child,
    required this.background,
    required this.horizontalPadding,
    required this.verticalPadding,
    this.topPadding,
  });

  @override
  State<_ContentFrame> createState() => _ContentFrameState();
}

class _ContentFrameState extends State<_ContentFrame> {
  static const _thumb = 6.0;
  static const _gap = 10.0;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline.withValues(alpha: 0.5);
    final box = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.background.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: outline),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              widget.horizontalPadding,
              widget.topPadding ?? widget.verticalPadding,
              widget.horizontalPadding,
              widget.verticalPadding,
            ),
            child: ClipRect(child: widget.child),
          ),
        ),
      ),
    );
    return PrimaryScrollController(
      controller: _scroll,
      child: ListenableBuilder(
        listenable: _scroll,
        builder: (context, child) {
          final framed = Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: child!),
                const SizedBox(width: _gap + _thumb),
              ],
            ),
          );
          return RawScrollbar(
            controller: _scroll,
            thumbVisibility: _scroll.hasClients,
            thickness: _thumb,
            radius: const Radius.circular(3),
            thumbColor: const Color(0xFFB7C0C8),
            crossAxisMargin: 0,
            mainAxisMargin: 12,
            interactive: true,
            child: framed,
          );
        },
        child: box,
      ),
    );
  }
}

class PageTemplate extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final bool fullScreen;

  /// Map compass; only Charts should enable this.
  final bool showCompass;

  /// When set, replaces the theme's side padding inside the content panel.
  final double? contentHorizontalPadding;

  /// When set, replaces the space above the first element in the panel.
  final double? contentTopPadding;
  final ValueChanged<MapLibreMapController>? onMapCreated;
  final ValueChanged<CameraPosition>? onCameraMove;
  final VoidCallback? onCameraIdle;
  final CameraPosition? initialCamera;

  const PageTemplate({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.fullScreen = false,
    this.showCompass = false,
    this.contentHorizontalPadding,
    this.contentTopPadding,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.initialCamera,
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
          final width = constraints.maxWidth;
          final inset = PageWidth.outerInset(context, width);
          return ValueListenableBuilder<bool>(
            valueListenable: contentDockedRight,
            builder: (context, dockPref, _) {
              final docked = dockPref &&
                  contentDockAvailable(
                    context,
                    width,
                    fullScreen: fullScreen,
                  );
              // Right third of the screen, and never narrower than 500px.
              // The left stays an open chart.
              final panelWidth = width / 3 < 500 ? 500.0 : width / 3;
              final slotLeft = docked ? width - panelWidth : inset;
              final slotRight = docked ? 0.0 : inset;
              return Stack(
            children: [
              Positioned.fill(
                child: OceanMapBackground(
                  interactive: fullScreen || docked,
                  showCompass: showCompass,
                  controlRightInset: docked ? panelWidth : 0,
                  initialCamera: initialCamera,
                  onMapCreated: onMapCreated,
                  onCameraMove: onCameraMove,
                  onCameraIdle: onCameraIdle,
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
                  left: slotLeft,
                  right: slotRight,
                  bottom: footerHeight,
                  child: PointerInterceptor(
                    child: _ContentFrame(
                    background: background,
                    horizontalPadding: contentHorizontalPadding ??
                        (sizes['contentHorizontalPadding'] as double? ?? 30.0),
                    verticalPadding:
                        sizes['contentVerticalPadding'] as double? ?? 30.0,
                    topPadding: contentTopPadding,
                    child: body,
                  ),
                  ),
                ),
              // The page can park on the right. The header stays in place.
              Positioned(
                top: 0,
                left: inset,
                right: inset,
                child: PointerInterceptor(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MyAppBar(),
                      if (showTopHeader) const TopHeader(),
                    ],
                  ),
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
          );
        },
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
