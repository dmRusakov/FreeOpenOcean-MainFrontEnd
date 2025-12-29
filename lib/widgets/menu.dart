import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:free_open_ocean/common/element/logo.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import '../core/theme/AppTheme.dart';
import 'package:free_open_ocean/common/element/appButon.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.getTheme('menu');
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: theme.sizes['margin'],
      child: ClipRRect(
        borderRadius: theme.sizes['border'],
        child: Drawer(
          child: SafeArea(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: theme.sizes['headerHeight'],
                  child: DrawerHeader(
                    margin: theme.sizes['headerMargin'],
                    padding: theme.sizes['headerPadding'],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Logo(
                          onPressed: () {
                            context.routerGoTo('');
                            },
                          size: theme.sizes['headerButtonSize'],
                        ),
                        AppButton(
                          onPressed: () { Navigator.pop(context); },
                          icon: Icons.close,
                          size: theme.sizes['headerButtonSize'],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.map),
                        title: Text(localizations.translate('ocean_map')),
                        onTap: () {
                          context.routerGoTo('ocean_map');
                        },
                      ),
                      const Spacer(),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: Text(localizations.translate('settings')),
                        onTap: () {
                          context.routerGoTo('settings');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(localizations.translate('user')),
                        onTap: () {
                          context.routerGoTo('user');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: Text(localizations.translate('about')),
                        onTap: () {
                          context.routerGoTo('about');
                        },
                      ),
                      ListTile(
                        leading: SvgPicture.asset(
                          'assets/icons/donate.svg',
                          width: 25.0,
                          colorFilter: ColorFilter.mode(Theme.of(context).textTheme.bodyLarge!.color ?? Colors.black, BlendMode.srcIn),
                        ),
                        title: Text(localizations.translate('donations')),
                        onTap: () {
                          context.routerGoTo('about');
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/flags/us.svg',
                        width: 25.0,
                      ),
                      const SizedBox(width: 10.0),
                      Text(localizations.translate('made_in_usa')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
