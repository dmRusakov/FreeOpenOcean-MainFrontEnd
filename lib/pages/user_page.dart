import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:flutter/foundation.dart';
import 'package:free_open_ocean/services/status.dart';

class UserPage extends StatefulWidget {
  final Map<String, String>? params;

  const UserPage({super.key, this.params});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String statusResult = 'Loading status...';
  final _statusService = StatusService();

  @override
  void initState() {
    super.initState();
    _callStatus();
  }

  Future<void> _callStatus() async {
    final result = await _statusService.getStatus();
    setState(() {
      statusResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PageTemplate(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(localizations.translate('user_page')),
            const SizedBox(height: 20),
            Text(statusResult),
          ],
        ),
      ),
    );
  }
}
