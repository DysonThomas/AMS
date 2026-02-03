import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

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

  static Future<int?> getStoreStatus() async {
    final userString = await _storage.read(key: 'user');
    if (userString == null) return null;

    final Map<String, dynamic> user = jsonDecode(userString);
    var storeId = user['storeId'];

    try {
      final url = Uri.parse("$apiBaseUrl/getStoreDetails?storeId=$storeId");

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        var isActive = data['isActive'];
        return isActive;

      } else if (response.statusCode == 404) {
        print("⚠️ No store found for ID: $storeId");
        return null;

      } else {
        print("❌ Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("🔥 Error fetching store details: $e");
      return null;
    }
  }
}
