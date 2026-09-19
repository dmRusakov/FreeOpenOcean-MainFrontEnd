import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';

class OceanCharts extends StatefulWidget {
  final Map<String, String>? params;

  const OceanCharts({super.key, this.params});

  @override
  State<OceanCharts> createState() => _OceanChartsState();
}

class _OceanChartsState extends State<OceanCharts> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final localizations = AppLocalizations.of(context)!;
      setTopBar(
        title: localizations.translate('ocean_charts'),
        ownerId: 'ocean_charts',
        submenu: [],
      );
    });
  }

  @override
  void dispose() {
    clearTopBar(ownerId: 'ocean_charts');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const PageTemplate(
      fullScreen: true,
      showCompass: true,
      body: SizedBox.expand(),
    );
  }
}
