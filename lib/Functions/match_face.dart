import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../constants.dart';

class MatchFace{
  late List<double> embedding;
Future<Map<String,dynamic>?> setEmbedding(List<double> newEmbedding) async {
  print("inside api");
  embedding = newEmbedding;
  var url = Uri.parse("$apiBaseUrl/allusers");
  var res = await http.get(url);
  if (res.statusCode == 200) {
    final List<dynamic> users = jsonDecode(res.body);
    double minDistance = double.infinity;
    Map<String, dynamic>? bestMatch;
    for (var user in users) {
      List<dynamic> dbEmbed = user["faceembed"];
      double dist = euclideanDistance(embedding, dbEmbed);
      if (dist < minDistance) {
        minDistance = dist;
        bestMatch = user;
      }
    }
    print("Best match: ${bestMatch?["userName"]} with distance $minDistance");
    if (minDistance < .9) {
      return bestMatch; // Match found
    } else {
      return null; // No match
    }
    }
  else {
    print("Error: ${res.statusCode}");
  }
}
  double euclideanDistance(List<double> e1, List<dynamic> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      double diff = e1[i] - (e2[i] as double);
      sum += diff * diff;
    }
    return sqrt(sum);
  }
}