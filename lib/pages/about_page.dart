import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';

class AboutPage extends StatefulWidget {
  final Map<String, String>? params;

  const AboutPage({super.key, this.params});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const _ownerId = 'about_page';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ensure localization is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context)!;
      setTopBar(title: localizations.translate('about_page'), ownerId: _ownerId, submenu: []);
    });
  }

  @override
  void dispose() {
    clearTopBar(ownerId: _ownerId);
    super.dispose();
  }

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