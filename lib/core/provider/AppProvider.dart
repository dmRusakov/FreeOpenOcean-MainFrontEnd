import 'package:flutter/material.dart';
import 'package:free_open_ocean/common/element/appButon.dart';
import 'dart:async';
import '../../services/app.dart';
import '../../services/api.dart';
import '../../models/endpoint.dart';
import '../../core/localization/AppLocalizations.dart';
import '../../common/element/appDropdown.dart';
import 'package:free_open_ocean/core/provider/AppThemeProvider.dart';

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

  // connection mode icons
  static IconData getConnectionModeIcon(ConnectionMode mode) {
    switch (mode) {
      case ConnectionMode.disable:
        return Icons.cloud_off;
      case ConnectionMode.silent:
        return Icons.cloud_outlined;
      case ConnectionMode.normal:
        return Icons.cloud_rounded;
    }
  }

  // connection mode status icons
  static IconData getConnectionStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.offline:
        return Icons.signal_wifi_off;
      case ConnectionStatus.connecting:
        return Icons.signal_wifi_4_bar_lock;
      case ConnectionStatus.online:
        return Icons.signal_wifi_4_bar;
    }
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

    IconData icon = getConnectionModeIcon(currentMode);

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
            final filteredModes = ConnectionMode.values.where((mode) =>
                mode.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
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
                          IconData icon = getConnectionModeIcon(mode);
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

  static Future<Map<String, dynamic>> _getStatusData(BuildContext context) async {
    final provider = AppProvider.of(context);
    final connectionStatus = await provider?.app.getConnectionStatus();
    final connectionMode = await provider?.app.getConnectionMode();
    final endpoint = await provider?.app.getEndpoint();

    String status = 'unknown';
    IconData icon = AppProvider.getConnectionStatusIcon(ConnectionStatus.offline);

    if (connectionMode == ConnectionMode.disable) {
      status = connectionMode?.name ?? 'disable';
      icon = AppProvider.getConnectionModeIcon(ConnectionMode.disable);
    } else if (connectionStatus == ConnectionStatus.online) {
      status = connectionMode?.name ?? 'normal';
      icon = AppProvider.getConnectionModeIcon(connectionMode ?? ConnectionMode.normal);
    } else {
      status = connectionStatus?.name ?? 'online';
      icon = AppProvider.getConnectionStatusIcon(connectionStatus ?? ConnectionStatus.online);
    }

    return {
      'name': endpoint?.name ?? 'Offline',
      'status': status,
      'icon': icon,
    };
  }

  static Widget buildFooterConnectionStatusIcon(BuildContext context) {
    final theme = context.getTheme('footer');
    final localizations = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getStatusData(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        }
        final data = snapshot.data;
        final status = data?['status'] ?? 'unknown';
        final icon = data?['icon'] ?? Icons.help_outline;

        return AppButton(
          icon: icon,
          text: localizations.translate(status),
          size: 's',
          // onPressed: () => _selectSection(SettingSection.general),
          // theme: _selectedSection == SettingSection.general ? 'primary' : 'secondary',
        );

        // return Padding(
        //   padding: const EdgeInsets.only(top: 3),
        //   child: Container(
        //     child: Icon(
        //       icon,
        //       color: color,
        //       size: (theme.sizes['fontSize'] ?? 14.0) * 1.2,
        //     ),
        //   ),
        // );
      },
    );
  }
}

extension ContextExtensions on BuildContext {

  Future<Endpoint> getEndpoint() async {
    final api = AppProvider.of(this)?.api;
    if (api == null) throw Exception('No AppProvider');
    if (api.selectedEndpoint != null) return api.selectedEndpoint!;
    if (api.endpointCompleter == null) api.endpointCompleter = Completer<Endpoint>();
    return api.endpointCompleter!.future;
  }
}