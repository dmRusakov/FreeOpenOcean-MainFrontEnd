import 'package:flutter/material.dart';
import 'package:free_open_ocean/widgets/footer.dart';
import 'package:free_open_ocean/widgets/header.dart';
import 'package:free_open_ocean/widgets/menu.dart';
import 'package:free_open_ocean/widgets/top_header.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart';
import 'package:free_open_ocean/core/provider/AppThemeProvider.dart';
import 'package:free_open_ocean/common/element/logo.dart';
import 'package:free_open_ocean/common/element/appButon.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';

class PageTemplate extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final bool fullScreen;

  const PageTemplate({super.key, required this.body, this.floatingActionButton, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    final sizes = context.getThemeSizes('pageLayout');

    if (fullScreen) {
      return Scaffold(
        drawer: const AppMenu(),
        body: Stack(
          children: [
            Positioned.fill(child: body),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const HeaderRow(),
            ),
            if (sizes['footer']) Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: const Footer(),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      appBar: const MyAppBar(),
      drawer: const AppMenu(),
      body: Column(
        children: [
          sizes['topHeader'] ? const TopHeader() : const SizedBox(),
          Expanded(
            child: body,
          ),
          sizes['footer'] ? const Footer() : const SizedBox(),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class HeaderRow extends StatelessWidget {
  const HeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.getTheme('header');
    final localizations = AppLocalizations.of(context)!;

    return Container(
      height: kToolbarHeight,
      padding: theme.sizes['padding'],
      color: theme.color['background'],
      child: Row(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Logo(
              size: 'l',
              onPressed: () { Scaffold.of(context).openDrawer(); },
            ),
          ),
          const Spacer(),
          AppButton(
            onPressed: () {
              context.routerGoTo('about');
            },
            svgIconPath: 'icons/donate.svg',
            text: localizations.translate('donations'),
            size: "l",
            theme: "warning",
          ),
        ],
      ),
    );
  }
}