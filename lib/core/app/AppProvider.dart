import 'package:flutter/material.dart';
import '../../services/app.dart';
import '../../services/api.dart';
import '../../models/endpoint.dart';

class AppProvider extends InheritedWidget {
  final App app;
  final Api api;

  const AppProvider({super.key, required this.app, required this.api, required super.child});

  static AppProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppProvider>();
  }

  @override
  bool updateShouldNotify(AppProvider oldWidget) {
    return false;
  }
}

extension ContextExtensions on BuildContext {
  Endpoint? getEndpoint() {
    return AppProvider.of(this)?.api.selectedEndpoint;
  }
}
