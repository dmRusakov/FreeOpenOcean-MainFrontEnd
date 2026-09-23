import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../core/provider/app_theme_provider.dart';
import '../core/router/app_router.dart';

class PageElementSamples extends StatefulWidget {
  const PageElementSamples({super.key});

  @override
  State<PageElementSamples> createState() => _PageElementSamplesState();
}

class _PageElementSamplesState extends State<PageElementSamples> {
  bool _checked = true;
  bool _enabled = false;
  String _appearance = 'Automatic';
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _loadExample() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    Widget heading(String title) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(title, style: text.titleLarge),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading('Links'),
        Text(
          'Hover over a link or use Tab to see its keyboard focus state.',
          style: text.bodyMedium,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => AppRouter.goTo(context, 'about'),
            child: const Text(
              'Read about FreeOpenOcean',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ),
        heading('Numbered lists'),
        Html(
          data:
              '<ol><li>Choose your destination.</li><li>Review the map before your passage, including nearby coastlines and the details you want to explore.<ol><li>Check your preferred appearance.</li><li>Adjust the map view.</li></ol></li><li>Continue exploring.</li></ol>',
          style: {
            'body': Style(
              color: theme.colorScheme.onSurface,
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
          },
        ),
        heading('Blockquote'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“A clear view makes room for discovery.”',
                style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Text('— FreeOpenOcean · sample quotation', style: text.bodySmall),
            ],
          ),
        ),
        heading('Table'),
        Text(
          'Sample display settings. Swipe horizontally on smaller screens.',
          style: text.bodySmall,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Setting')),
              DataColumn(label: Text('Example')),
              DataColumn(label: Text('Description')),
            ],
            rows: const [
              DataRow(
                cells: [
                  DataCell(Text('Appearance')),
                  DataCell(Text('Automatic')),
                  DataCell(Text('Follow the device theme')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('Language')),
                  DataCell(Text('English')),
                  DataCell(Text('Interface language')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('Map orientation')),
                  DataCell(Text('North up')),
                  DataCell(Text('Default viewing direction')),
                ],
              ),
            ],
          ),
        ),
        heading('Alerts'),
        for (final item in [
          (
            'Success',
            'success',
            Icons.check_circle_outline,
            'Your preferences have been saved.',
          ),
          (
            'Danger',
            'error',
            Icons.error_outline,
            'The request failed. Please try again.',
          ),
          (
            'Warning',
            'warning',
            Icons.warning_amber,
            'Some map details may be unavailable offline.',
          ),
          (
            'Info',
            'info',
            Icons.info_outline,
            'Use the compass to reset the map to north.',
          ),
        ])
          Builder(
            builder: (context) {
              final colors = context.getThemeColor('btn_${item.$2}') as Map;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors['background'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$3, color: colors['text'] as Color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${item.$1}: ${item.$4}',
                        style: text.bodyMedium?.copyWith(
                          color: colors['text'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        heading('Form controls'),
        Text(
          'Interactive examples only; these do not change your app settings.',
          style: text.bodySmall,
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Passage name',
                  hintText: 'Weekend coastal trip',
                  helperText: 'Enter a name to validate the example.',
                  border: OutlineInputBorder(),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a passage name.'
                    : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _appearance,
                decoration: const InputDecoration(
                  labelText: 'Appearance',
                  border: OutlineInputBorder(),
                ),
                items: ['Automatic', 'Light', 'Dark']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _appearance = value ?? 'Automatic'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include map labels'),
                value: _checked,
                onChanged: (value) => setState(() => _checked = value ?? false),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show extra details'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  onPressed: () => _formKey.currentState!.validate(),
                  child: const Text('Validate example'),
                ),
              ),
            ],
          ),
        ),
        heading('Button states'),
        Text(
          'Use Tab to focus an enabled button, then Enter or Space to activate it.',
          style: text.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const FilledButton(onPressed: null, child: Text('Disabled')),
            FilledButton.icon(
              onPressed: _loading ? null : _loadExample,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_loading ? 'Loading…' : 'Try loading'),
            ),
            IconButton.filledTonal(
              tooltip: 'Sample compass action',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compass example activated')),
              ),
              icon: const Icon(Icons.navigation),
            ),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Keyboard-accessible button activated'),
                ),
              ),
              child: const Text('Focus with Tab'),
            ),
          ],
        ),
        heading('Image and caption'),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=1200&q=80',
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: 'Waves approaching an ocean shore',
            errorBuilder: (_, error, stack) => const SizedBox(
              height: 120,
              child: Center(child: Text('Image unavailable')),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ocean shoreline · example image caption',
          style: text.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        heading('Dividers'),
        const Divider(),
        const SizedBox(height: 12),
        Text(
          'A divider separates related sections without adding another heading.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 12),
        const Divider(indent: 24, endIndent: 24),
      ],
    );
  }
}
