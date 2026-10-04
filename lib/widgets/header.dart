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
    final scheme = Theme.of(context).colorScheme;
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
          // The bar floats on the chart, so the title needs its own ground.
          // A gradient scrim holds contrast over sand, sea or a dark coast
          // without boxing the header in.
          flexibleSpace: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.surface.withValues(alpha: 0.82),
                  scheme.surface.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          title: Padding(
            padding: theme.sizes['padding'] as EdgeInsets? ?? EdgeInsets.zero,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                final submenu = data.submenu;
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
                        child: LayoutBuilder(
                          builder: (context, bar) {
                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data.title ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (submenu != null && submenu.isNotEmpty)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: bar.maxWidth * 0.72 < 560
                                          ? bar.maxWidth * 0.72
                                          : 560,
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, slot) {
                                        // The row is at least as wide as the
                                        // slot, so the buttons sit on its
                                        // right edge and scroll when they
                                        // do not fit.
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: slot.maxWidth,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: submenu,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
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
