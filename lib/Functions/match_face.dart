
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../constants.dart';
import 'fetchstoredetails.dart';

class MatchFace {
  // Constants
  static const double MATCH_THRESHOLD = 0.9;

  int? storeId;
  late List<double> embedding;

  Future<Map<String, dynamic>?> setEmbedding(List<double> newEmbedding) async {
    try {
      embedding = newEmbedding;

      final users = await LocalStorageService.getAllFaces();

      // Check if users is null or empty
      if (users == null || users.isEmpty) {
        if (kDebugMode) {
          print("⚠️ No faces found in local storage");
        }
        return null;
      }

      double minDistance = double.infinity;
      Map<String, dynamic>? bestMatch;

      for (var user in users) {
        // Handle faceembed safely
        if (user["faceembed"] == null) continue;

        try {
          // Parse faceembed - it might be stored as a JSON string
          List<double> dbEmbed;

          if (user["faceembed"] is String) {
            final decoded = jsonDecode(user["faceembed"]) as List;
            dbEmbed = decoded.map((e) => (e as num).toDouble()).toList();
          } else if (user["faceembed"] is List) {
            dbEmbed = (user["faceembed"] as List).map((e) => (e as num).toDouble()).toList();
          } else {
            if (kDebugMode) {
              print("⚠️ Invalid faceembed format for user ${user['userName']}");
            }
            continue;
          }

          // Validate embedding lengths match
          if (dbEmbed.length != embedding.length) {
            if (kDebugMode) {
              print("⚠️ Embedding length mismatch for user ${user['userName']}: ${dbEmbed.length} vs ${embedding.length}");
            }
            continue;
          }

          double dist = euclideanDistance(embedding, dbEmbed);

          if (dist < minDistance) {
            minDistance = dist;
            bestMatch = user;
          }
        } catch (e) {
          if (kDebugMode) {
            print("⚠️ Error processing user ${user['userName']}: $e");
          }
          continue;
        }
      }

      // Check threshold and isActive
      if (minDistance < MATCH_THRESHOLD && bestMatch != null) {
        // Safely check isActive (could be int, bool, or null)
        final isActive = bestMatch["isActive"];
        final isUserActive = (isActive == 1 || isActive == true);

        if (isUserActive) {
          if (kDebugMode) {
            print("✅ Match found: ${bestMatch['userName']} (distance: ${minDistance.toStringAsFixed(4)})");
          }
          return bestMatch;
        } else {
          if (kDebugMode) {
            print("⚠️ Best match found but user is inactive: ${bestMatch['userName']}");
          }
        }
      }

      if (kDebugMode) {
        print("❌ No match found (best distance: ${minDistance.toStringAsFixed(4)}, threshold: $MATCH_THRESHOLD)");
      }
      return null;

    } catch (e) {
      if (kDebugMode) {
        print("❌ Error in setEmbedding: $e");
      }
      return null;
    }
  }

  double euclideanDistance(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) {
      throw ArgumentError(
          "Embedding dimensions don't match: ${e1.length} vs ${e2.length}"
      );
    }

    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      double diff = e1[i] - e2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }
}