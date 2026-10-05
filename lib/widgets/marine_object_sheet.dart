import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/localization/app_localizations.dart';
import '../services/marine_object_info.dart';

/// Shows name, type, details, and data source for a tapped marine object.
Future<void> showMarineObjectInfoDialog(
  BuildContext context,
  MarineObjectInfo info,
) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return PointerInterceptor(
        child: Dialog(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.title,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                info.typeLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.translate('map_cancel'),
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (info.category != null)
                          _InfoRow(
                            label: l10n.translate('marine_object_category'),
                            value: info.category!,
                          ),
                        if (info.ref != null)
                          _InfoRow(
                            label: l10n.translate('marine_object_ref'),
                            value: info.ref!,
                          ),
                        if (info.operator != null)
                          _InfoRow(
                            label: l10n.translate('marine_object_operator'),
                            value: info.operator!,
                          ),
                        if (info.phone != null)
                          _InfoRow(
                            label: l10n.translate('marine_object_phone'),
                            value: info.phone!,
                          ),
                        if (info.website != null)
                          _InfoRow(
                            label: l10n.translate('marine_object_website'),
                            value: info.website!,
                            selectable: true,
                          ),
                        if (info.detail != null &&
                            info.detail!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.translate('marine_object_details'),
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          SelectableText(info.detail!),
                        ],
                        if (info.latitude != null && info.longitude != null)
                          _InfoRow(
                            label: l10n.translate('marine_object_position'),
                            value:
                                '${info.latitude!.toStringAsFixed(5)}, ${info.longitude!.toStringAsFixed(5)}',
                            selectable: true,
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.translate('marine_object_source')}: ${info.sourceLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      if (info.itemId != null) ...[
                        const SizedBox(height: 2),
                        SelectableText(
                          '${l10n.translate('marine_object_id')}: ${info.itemId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value, style: valueStyle)
                : Text(value, style: valueStyle),
          ),
        ],
      ),
    );
  }
}
