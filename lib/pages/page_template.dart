import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:free_open_ocean/core/provider/AppThemeProvider.dart';
import 'package:free_open_ocean/widgets/footer.dart';
import 'package:free_open_ocean/widgets/header.dart';
import 'package:free_open_ocean/widgets/menu.dart';
import 'package:free_open_ocean/widgets/top_header.dart';


// Top bar data and notifier so pages can set a title and submenu that the header will render.
class TopBarData {
  final String? title;
  final List<Widget>? submenu;
  final String? ownerId;

  const TopBarData({this.title, this.submenu, this.ownerId});
}

final ValueNotifier<TopBarData> topBarNotifier = ValueNotifier(const TopBarData());

/// Helper that updates the notifier immediately if safe, or schedules it for the next frame.
void _updateTopBarNotifier(TopBarData data) {
  final phase = SchedulerBinding.instance.schedulerPhase;
  void doUpdate() {
    if (kDebugMode) {
      final prev = topBarNotifier.value;
      // print a concise debug message showing previous and new top bar states
      // include a short stack trace for context
      final trace = StackTrace.current.toString().split('\n').take(3).join(' | ');
      // ignore long prints in non-debug builds
      print('[TopBar] update: prev(owner=${prev.ownerId}, title=${prev.title}) -> new(owner=${data.ownerId}, title=${data.title}) ; trace: $trace');
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

  const PageTemplate({super.key, required this.body, this.floatingActionButton, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    final sizes = context.getThemeSizes('pageLayout');

    if (fullScreen) {
      return Scaffold(
        drawer: const AppMenu(),
        body: Stack(
          children: [
            Positioned.fill(child: body),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const HeaderRow(),
            ),
            if (sizes['footer']) Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: const Footer(),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      appBar: const MyAppBar(),
      drawer: const AppMenu(),
      body: Column(
        children: [
          sizes['topHeader'] ? const TopHeader() : const SizedBox(),
          Expanded(
            child: body,
          ),
          sizes['footer'] ? const Footer() : const SizedBox(),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class HeaderRow extends StatelessWidget {
  const HeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyAppBar();
  }
}