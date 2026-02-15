import 'package:flutter/material.dart';
import '../core/theme/AppTheme.dart';
import '../core/provider/AppThemeProvider.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.getTheme('topHeader');

    return Container(
      height: theme.sizes['height'],
      color: theme.color['background'],
      padding: theme.sizes['padding'],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: theme.color['text'] as Color, size: 16),
          const SizedBox(width: 8),
          const Text(
            'This is the top header for additional information.',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
