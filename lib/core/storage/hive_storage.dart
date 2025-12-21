import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:typed_data';

class HiveStorage {
  static const String _encryptionKeyName = 'hive_encryption_key';
  static const _secureStorage = FlutterSecureStorage();
  
  static const String cleaningsBox = 'cleanings';
  static const String queueBox = 'queue';
  static const String machinesBox = 'machines';
  static const String floorsBox = 'floors';
  static const String appStateBox = 'app_state';
  
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    
    final encryptionKey = await _getEncryptionKey();
    
    await Hive.openBox(cleaningsBox, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(queueBox, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(machinesBox, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(floorsBox);
    await Hive.openBox(appStateBox);
    
    _initialized = true;
  }

  static Future<Uint8List> _getEncryptionKey() async {
    String? keyString = await _secureStorage.read(key: _encryptionKeyName);
    
    if (keyString == null) {
      final key = Hive.generateSecureKey();
      keyString = base64Encode(key);
      await _secureStorage.write(key: _encryptionKeyName, value: keyString);
      return Uint8List.fromList(key);
    }
    
    return Uint8List.fromList(base64Decode(keyString));
  }

  static Future<void> save(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  static T? load<T>(String boxName, String key, {T? defaultValue}) {
    final box = Hive.box(boxName);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> saveList(String boxName, String key, List<Map<String, dynamic>> list) async {
    await save(boxName, key, list);
  }

  static List<Map<String, dynamic>> loadList(String boxName, String key) {
    final data = load<List>(boxName, key, defaultValue: []);
    return data!.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> migrate() async {
    final currentVersion = load<int>(appStateBox, 'db_version', defaultValue: 1);
    if (currentVersion! < 2) {
      await save(appStateBox, 'db_version', 2);
    }
  }

  static Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  static Future<void> clearOldCleaningData() async {
    final cleaningsData = loadList(cleaningsBox, 'cleanings_data');
    final now = DateTime.now();
    
    final filtered = cleaningsData.where((cleaning) {
      final scheduledDate = DateTime.parse(cleaning['scheduledDate']);
      final difference = now.difference(scheduledDate).inHours;
      return difference < 24;
    }).toList();
    
    await saveList(cleaningsBox, 'cleanings_data', filtered);
  }
}
