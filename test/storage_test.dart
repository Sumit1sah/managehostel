import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:managehostel/core/storage/hive_storage.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('HiveStorage Tests', () {
    test('Save and load string', () async {
      await HiveStorage.init();
      await HiveStorage.save(HiveStorage.appStateBox, 'test_key', 'test_value');
      final result = HiveStorage.load<String>(HiveStorage.appStateBox, 'test_key');
      expect(result, 'test_value');
    });

    test('Save and load list', () async {
      final testList = [
        {'id': '1', 'name': 'Test'},
        {'id': '2', 'name': 'Test2'},
      ];
      await HiveStorage.saveList(HiveStorage.cleaningsBox, 'test_list', testList);
      final result = HiveStorage.loadList(HiveStorage.cleaningsBox, 'test_list');
      expect(result.length, 2);
      expect(result[0]['name'], 'Test');
    });
  });
}
