import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';

class OceanCharts extends StatelessWidget {
  final Map<String, String>? params;

  const OceanCharts({super.key, this.params});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PageTemplate(
      body: Html(
        data: '''
        <iframe src="https://www.nauticalcharts.noaa.gov/viewer/" width="100%" height="600" frameborder="0"></iframe>
        <p>NOAA Nautical Charts Viewer</p>
        ''',
      ),
    );
  }
}
