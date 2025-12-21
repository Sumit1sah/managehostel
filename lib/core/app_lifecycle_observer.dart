import 'package:flutter/material.dart';
import 'providers/app_state_provider.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final AppStateProvider appStateProvider;

  AppLifecycleObserver(this.appStateProvider);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        appStateProvider.forceSave();
        break;
      case AppLifecycleState.resumed:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
