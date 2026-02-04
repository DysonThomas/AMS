import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:telsim_attendance/Functions/FetchAllFaces.dart';

import '../constants.dart';
import 'fetchstoredetails.dart';

class MatchFace {
  int? storeId;
  late List<double> embedding;

  Future<Map<String, dynamic>?> setEmbedding(List<double> newEmbedding) async {
    embedding = newEmbedding;

    final users = await LocalStorageService.getAllFaces();

    // Check if users is null or empty
    if (users == null || users.isEmpty) {
      print("⚠️ No faces found in local storage");
      return null;
    }

    double minDistance = double.infinity;
    Map<String, dynamic>? bestMatch;

    for (var user in users) {
      // Handle faceembed safely
      if (user["faceembed"] == null) continue;

      // Parse faceembed - it might be stored as a JSON string
      List<dynamic> dbEmbed;
      if (user["faceembed"] is String) {
        dbEmbed = jsonDecode(user["faceembed"]);
      } else {
        dbEmbed = user["faceembed"];
      }

      double dist = euclideanDistance(embedding, dbEmbed);

      if (dist < minDistance) {
        minDistance = dist;
        bestMatch = user;
      }
    }

    // Check threshold and isActive
    if (minDistance < 0.9 && bestMatch != null && bestMatch["isActive"] == 1) {
      print("✅ Match found: ${bestMatch['userName']} (distance: ${minDistance.toStringAsFixed(4)})");
      return bestMatch;
    } else {
      print("❌ No match found (best distance: ${minDistance.toStringAsFixed(4)})");
      return null;
    }
  }

  double euclideanDistance(List<double> e1, List<dynamic> e2) {
    if (e1.length != e2.length) {
      throw Exception("Embedding dimensions don't match: ${e1.length} vs ${e2.length}");
    }

    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      double diff = e1[i] - (e2[i] as double);
      sum += diff * diff;
    }
    return sqrt(sum);
  }
}