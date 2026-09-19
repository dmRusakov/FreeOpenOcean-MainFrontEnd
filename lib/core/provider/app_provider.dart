import 'package:flutter/material.dart';
import 'package:free_open_ocean/common/element/app_button.dart';
import '../../services/app.dart';
import '../../services/api.dart';
import '../../models/endpoint.dart';
import '../../core/localization/app_localizations.dart';
import '../../common/element/app_dropdown.dart';

class AppProvider extends InheritedWidget {
  final App app;
  final Api api;

  const AppProvider({
    super.key,
    required this.app,
    required this.api,
    required super.child,
  });

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
    void Function(ConnectionMode?) onChanged, {
    String color = 'secondary',
    String size = 'm',
    bool showTextAlways = false,
  }) {
    final localizations = AppLocalizations.of(context)!;

    IconData icon = getConnectionModeIcon(currentMode);

    return AppDropdown<ConnectionMode>(
      text: showTextAlways ? localizations.translate(currentMode.name) : null,
      onPressed: () =>
          _showConnectionModeSearchDialog(context, currentMode, onChanged),
      icon: icon,
      theme: color,
      size: size,
      showTextAlways: showTextAlways,
    );
  }

  static void _showConnectionModeSearchDialog(
    BuildContext context,
    ConnectionMode currentMode,
    void Function(ConnectionMode?) onChanged,
  ) {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        final localizations = AppLocalizations.of(dialogContext)!;
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final filteredModes = ConnectionMode.values
                .where(
                  (mode) => mode.name.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
                )
                .toList();
            return AlertDialog(
              title: Text(localizations.translate('select_connection_mode')),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: localizations.translate(
                          'search_connection_mode',
                        ),
                      ),
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
                              Navigator.pop(dialogContext);
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

  static Widget buildFooterConnectionStatusIcon(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final provider = AppProvider.of(context);
    final connectionStatus =
        provider?.app.connectionStatus ?? ConnectionStatus.offline;
    final connectionMode =
        provider?.app.connectionMode ?? ConnectionMode.disable;

    String status = 'unknown';
    IconData icon = Icons.help_outline;

    if (connectionMode == ConnectionMode.disable) {
      status = 'disable';
      icon = AppProvider.getConnectionModeIcon(ConnectionMode.disable);
    } else if (connectionStatus == ConnectionStatus.online) {
      status = connectionMode.name;
      icon = AppProvider.getConnectionModeIcon(connectionMode);
    } else {
      status = connectionStatus.name;
      icon = AppProvider.getConnectionStatusIcon(connectionStatus);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 0, top: 3),
      child: AppButton(
        icon: icon,
        text:
            '${localizations.translate('server_connection')}: ${localizations.translate(status)}',
        size: 's',
        theme: status == 'offline' || status == 'disable'
            ? 'error'
            : (status == 'connecting' ? 'warning' : 'success'),
      ),
    );
  }
}

extension ContextExtensions on BuildContext {
  Future<Endpoint> getEndpoint() {
    final app = AppProvider.of(this)?.app;
    if (app == null) throw StateError('No AppProvider');
    return app.getEndpoint();
  }
}
