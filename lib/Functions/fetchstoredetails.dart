import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  static final FlutterSecureStorage _storage =
  const FlutterSecureStorage();

  /// 🏪 Get store details from stored user
  static Future<Map<String, dynamic>?> getStoreDetails() async {
    final userString = await _storage.read(key: 'user');
    if (userString == null) return null;

    final Map<String, dynamic> user = jsonDecode(userString);

    return {
      "storeId": user['storeId'],
    };
  }
}
