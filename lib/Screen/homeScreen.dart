
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:telsim_attendance/Screen/Facereco.dart';
import 'package:telsim_attendance/Screen/loginPage.dart';
import 'package:telsim_attendance/components/myDrawer.dart';

import '../Functions/FetchAllFaces.dart';
import '../Functions/fetchstoredetails.dart';
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
  String storeName = '';

  void initState() {
    super.initState();
    // Disable system navigation (Android only)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
      // Keep only status bar
    );
    OnInit();
  }
  OnInit(){
    fetchStoredetails();
    FetchFaces.getFaceDetails();
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


    if (storeId == null) {

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
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = MediaQuery.of(context).size.shortestSide > 600;

    return Scaffold(
      drawer: (isActive == 1) ? Mydrawer(currentRoute: 'home') :  Drawer(
        backgroundColor: Colors.white,
        child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: const Color(0xFF2C3E50)),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Contact Admin'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await LocalStorageService.clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Loginpage()),
                        (route) => false,
                  );
                },
              ),
            ]
        )
    ),
      appBar: AppBar(
        toolbarHeight: 80.0,
        iconTheme: IconThemeData(
          color: Colors.white70,
        ),
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Attendo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        elevation: 6,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF2C3E50),
            onRefresh: () async {
              await OnInit();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              // Makes RefreshIndicator work even when content is short
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: isTablet
                      ? screenHeight * 0.75
                      : screenHeight * 0.82,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: const Color(0xFF2C3E50),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading || isActive == null) ...[
                            const Expanded(
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ]
                          else if (isActive == 1) ...[
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
                          ] else ...[
                            Expanded(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 32),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white38,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lock_outline,
                                        color: Colors.black,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Store Inactive',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Please contact your manager\nto activate your store.',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     drawer: Mydrawer(currentRoute: 'home',),
  //     appBar: AppBar(
  //       toolbarHeight: 80.0,
  //       iconTheme: IconThemeData(
  //         color: Colors.white70,
  //       ),
  //       backgroundColor: const Color(0xFF2C3E50),
  //       title: const Text(
  //         'Attendo',
  //         style: TextStyle(fontWeight: FontWeight.bold,
  //             color: Colors.white70
  //
  //         ),
  //       ),
  //       centerTitle: true,
  //       elevation: 6,
  //     ),
  //     body: SafeArea(
  //         child: Padding(
  //           padding: const EdgeInsets.all(15.0),
  //           child: Card(
  //
  //             elevation: 5, // Shadow depth
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(15),
  //             ),
  //             color: Color(0xFF2C3E50),
  //
  //             child:
  //             Padding(
  //
  //               padding: const EdgeInsets.all(16.0),
  //
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //
  //                   if(isActive == 1)...[
  //                     Text(
  //                       storeName,
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 22,
  //                         fontWeight: FontWeight.bold,
  //                         letterSpacing: 0.5,
  //                       ),
  //                     ),
  //                     LiveClock(),
  //                     Facedetect(),
  //                   ]
  //                   else
  //                     ...[
  //                       Expanded(
  //                         child: Center(
  //                           child: Container(
  //                             padding: const EdgeInsets.symmetric(
  //                                 horizontal: 24, vertical: 32),
  //                             decoration: BoxDecoration(
  //                               border: Border.all(
  //                                   color: Colors.white38, width: 1.5),
  //                               borderRadius: BorderRadius.circular(16),
  //                               color: Colors.white,
  //                             ),
  //                             child: Column(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 const Icon(
  //                                   Icons.lock_outline,
  //                                   color: Colors.black,
  //                                   size: 48,
  //                                 ),
  //                                 const SizedBox(height: 16),
  //                                 const Text(
  //                                   'Store Inactive',
  //                                   style: TextStyle(
  //                                     color: Colors.white,
  //                                     fontSize: 18,
  //                                     fontWeight: FontWeight.bold,
  //                                   ),
  //                                 ),
  //                                 const SizedBox(height: 8),
  //                                 const Text(
  //                                   'Please contact your manager\nto activate your store.',
  //                                   style: TextStyle(
  //                                     color: Colors.black,
  //                                     fontSize: 14,
  //                                     height: 1.5,
  //                                   ),
  //                                   textAlign: TextAlign.center,
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ]
  //                 ],
  //               ),
  //             ),
  //
  //           ),
  //         )
  //     ),
  //   );
  // }
}
