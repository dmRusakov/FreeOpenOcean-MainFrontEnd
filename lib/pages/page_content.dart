import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_html/flutter_html.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/services/page_service.dart';
// The contracts package currently exposes generated files only.
// ignore: implementation_imports
import 'package:free_open_ocean_grpc/src/grpc/pages/v1/pages.pb.dart'
    as pages_pb;
import '../services/api.dart';
import '../core/localization/app_localizations.dart';
import 'package:free_open_ocean/pages/page_template.dart' show clearTopBar;

class PageContent extends StatefulWidget {
  final String slug;
  final String? language;
  final String? country;

  const PageContent({
    super.key,
    required this.slug,
    this.language,
    this.country,
  });

  @override
  State<PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<PageContent> {
  pages_pb.Page? _loadedPage;
  bool _hasError = false;
  int _requestVersion = 0;
  String? _requestKey;
  Api? _api;
  late final String _ownerId = 'page_${identityHashCode(this)}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = AppThemeProvider.of(context)!.api;
    if (_api != api) {
      _api?.app.removeListener(_onConnectionChanged);
      _api = api;
      api.app.addListener(_onConnectionChanged);
    }
    _loadIfChanged();
  }

  @override
  void didUpdateWidget(PageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadIfChanged();
  }

  void _onConnectionChanged() {
    if (!mounted) return;
    // Only a mode change should invalidate loaded content; health probes do not.
    final mode = _api!.app.connectionMode.name;
    if (_requestKey?.endsWith('|$mode') != true) setState(_loadIfChanged);
  }

  void _loadIfChanged({bool retry = false}) {
    final provider = AppThemeProvider.of(context)!;
    final language = widget.language ?? provider.locale.languageCode;
    final country = widget.country ?? provider.country;
    final mode = provider.api.app.connectionMode;
    final key = '${widget.slug}|$language|$country|${mode.name}';
    if (!retry && key == _requestKey) return;
    _requestKey = key;
    _loadedPage = null;
    _hasError = mode == ConnectionMode.disable;
    final version = ++_requestVersion;
    if (_hasError) return;
    _load(provider.api, widget.slug, language, country, version, retry);
  }

  Future<void> _load(
    Api api,
    String slug,
    String language,
    String country,
    int version,
    bool retry,
  ) async {
    try {
      if (retry) await api.refresh();
      if (!mounted || version != _requestVersion) return;
      final page = await PageService(api).get(context, slug, language, country);
      if (!mounted || version != _requestVersion) return;
      setState(() => _loadedPage = page);
      if (kIsWeb) {
        html.document.title = page.seoTitle.isNotEmpty
            ? page.seoTitle
            : page.title;
        html.document.head
            ?.querySelectorAll('meta[name="description"]')
            .forEach((element) => element.remove());
        html.document.head?.append(
          html.MetaElement()
            ..name = 'description'
            ..content = page.seoDescription.isNotEmpty
                ? page.seoDescription
                : page.shortDescription,
        );
      }
      // Keep the enclosing page's submenu intact (e.g. Settings > Style Guide).
    } catch (_) {
      if (mounted && version == _requestVersion) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _requestVersion++;
    _api?.app.removeListener(_onConnectionChanged);
    clearTopBar(ownerId: _ownerId);
    super.dispose();
  }

  List<Widget> _buildContent(
    pages_pb.Page page,
    double maxWidth,
    BuildContext context,
  ) {
    List<Widget> content = [const SizedBox(height: 10)];

    // add title and short description if available
    if (page.title != '') {
      content.add(
        Text(page.title, style: Theme.of(context).textTheme.headlineLarge),
      );

      if (page.shortDescription != '') {
        content.add(const SizedBox(height: 10));
        content.add(
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth * 0.50),
            child: Text(
              page.shortDescription,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      content.add(const SizedBox(height: 30));
    }

    // add content
    content.add(
      Html(
        data: page.content,
        style: AppThemeProvider.of(context)!.theme.pageStyles,
      ),
    );

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = AppThemeProvider.of(context)!;

    if (_hasError) {
      final localizations = AppLocalizations.of(context)!;
      final disabled =
          themeProvider.api.app.connectionMode == ConnectionMode.disable;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.translate(
                  disabled ? 'connection_disabled_message' : 'page_load_failed',
                ),
                textAlign: TextAlign.center,
              ),
              if (!disabled) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(() => _loadIfChanged(retry: true)),
                  child: Text(localizations.translate('retry')),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (_loadedPage == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final page = _loadedPage!;

    final maxWidth = themeProvider.theme.maxWidth;

    List<Widget> content = _buildContent(page, maxWidth, context);

    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: content),
        ),
      ),
    );
  }
}
