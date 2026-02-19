import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class LocalStorageService {
  static List<Map<String, dynamic>>? _cachedFaces; // ← in-memory cache

  static List<Map<String, dynamic>>? get cachedFaces => _cachedFaces;
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
    final storage = FlutterSecureStorage();
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
  static Future<void> clear() async {
    await _storage.deleteAll();
  }
  static Future<Map<String, dynamic>?> getEmployeeStatus() async {
    final userString = await _storage.read(key: 'user');
    if (userString == null) return null;

    final Map<String, dynamic> user = jsonDecode(userString);
    return {
      "isActive": user['isActive'],
    };
  }
  static List<Map<String, dynamic>>? getAllFaces() {
    return _cachedFaces; // instant, no async, no decryption
  }
  static Future<void> updateUserLoginStatus(String userID, bool isLoggedIn) async {
    if (_cachedFaces == null) return;

    for (var face in _cachedFaces!) {
      if (face['userID'].toString() == userID) {
        face['isLoggedIn'] = isLoggedIn ? 1 : 0;
        print("✅ Updated login status in memory for $userID");
        return;
      }
    }

    print("⚠️ User $userID not found in cache");
  }
  static Future<bool> updateAllFaces(List<Map<String, dynamic>> faces) async {
    try {
      final facesJson = jsonEncode(faces);
      await _storage.write(key: 'faceData', value: facesJson);
      return true;
    } catch (e) {
      print("Error updating faces: $e");
      return false;
    }
  }
  static void setCachedFaces(List<Map<String, dynamic>> faces) {
    _cachedFaces = faces;
  }
}
