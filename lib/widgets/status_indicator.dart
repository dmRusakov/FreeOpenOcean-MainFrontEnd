import 'dart:async';
import 'package:flutter/material.dart';
import 'package:free_open_ocean/services/api.dart';
import 'package:free_open_ocean/services/status_info.dart';
import 'package:free_open_ocean/services/settings_service.dart';

class StatusIndicator extends StatefulWidget {
  final Duration pollInterval;

  const StatusIndicator({super.key, this.pollInterval = const Duration(minutes: 5)});

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> {
  final Api _api = Api(settingsService: SettingsService());
  late Timer _timer;
  StatusInfo _info = const StatusInfo(ok: false, serverName: '', message: 'Not checked');
  // states: 0 = initial (yellow), 1 = ok (green), 2 = error (red)
  int _state = 0;

  @override
  void initState() {
    super.initState();
    // initial: yellow
    _state = 0;
    _poll();
    _timer = Timer.periodic(widget.pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    setState(() {
      _state = 0; // loading
    });
    final info = await _api.getStatus();
    setState(() {
      _info = info;
      _state = info.ok ? 1 : 2;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
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

    final displayName = _info.serverName.isNotEmpty ? _info.serverName : _info.message;

    final baseSize = IconTheme.of(context).size ?? 24.0;
    final iconSize = baseSize * 0.6;

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
              iconSize: iconSize,
              splashRadius: iconSize + 6,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
              icon: Icon(icon, color: color, size: iconSize),
              onPressed: () {
                // Show server name on click, do not reload status
                final name = "Server: $displayName";
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(name, style: const TextStyle(color: Colors.white)),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.grey[800],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
