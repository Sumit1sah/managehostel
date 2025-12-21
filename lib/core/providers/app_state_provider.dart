import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';
import 'dart:async';

class AppStateProvider extends ChangeNotifier {
  String _lastRoute = '/home';
  Map<String, dynamic> _routeArguments = {};
  
  Timer? _saveTimer;
  static const _saveDuration = Duration(milliseconds: 500);

  String get lastRoute => _lastRoute;
  Map<String, dynamic> get routeArguments => _routeArguments;

  Future<void> init() async {
    await _restoreState();
  }

  Future<void> _restoreState() async {
    _lastRoute = HiveStorage.load(HiveStorage.appStateBox, 'last_route', defaultValue: '/home')!;
    _routeArguments = Map<String, dynamic>.from(
      HiveStorage.load(HiveStorage.appStateBox, 'route_args', defaultValue: {})!,
    );
  }

  void saveNavigationState(String route, {Map<String, dynamic>? arguments}) {
    _lastRoute = route;
    _routeArguments = arguments ?? {};
    _debouncedSave();
    notifyListeners();
  }

  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDuration, _persistState);
  }

  Future<void> _persistState() async {
    await HiveStorage.save(HiveStorage.appStateBox, 'last_route', _lastRoute);
    await HiveStorage.save(HiveStorage.appStateBox, 'route_args', _routeArguments);
  }

  Future<void> forceSave() async {
    _saveTimer?.cancel();
    await _persistState();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
