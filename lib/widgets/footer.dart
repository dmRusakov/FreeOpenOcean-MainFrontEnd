import 'package:flutter/material.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.getTheme('footer');
    final localizations = AppLocalizations.of(context)!;

    return Container(
      height: theme.sizes['height'],
      color: theme.color['background'],
      padding: theme.sizes['padding'],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${localizations.translate('footer_text')} (v$_version)',
            style: TextStyle(
              fontSize: theme.sizes['fontSize'],
              color: theme.color['text'],
            ),
          ),
        ],
      ),
    );
  }
}
