import 'package:flutter/material.dart';

import '../core/provider/app_theme_provider.dart';

/// Shared centered column for page content and map overlays.
class PageWidth extends StatelessWidget {
  final Widget child;
  const PageWidth({super.key, required this.child});

  static double maxWidth(BuildContext context) =>
      AppThemeProvider.of(context)?.theme.maxWidth ?? 1200;

  static double outerInset(BuildContext context, double width) =>
      ((width - maxWidth(context)) / 2).clamp(0.0, double.infinity);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth(context)),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}
