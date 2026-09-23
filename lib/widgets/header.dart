import 'package:flutter/material.dart';

import '../common/element/logo.dart';
import '../common/element/app_button.dart';
import '../core/provider/app_theme_provider.dart';
import '../pages/page_template.dart' show topBarNotifier, TopBarData;

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  static const chartsToolbarHeight = 72.0;

  double _toolbarHeight(TopBarData data) =>
      data.ownerId == 'ocean_charts' ? chartsToolbarHeight : kToolbarHeight;

  @override
  Widget build(BuildContext context) {
    final theme = context.getTheme('header');
    return ValueListenableBuilder<TopBarData>(
      valueListenable: topBarNotifier,
      builder: (context, data, _) {
        final height = _toolbarHeight(data);
        return AppBar(
          toolbarHeight: height,
          titleSpacing: 0,
          elevation: 0,
          scrolledUnderElevation: 0,
          forceMaterialTransparency: true,
          backgroundColor: theme.color['background'],
          automaticallyImplyLeading: false,
          title: Padding(
            padding: theme.sizes['padding'] as EdgeInsets? ?? EdgeInsets.zero,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                return SizedBox(
                  height: height,
                  child: Row(
                    children: [
                      AppButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: Icons.menu,
                        size: 'l',
                        theme: 'primary',
                      ),
                      const SizedBox(width: 8),
                      Logo(
                        size: compact ? 's' : 'l',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data.title ?? '',
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (data.submenu?.isNotEmpty ?? false)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: data.submenu!,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
