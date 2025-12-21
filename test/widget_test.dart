import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:managehostel/main.dart';
import 'package:managehostel/core/providers/theme_provider.dart';
import 'package:managehostel/core/providers/locale_provider.dart';
import 'package:managehostel/core/providers/app_state_provider.dart';
import 'package:managehostel/core/storage/hive_storage.dart';

void main() {
  setUpAll(() async {
    await HiveStorage.init();
  });

  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Hostel Management'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
