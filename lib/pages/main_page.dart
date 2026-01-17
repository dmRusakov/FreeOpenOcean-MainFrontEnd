import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainPage extends StatelessWidget {
  final Map<String, String>? params;

  const MainPage({super.key, this.params});

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.translate('home_page')),
            // const SizedBox(height: 20),
            // SvgPicture.asset('assets/flags/us.svg', width: 100, height: 100),
            // const SizedBox(height: 20),
            // SvgPicture.asset('assets/icons/donate.svg', width: 100, height: 100),
          ],
        ),
      ),
    );
  }
}
