import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';

class MapPage extends StatelessWidget {
  final Map<String, String>? params;

  const MapPage({super.key, this.params});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PageTemplate(
      body: Center(
        child: Text(localizations.translate('about_page')),
      ),
    );
  }
}
