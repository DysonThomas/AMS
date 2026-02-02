
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:telsim_attendance/Screen/Facereco.dart';
import 'package:telsim_attendance/Screen/loginPage.dart';
import 'package:telsim_attendance/components/myDrawer.dart';

import '../components/myClock.dart';
import '../constants.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override

  final storage = FlutterSecureStorage();
  bool isLoading = true;
  int? storeId;
  int? isActive;
  String storeName='';
  void initState() {

    super.initState();
    // Disable system navigation (Android only)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
      // Keep only status bar
    );
    fetchStoredetails();

  }
  fetchStoredetails() async {
    String? user = await storage.read(key: 'user');
    if (user != null) {
      final Map<String, dynamic> User = jsonDecode(user);
      setState(() {
        storeId = User['storeId'];

        isLoading = false;
      });
      getStoreDetails();
    }

  }
  Future<void> getStoreDetails() async {
    debugPrint("🟢 getStoreDetails() called");

    if (storeId == null) {
      debugPrint("🔴 storeId is null, API not called");
      return;
    }

    try {
      final url = Uri.parse(
        "$apiBaseUrl/getStoreDetails?storeId=$storeId",
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (!mounted) return; // ✅ safety check

        setState(() {
          storeName = data['name'];
          isActive = data['isActive'];
        });

        debugPrint("✅ Store Name: $storeName");
        debugPrint("✅ Store Active: $isActive");
      }
      else if (response.statusCode == 404) {
        debugPrint("⚠️ No store found for ID: $storeId");
      }
      else {
        debugPrint("❌ Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🔥 Error fetching store details: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
     drawer: Mydrawer(currentRoute: 'home',),
      appBar:AppBar(
        toolbarHeight: 80.0,
        iconTheme: IconThemeData(
          color: Colors.white70,
        ),
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Attendo',
          style: TextStyle(fontWeight: FontWeight.bold,
              color: Colors.white70

          ),
        ),
        centerTitle: true,
        elevation: 6,
      ),
      body: SafeArea(
        child:Padding(
          padding: const EdgeInsets.all(15.0),
          child: Card(

            elevation: 5, // Shadow depth
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Color(0xFF2C3E50),

            child:
            Padding(

              padding: const EdgeInsets.all(16.0),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  if(isActive==1)...[
                    Text(
                      storeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  LiveClock(),
                  Facedetect(),
              ]
                  else...[const Text(
                    "Contact your manager",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),]
                ],
              ),
            ),

          ),
        )
      ),
    );
  }
}
