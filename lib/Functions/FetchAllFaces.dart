import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'fetchstoredetails.dart';

class FetchFaces {

  static Future<List<Map<String, dynamic>>?> getFaceDetails() async {
    final storeData = await LocalStorageService.getStoreDetails();
    final store = storeData?['storeId'];
    print("✅ Fetching faces for store: $store");

    try {
      final url = Uri.parse("$apiBaseUrl/allusers?storeId=$store");

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        List<Map<String, dynamic>> users = data.map((user) {
          return <String, dynamic>{
            'userID': user['userID'],
            'userName': user['userName'],
            'isLoggedIn': user['isLoggedIn'],
            'isActive': user['isActive'],
            'faceembed': user['faceembed'],
          };
        }).toList();

        // ✅ Store in memory cache — no more secure storage
        LocalStorageService.setCachedFaces(users);
        print("✅ ${users.length} faces cached in memory");
        return users;

      } else if (response.statusCode == 404) {
        print("No Faces Registered");
        return null;

      } else {
        print("❌ Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("🔥 Error fetching Faces: $e");
      return null;
    }
  }

  static Future<void> refresh() async {
    await getFaceDetails();
  }
}