import 'package:flutter/material.dart';
import 'package:free_open_ocean/widgets/footer.dart';
import 'package:free_open_ocean/widgets/header.dart';
import 'package:free_open_ocean/widgets/menu.dart';
import 'package:free_open_ocean/widgets/top_header.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart';

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
        body: Stack(
          children: [
            Positioned.fill(child: body),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const MyAppBar(),
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
