import 'dart:async';
import 'package:flutter/material.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart' as theme_interface;
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:free_open_ocean/core/app/AppProvider.dart';

class StatusIndicator extends StatefulWidget {
  final Duration pollInterval;

  const StatusIndicator({super.key, this.pollInterval = const Duration(minutes: 5)});

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> {
  // final Api _api = Api(settingsService: SettingsService());
  late Timer _timer;
  // StatusInfo _info = const StatusInfo(ok: false, serverName: '', message: 'Not checked');
  // states: 0 = initial (yellow), 1 = ok (green), 2 = error (red)
  int _state = 0;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // initial: yellow
    _state = 0;
    // _poll(); // moved to didChangeDependencies
    _timer = Timer.periodic(widget.pollInterval, (_) => _poll());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _poll();
  }

  Future<void> _poll() async {
    final ep = context.getEndpoint();
    print(ep);
    print('Polling server status... Endpoint: ${ep?.id}');
    setState(() {
      _state = 0; // loading
    });
    // final ep = await _api.getStatus();
    // setState(() {
    //   _info = info;
    //   _state = info.ok ? 1 : 2;
    // });
  }

  @override
  void dispose() {
    _timer.cancel();
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (_state) {
      case 0:
        color = Colors.yellow;
        icon = Icons.hourglass_top;
        break;
      case 1:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.red;
        icon = Icons.error;
    }

    // final displayName = _info.serverName.isNotEmpty ? _info.serverName : _info.message;
    final displayName = 'Not checked';

    // Align to the right and shift up by 3px (negative top margin)
    return Align(
      alignment: Alignment.centerRight,
      child: Transform.translate(
        offset: const Offset(0, -3), // move up by 3px
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: "",
            child: IconButton(
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
              icon: Icon(icon, color: color, size: (IconTheme.of(context).size ?? 16.0) * 0.6),
              onPressed: () {
                if (_overlayEntry != null) {
                  _overlayEntry!.remove();
                  _overlayEntry = null;
                }
                _overlayEntry = OverlayEntry(
                  builder: (context) {
                    final themeProvider = theme_interface.AppThemeProvider.of(context)!;
                    final name = "Server: $displayName";
                    return Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: MouseRegion(
                        onExit: (event) {
                          _overlayEntry?.remove();
                          _overlayEntry = null;
                        },
                        child: Material(
                          elevation: 6,
                          color: Colors.grey[800],
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              children: [
                                Text(name, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
                                const Spacer(),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppLocalizations.buildLanguageDropdown(context, themeProvider.locale, (locale) => themeProvider.onLocaleChanged(locale, true), size: 's', color: "info"),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    theme_interface.AppThemeProvider.buildThemeModeDropdown(context, themeProvider.themeMode, themeProvider.onThemeModeChanged, size: 's', color: "info"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
                Overlay.of(context).insert(_overlayEntry!);
              },
            ),
          ),
        ),
      ),
    );
  }
}
