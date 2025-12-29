import 'package:flutter/material.dart';
import 'package:free_open_ocean/widgets/footer.dart';
import 'package:free_open_ocean/widgets/header.dart';
import 'package:free_open_ocean/widgets/menu.dart';
import 'package:free_open_ocean/widgets/top_header.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart';

class PageTemplate extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;

  const PageTemplate({super.key, required this.body, this.floatingActionButton});

  @override
  Widget build(BuildContext context) {
    final sizes = context.getThemeSizes('pageLayout');

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
