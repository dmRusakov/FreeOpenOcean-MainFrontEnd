import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../common/element/app_button.dart';
import 'page_element_samples.dart';
import '../core/provider/app_theme_provider.dart';

/// Samples use the active theme, so they follow light and dark appearance.
class TypographyContent extends StatelessWidget {
  const TypographyContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    const variants = [
      ('Primary', 'primary'),
      ('Success', 'success'),
      ('Danger', 'error'),
      ('Warning', 'warning'),
      ('Info', 'info'),
    ];
    const sizes = [
      ('Small', 's'),
      ('Medium', 'm'),
      ('Large', 'l'),
      ('Extra large', 'xl'),
    ];
    final samples = <(String, String, TextStyle?)>[
      ('Display', 'Explore the open ocean', text.displaySmall),
      ('Heading 1', 'Chart your next passage', text.headlineLarge),
      ('Heading 2', 'A clearer view of the coast', text.headlineMedium),
      ('Heading 3', 'Plan with confidence', text.headlineSmall),
      ('Title', 'Your journey starts here', text.titleLarge),
      (
        'Body',
        'Explore coastlines, discover new destinations, and keep the bigger picture in view. Clear, readable text helps you find the information you need.',
        text.bodyLarge,
      ),
      ('Small text', 'Map details and supporting information.', text.bodySmall),
      ('Label', 'MAP APPEARANCE', text.labelLarge),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Typography', style: text.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'Headings, body text, and labels in the current app theme.',
          style: text.bodyLarge,
        ),
        const SizedBox(height: 32),
        for (final sample in samples) ...[
          Text(
            sample.$1,
            style: text.labelMedium?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(sample.$2, style: sample.$3),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
        ],
        Text('Colors', style: text.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final variant in variants)
              Builder(
                builder: (context) {
                  final colors =
                      context.getThemeColor('btn_${variant.$2}') as Map;
                  return Container(
                    width: 140,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors['background'] as Color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      variant.$1,
                      style: text.titleSmall?.copyWith(
                        color: colors['text'] as Color,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 32),
        Text('Unordered list', style: text.titleLarge),
        Html(
          data:
              '<ul><li>Explore coastlines and nearby destinations.</li><li>Choose your map appearance.<ul><li>Light mode for daylight.</li><li>Dark mode for low light.</li></ul></li><li>Save time planning your next passage.</li></ul>',
          style: {
            'body': Style(
              color: theme.colorScheme.onSurface,
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
          },
        ),
        const SizedBox(height: 32),
        Text('Buttons', style: text.titleLarge),
        const SizedBox(height: 12),
        for (final size in sizes) ...[
          Text(size.$1, style: text.titleMedium),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final variant in variants)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AppButton(
                      text: variant.$1,
                      theme: variant.$2,
                      size: size.$2,
                      showTextAlways: true,
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${variant.$1} · ${size.$1} button',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        const PageElementSamples(),
        const SizedBox(height: 32),
        Text('Text emphasis', style: text.titleLarge),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Use '),
              const TextSpan(
                text: 'bold text',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' for key details and '),
              const TextSpan(
                text: 'italic text',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const TextSpan(text: ' for gentle emphasis.'),
            ],
          ),
          style: text.bodyLarge,
        ),
      ],
    );
  }
}
