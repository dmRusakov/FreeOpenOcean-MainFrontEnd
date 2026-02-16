import 'package:flutter/material.dart';
import '../../services/app.dart';
import '../../services/api.dart';
import '../../models/endpoint.dart';
import '../../core/localization/AppLocalizations.dart';
import '../../common/element/appDropdown.dart';

enum ConnectionMode { disable, connecting, offline, silent, normal }

class AppProvider extends InheritedWidget {
  final App app;
  final Api api;

  const AppProvider({super.key, required this.app, required this.api, required super.child});

  static AppProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppProvider>();
  }

  @override
  bool updateShouldNotify(AppProvider oldWidget) {
    return false;
  }

  static Widget buildConnectionModeDropdown(
      BuildContext context,
      ConnectionMode currentMode,
      void Function(ConnectionMode?) onChanged,
      {
        String color = 'secondary',
        String size = 'm',
        bool showTextAlways = false,
      }) {
    final localizations = AppLocalizations.of(context)!;

    IconData icon;
    switch (currentMode) {
      case ConnectionMode.disable:
        icon = Icons.block;
        break;
      case ConnectionMode.connecting:
        icon = Icons.cloud_sync_rounded;
        break;
      case ConnectionMode.offline:
        icon = Icons.cloud_off;
        break;
      case ConnectionMode.silent:
        icon = Icons.cloud_queue;
        break;
      case ConnectionMode.normal:
        icon = Icons.cloud_rounded;
        break;
    }

    return AppDropdown<ConnectionMode>(
      text: showTextAlways ? localizations.translate(currentMode.name) : null,
      onPressed: () => _showConnectionModeSearchDialog(context, currentMode, onChanged),
      icon: icon,
      theme: color,
      size: size,
      showTextAlways: showTextAlways,
    );
  }

  static void _showConnectionModeSearchDialog(BuildContext context, ConnectionMode currentMode, void Function(ConnectionMode?) onChanged) {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredModes = ConnectionMode.values.where((mode) => mode.name.toLowerCase().contains(searchQuery.toLowerCase()) && mode != ConnectionMode.disable && mode != ConnectionMode.connecting).toList();
            return AlertDialog(
              title: Text(localizations.translate('select_connection_mode')),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(hintText: localizations.translate('search_connection_mode')),
                    ),
                    Expanded(
                      child: ListView(
                        children: filteredModes.map((mode) {
                          IconData icon;
                          switch (mode) {
                            case ConnectionMode.disable:
                              icon = Icons.block;
                              break;
                            case ConnectionMode.connecting:
                              icon = Icons.cloud_sync_rounded;
                              break;
                            case ConnectionMode.offline:
                              icon = Icons.cloud_off;
                              break;
                            case ConnectionMode.silent:
                              icon = Icons.cloud_queue;
                              break;
                            case ConnectionMode.normal:
                              icon = Icons.cloud_rounded;
                              break;
                          }
                          return ListTile(
                            leading: Icon(icon),
                            title: Text(localizations.translate(mode.name)),
                            selected: mode == currentMode,
                            onTap: () {
                              onChanged(mode);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

extension ContextExtensions on BuildContext {
  Endpoint? getEndpoint() {
    return AppProvider.of(this)?.api.selectedEndpoint;
  }
}
