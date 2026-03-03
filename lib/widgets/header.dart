import 'package:flutter/material.dart';
import '../common/element/logo.dart';
import 'package:free_open_ocean/common/element/appButon.dart';
import 'package:free_open_ocean/core/provider/AppThemeProvider.dart';
import 'package:free_open_ocean/pages/page_template.dart' show topBarNotifier, TopBarData;

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.getTheme('header');

    return AppBar(
      toolbarHeight: kToolbarHeight,
      actionsPadding: theme.sizes['padding'],
      backgroundColor: theme.color['background'],
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Menu button moved to the left
          AppButton(
            onPressed: () { Scaffold.of(context).openDrawer(); },
            icon: Icons.menu,
            size: "l",
            theme: "primary",
          ),
          const SizedBox(width: 8),
          Logo(
            size: 'l',
            onPressed: () { Scaffold.of(context).openDrawer(); },
          ),
          // Page title directly after logo
          ValueListenableBuilder<TopBarData>(
            valueListenable: topBarNotifier,
            builder: (context, data, child) {
              if (data.title == null || data.title!.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 20.0, top: 2.0),
                child: Text(data.title!, style: Theme.of(context).textTheme.titleLarge),
              );
            },
          ),
          const Spacer(),
          // Submenu on the far right
          ValueListenableBuilder<TopBarData>(
            valueListenable: topBarNotifier,
            builder: (context, data, child) {
              if (data.submenu == null || data.submenu!.isEmpty) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...data.submenu!,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}