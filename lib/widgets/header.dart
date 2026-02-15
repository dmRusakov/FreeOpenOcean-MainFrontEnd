import 'package:flutter/material.dart';
import '../common/element/logo.dart';
import '../core/theme/AppTheme.dart';
import 'package:free_open_ocean/common/element/appButon.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:free_open_ocean/core/provider/AppThemeProvider.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.getTheme('header');
    final localizations = AppLocalizations.of(context)!;

    return AppBar(
      toolbarHeight: kToolbarHeight,
      actionsPadding: theme.sizes['padding'],
      backgroundColor: theme.color['background'],
      leading: Padding(
        padding: const EdgeInsets.only(left: 15.0, right: 0),
        child: Row(
          children: [
            AppButton(
              onPressed: () { Scaffold.of(context).openDrawer(); },
              icon: Icons.menu,
              size: "l",
              theme: "success",
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Logo(
            size: 'l',
            onPressed: () {
              context.routerGoTo('');
            },
          ),
        ],
      ),
      actions: [
        AppButton(
          onPressed: () {
            context.routerGoTo('about');
          },
          svgIconPath: 'assets/icons/donate.svg',
          text: localizations.translate('donations'),
          size: "l",
          theme: "warning",
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
